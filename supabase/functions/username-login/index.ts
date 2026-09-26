// username-login: sign in with @username + password.
//
// Why a function: the app must never learn which e-mail belongs to a username (that would let anyone
// harvest e-mail addresses), and password guessing must be throttled somewhere we control.
//
//   1. rate-limit check (per username and per IP, see login_retry_after in the database)
//   2. resolve username -> e-mail server-side (service role only)
//   3. verify the password with Supabase Auth (GoTrue password grant)
//   4. every failure returns the SAME response, and an unknown username still performs a GoTrue call
//      so response time does not reveal whether the username exists
//
// Deployed with --no-verify-jwt (the caller has no session yet).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'content-type, apikey',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (status: number, body: unknown, extra: Record<string, string> = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', ...cors, ...extra },
  });

const INVALID = () => json(401, { error: 'invalid_credentials' });

// 423: password sign-in is paused for this account (the username is public, so this reveals nothing secret).
const locked = (permanent: boolean, until: string | null) =>
  json(423, { error: 'password_login_locked', permanent, until });

async function sha256(text: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
  if (req.method !== 'POST') return json(405, { error: 'method_not_allowed' });
  if (Number(req.headers.get('content-length') ?? '0') > 2048) return json(413, { error: 'too_large' });

  let body: { username?: unknown; password?: unknown };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: 'bad_request' });
  }

  const raw = typeof body.username === 'string' ? body.username.trim().toLowerCase() : '';
  const username = raw.startsWith('@') ? raw : `@${raw}`;
  const password = typeof body.password === 'string' ? body.password : '';
  if (!/^@[a-z0-9_]{3,30}$/.test(username) || password.length < 1 || password.length > 128) return INVALID();

  const url = Deno.env.get('SUPABASE_URL')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const pepper = Deno.env.get('LOGIN_PEPPER') ?? Deno.env.get('CRON_SECRET') ?? '';
  if (!url || !serviceKey || !anonKey || !pepper) return json(500, { error: 'server_misconfigured' });

  const ip = (req.headers.get('x-forwarded-for') ?? '').split(',')[0].trim() || 'unknown';
  const userHash = await sha256(`${pepper}|u|${username}`);
  const ipHash = await sha256(`${pepper}|i|${ip}`);

  const db = createClient(url, serviceKey, { auth: { persistSession: false } });

  // 1. throttle
  const { data: wait, error: waitError } = await db.rpc('login_retry_after', { p_user_hash: userHash, p_ip_hash: ipHash });
  if (waitError) return json(500, { error: 'server_error' });
  if (typeof wait === 'number' && wait > 0) {
    return json(429, { error: 'too_many_attempts', retry_after: wait }, { 'Retry-After': String(wait) });
  }

  // 2. username -> e-mail (unknown names still go through the same GoTrue call below)
  const { data: found } = await db.rpc('internal_lookup_login', { p_username: username });
  const account = Array.isArray(found) && found.length > 0 ? found[0] : null;
  const email = account?.email ?? `nobody-${crypto.randomUUID()}@invalid.example`;

  // 2b. escalated lock (5 consecutive failures = 24 h, 3 of those = until a super admin recovers it).
  // Only the password path is blocked; Google sign-in is unaffected. The password is NOT checked while locked.
  if (account) {
    const { data: lock } = await db.rpc('login_lock_state', { p_user_id: account.user_id });
    const active = Array.isArray(lock) && lock.length > 0 ? lock[0] : null;
    if (active) return locked(active.permanent, active.locked_until);
  }

  // 3. verify the password
  let session: Record<string, unknown> | null = null;
  let upstream = 0;
  try {
    const res = await fetch(`${url}/auth/v1/token?grant_type=password`, {
      method: 'POST',
      headers: { apikey: anonKey, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    upstream = res.status;
    if (res.ok) session = await res.json();
  } catch {
    return json(502, { error: 'auth_unavailable' });
  }

  const ok = Boolean(account && session && (session as { access_token?: string }).access_token);
  const { data: outcome } = await db.rpc('record_login_attempt', {
    p_user_hash: userHash,
    p_ip_hash: ipHash,
    p_ok: ok,
    p_user_id: account?.user_id ?? null,
  });

  if (upstream === 429) return json(429, { error: 'too_many_attempts', retry_after: 60 }, { 'Retry-After': '60' });
  if (!ok && outcome === 'locked_24h') return locked(false, new Date(Date.now() + 24 * 3600 * 1000).toISOString());
  if (!ok && outcome === 'locked_permanent') return locked(true, null);
  if (!ok) return INVALID();

  // 4. hand back only what the app needs to restore the session (no user object, no e-mail)
  const s = session as Record<string, unknown>;
  return json(200, {
    access_token: s.access_token,
    refresh_token: s.refresh_token,
    expires_in: s.expires_in,
    expires_at: s.expires_at,
    token_type: s.token_type,
  });
});
