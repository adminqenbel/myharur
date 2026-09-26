// push-digest: the daily "new reports" notification, sent through Firebase Cloud Messaging (HTTP v1).
//
// The database decides whether anything may be sent (internal_digest_plan): silent during quiet hours (22:00-07:00
// India time), at most one digest per 20 hours, and only when new reports went live. This function only delivers.
// Recipients are people who kept both "Notifications" and "Reports" on. Dead tokens are removed.
//
// Secrets: CRON_SECRET (shared with the other scheduled jobs) and FIREBASE_SERVICE_ACCOUNT (the service-account JSON
// from Firebase console > Project settings > Service accounts). Without the latter the function does nothing.
// Auth: pg_cron/pg_net sends  x-cron-secret.  Deployed with --no-verify-jwt.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' } });

function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

const enc = new TextEncoder();
const b64url = (data: Uint8Array | string) => {
  const bytes = typeof data === 'string' ? enc.encode(data) : data;
  let s = '';
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};

function pemToDer(pem: string): ArrayBuffer {
  const body = pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, '');
  const raw = atob(body);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out.buffer;
}

type ServiceAccount = { project_id: string; client_email: string; private_key: string };

// Signs a short-lived JWT with the service-account key and exchanges it for an OAuth access token.
async function accessToken(sa: ServiceAccount): Promise<string | null> {
  const now = Math.floor(Date.now() / 1000);
  const unsigned =
    b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' })) +
    '.' +
    b64url(JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3300,
    }));
  const key = await crypto.subtle.importKey('pkcs8', pemToDer(sa.private_key), { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, enc.encode(unsigned)));
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${unsigned}.${b64url(sig)}` }),
  });
  if (!res.ok) return null;
  return (await res.json()).access_token ?? null;
}

const clip = (s: string, n: number) => (s.length > n ? s.slice(0, n - 1).trimEnd() + '…' : s);

function message(lang: string, n: number, titles: string[]) {
  const list = clip(titles.map((t) => clip(t, 60)).join(' · '), 120);
  return lang === 'ta'
    ? { title: `அரூரில் புதிய அறிக்கைகள்: ${n}`, body: list }
    : { title: `${n} new report${n === 1 ? '' : 's'} in Harur`, body: list };
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json(405, { error: 'method_not_allowed' });
  const secret = Deno.env.get('CRON_SECRET');
  if (!secret || !safeEqual(req.headers.get('x-cron-secret') ?? '', secret)) return json(401, { error: 'unauthorized' });

  const url = Deno.env.get('SUPABASE_URL')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const db = createClient(url, serviceKey, { auth: { persistSession: false } });

  const saRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!saRaw) return json(200, { sent: 0, reason: 'push_not_configured' });
  let sa: ServiceAccount;
  try {
    sa = JSON.parse(saRaw);
    if (!sa.project_id || !sa.client_email || !sa.private_key) throw new Error('incomplete');
  } catch {
    return json(500, { error: 'bad_service_account' });
  }

  // 1. may we send at all?
  const { data: planRows, error: planError } = await db.rpc('internal_digest_plan');
  if (planError) return json(500, { error: 'plan_failed' });
  const plan = Array.isArray(planRows) ? planRows[0] : planRows;
  if (!plan?.allowed) return json(200, { sent: 0, reason: plan?.reason ?? 'not_allowed' });

  // 2. who wants it?
  const { data: tokens, error: tokenError } = await db.rpc('internal_digest_tokens');
  if (tokenError) return json(500, { error: 'tokens_failed' });
  const targets: { token: string; lang: string }[] = tokens ?? [];
  if (targets.length === 0) return json(200, { sent: 0, reason: 'no_recipients' });

  const access = await accessToken(sa);
  if (!access) return json(502, { error: 'fcm_auth_failed' });

  // 3. deliver (20 at a time)
  const endpoint = `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(sa.project_id)}/messages:send`;
  const dead: string[] = [];
  let sent = 0;
  let failed = 0;
  for (let i = 0; i < targets.length; i += 20) {
    await Promise.all(targets.slice(i, i + 20).map(async (t) => {
      const m = message(t.lang, plan.new_reports, plan.titles ?? []);
      try {
        const res = await fetch(endpoint, {
          method: 'POST',
          headers: { Authorization: `Bearer ${access}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            message: {
              token: t.token,
              notification: { title: m.title, body: m.body },
              data: { route: 'reports' },
              android: { priority: 'NORMAL', ttl: '43200s' }, // a stale digest is worth nothing after 12 h
            },
          }),
        });
        if (res.ok) {
          sent++;
        } else {
          failed++;
          const status = (await res.json().catch(() => ({})))?.error?.status;
          if (res.status === 404 || status === 'UNREGISTERED' || status === 'INVALID_ARGUMENT') dead.push(t.token);
        }
      } catch {
        failed++;
      }
    }));
  }

  if (dead.length > 0) await db.rpc('internal_drop_tokens', { p_tokens: dead });
  // Logged only when something was delivered, so a total outage does not use up today's digest.
  if (sent > 0) await db.rpc('internal_log_notification', { p_kind: 'reports_digest', p_recipients: sent, p_detail: { new_reports: plan.new_reports, failed } });
  return json(200, { sent, failed, dropped: dead.length });
});
