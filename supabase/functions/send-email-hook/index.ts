// send-email-hook: Supabase Auth "Send Email" hook. Supabase calls this instead of its own mailer
// whenever it needs to e-mail someone a sign-in code (see docs/BREVO.md for how this is wired up in
// the Supabase dashboard). We show only the numeric code — the app's own OTP entry screen is what
// people actually use, so the magic-link URL Supabase would normally send is ignored.
//
// Every request is verified against the Standard Webhooks signature Supabase signs it with
// (SEND_EMAIL_HOOK_SECRET) before anything is parsed or sent. A per-identifier and whole-app daily
// cap (internal_otp_take) runs first so a burst of requests cannot run up the Brevo bill.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { verifyAuthHook } from '../_shared/webhook.ts';
import { sendBrevoEmail } from '../_shared/brevo.ts';
import { hashIdentifier } from '../_shared/otp_hash.ts';

const err = (code: number, message: string) => new Response(JSON.stringify({ error: { http_code: code, message } }), { status: code });

Deno.serve(async (req) => {
  if (req.method !== 'POST') return err(405, 'method_not_allowed');
  if (Number(req.headers.get('content-length') ?? '0') > 16384) return err(413, 'too_large');

  const secret = Deno.env.get('SEND_EMAIL_HOOK_SECRET');
  const rawBody = await req.text();
  if (!secret || !(await verifyAuthHook(req, rawBody, secret))) return err(401, 'invalid_signature');

  let payload: { user?: { email?: string }; email_data?: { token?: string } };
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return err(400, 'bad_request');
  }
  const email = payload.user?.email;
  const token = payload.email_data?.token;
  if (!email || !token) return err(400, 'bad_request');

  const url = Deno.env.get('SUPABASE_URL')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  if (!url || !serviceKey) return err(500, 'server_misconfigured');

  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const identifierHash = await hashIdentifier(email);
  const { data: allowed } = await admin.rpc('internal_otp_take', {
    p_channel: 'email',
    p_identifier_hash: identifierHash,
    p_max_per_id: 5,
    p_cooldown: '30 seconds',
    p_global_cap: Number(Deno.env.get('OTP_EMAIL_DAILY_CAP') ?? '300'),
  });
  if (allowed !== true) return err(429, 'rate_limited');

  const html = `
    <div style="font-family:sans-serif;font-size:16px;color:#111">
      <p>Your MyHarur sign-in code is:</p>
      <p style="font-size:32px;font-weight:700;letter-spacing:4px">${token}</p>
      <p style="color:#666">உங்கள் MyHarur குறியீடு: <b>${token}</b></p>
      <p style="color:#999;font-size:13px">This code expires in a few minutes. If you did not request it, ignore this e-mail.</p>
    </div>`;
  const ok = await sendBrevoEmail({ to: email, subject: `${token} is your MyHarur code`, html });
  if (!ok) return err(502, 'send_failed');

  return new Response('{}', { status: 200, headers: { 'Content-Type': 'application/json' } });
});
