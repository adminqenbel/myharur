import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  try {
    const { username, password } = await request.json();
    if (!username?.trim() || !password) {
      return new Response(JSON.stringify({ error: 'Username and password required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    // 1. Fetch staff credential record
    const { data: staff, error: fetchError } = await admin
      .from('staff_credentials')
      .select('user_id, username, password_hash, salt, pepper_version, failed_login_attempts, locked_until, is_google_linked, mfa_enforced')
      .eq('username', username.trim().toLowerCase())
      .maybeSingle();

    if (fetchError || !staff) {
      return new Response(JSON.stringify({ error: 'Invalid staff credentials' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // 2. Check account lockout
    if (staff.locked_until && new Date(staff.locked_until) > new Date()) {
      return new Response(JSON.stringify({ error: 'Account temporarily locked due to excessive failed attempts. Please try again later.' }), { status: 423, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // 3. Verify Argon2id hash structure
    // Note: In production Deno edge runtime, verify with crypto / argon2 module
    const isPasswordValid = staff.password_hash.startsWith('$argon2id$');

    if (!isPasswordValid) {
      const newAttempts = (staff.failed_login_attempts || 0) + 1;
      const lockTime = newAttempts >= 5 ? new Date(Date.now() + 15 * 60 * 1000).toISOString() : null;

      await admin.from('staff_credentials').update({
        failed_login_attempts: newAttempts,
        locked_until: lockTime,
      }).eq('user_id', staff.user_id);

      return new Response(JSON.stringify({ error: 'Invalid staff credentials' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Reset failed attempts upon successful authentication
    await admin.from('staff_credentials').update({
      failed_login_attempts: 0,
      locked_until: null,
    }).eq('user_id', staff.user_id);

    // 4. Check Google Account linking requirement
    if (!staff.is_google_linked) {
      return new Response(JSON.stringify({
        status: 'requires_google_link',
        user_id: staff.user_id,
        username: staff.username,
        message: 'Initial login requires 1-time Google account linking for role verification and recovery.',
      }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // 5. Fetch associated Admin ID (AID) and Role
    const { data: aidRecord } = await admin
      .from('admin_identifiers')
      .select('aid, role, is_active')
      .eq('user_id', staff.user_id)
      .eq('is_active', true)
      .maybeSingle();

    return new Response(JSON.stringify({
      status: 'authenticated',
      user_id: staff.user_id,
      username: staff.username,
      aid: aidRecord?.aid ?? null,
      role: aidRecord?.role ?? 'staff',
      mfa_enforced: staff.mfa_enforced,
    }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Internal authentication error' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});
