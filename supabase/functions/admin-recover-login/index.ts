// admin-recover-login: a super admin unlocks an account whose password sign-in was disabled, and gives the
// person a one-time temporary password.
//
//   1. The caller's own JWT calls the database function admin_recover_login(uid, reason). It enforces
//      "super admin + two-factor session + written reason", clears the lock, flags must_change_password,
//      signs the person out everywhere and writes the audit trail. If it refuses, we stop here.
//   2. Only then does the service role set a random password on the account (GoTrue hashes it).
//   3. The password is returned ONCE in the response. It is never stored or logged; the person is forced to
//      choose their own at next sign-in.
//
// Deployed with --no-verify-jwt: the function verifies the caller itself through the database call in step 1.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'content-type, authorization, apikey',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', ...cors },
  });

// 16 characters from an unambiguous alphabet, drawn with rejection sampling (no modulo bias).
function tempPassword(): string {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  const limit = 256 - (256 % alphabet.length);
  for (;;) {
    let out = '';
    while (out.length < 16) {
      for (const b of crypto.getRandomValues(new Uint8Array(32))) {
        if (b < limit && out.length < 16) out += alphabet[b % alphabet.length];
      }
    }
    // the password policy wants upper, lower and a digit
    if (/[A-Z]/.test(out) && /[a-z]/.test(out) && /[0-9]/.test(out)) return out;
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
  if (req.method !== 'POST') return json(405, { error: 'method_not_allowed' });
  if (Number(req.headers.get('content-length') ?? '0') > 2048) return json(413, { error: 'too_large' });

  const authorization = req.headers.get('authorization') ?? '';
  if (!authorization.toLowerCase().startsWith('bearer ')) return json(401, { error: 'unauthorized' });

  let body: { uid?: unknown; reason?: unknown };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: 'bad_request' });
  }
  const uid = typeof body.uid === 'string' ? body.uid : '';
  const reason = typeof body.reason === 'string' ? body.reason : '';
  if (!/^[0-9a-f-]{36}$/i.test(uid)) return json(400, { error: 'bad_request' });

  const url = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  if (!url || !anonKey || !serviceKey) return json(500, { error: 'server_misconfigured' });

  // 1. as the caller: authorisation happens inside the database function
  const asCaller = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { error } = await asCaller.rpc('admin_recover_login', { p_uid: uid, p_reason: reason });
  if (error) {
    const m = error.message ?? '';
    if (m.includes('aal2_required')) return json(403, { error: 'aal2_required' });
    if (m.includes('reason_required')) return json(422, { error: 'reason_required' });
    if (m.includes('not_found')) return json(404, { error: 'not_found' });
    return json(403, { error: 'forbidden' });
  }

  // 2. set the temporary password
  const password = tempPassword();
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const { error: pwError } = await admin.auth.admin.updateUserById(uid, { password });
  if (pwError) return json(500, { error: 'password_not_set' });

  return json(200, { temporary_password: password });
});
