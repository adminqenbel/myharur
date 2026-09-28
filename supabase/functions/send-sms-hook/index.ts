// send-sms-hook: Supabase Auth "Send SMS" hook, used for phone sign-in codes. See docs/BREVO.md
// for how this is wired up in the Supabase dashboard, and send-email-hook for the matching e-mail
// side. English-only and short by design: mixing Tamil forces UCS-2 SMS encoding, which roughly
// halves the character limit per segment and doubles the cost for no real benefit on a 6-digit code.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { verifyAuthHook } from '../_shared/webhook.ts';
import { sendBrevoSms } from '../_shared/brevo.ts';
import { hashIdentifier } from '../_shared/otp_hash.ts';

const err = (code: number, message: string) => new Response(JSON.stringify({ error: { http_code: code, message } }), { status: code });

Deno.serve(async (req) => {
  if (req.method !== 'POST') return err(405, 'method_not_allowed');
  if (Number(req.headers.get('content-length') ?? '0') > 16384) return err(413, 'too_large');

  const secret = Deno.env.get('SEND_SMS_HOOK_SECRET');
  const rawBody = await req.text();
  if (!secret || !(await verifyAuthHook(req, rawBody, secret))) return err(401, 'invalid_signature');

  let payload: { user?: { phone?: string }; sms?: { otp?: string } };
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return err(400, 'bad_request');
  }
  const phone = payload.user?.phone;
  const otp = payload.sms?.otp;
  if (!phone || !otp) return err(400, 'bad_request');

  const url = Deno.env.get('SUPABASE_URL')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  if (!url || !serviceKey) return err(500, 'server_misconfigured');

  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const identifierHash = await hashIdentifier(phone);
  const { data: allowed } = await admin.rpc('internal_otp_take', {
    p_channel: 'sms',
    p_identifier_hash: identifierHash,
    p_max_per_id: 5,
    p_cooldown: '30 seconds',
    p_global_cap: Number(Deno.env.get('OTP_SMS_DAILY_CAP') ?? '50'),
  });
  if (allowed !== true) return err(429, 'rate_limited');

  const ok = await sendBrevoSms({ to: phone, text: `MyHarur code: ${otp} (valid a few minutes). Do not share it.` });
  if (!ok) return err(502, 'send_failed');

  return new Response('{}', { status: 200, headers: { 'Content-Type': 'application/json' } });
});
