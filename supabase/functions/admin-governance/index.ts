import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

type GovernanceAction = 
  | { action: 'vote_terminate'; targetUserId: string; reason: string }
  | { action: 'superadmin_terminate'; targetUserId: string; reason: string }
  | { action: 'assign_aid'; targetUserId: string; role: 'super_admin' | 'admin' | 'moderator' | 'government_official' }
  | { action: 'revoke_aid'; targetUserId: string }
  | { action: 'approve_news'; submissionId: string }
  | { action: 'approve_event'; eventId: string };

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const authorization = request.headers.get('Authorization');
  if (!authorization) {
    return new Response(JSON.stringify({ error: 'Authorization header required' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const userClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  // Check caller permissions and AID
  const { data: callerAid } = await admin
    .from('admin_identifiers')
    .select('aid, role, is_active')
    .eq('user_id', user.id)
    .eq('is_active', true)
    .maybeSingle();

  const { data: isSuperAdmin } = await admin
    .from('super_admin_invariants')
    .select('is_primary')
    .eq('user_id', user.id)
    .maybeSingle();

  const isCallerAdmin = Boolean(callerAid || isSuperAdmin);
  if (!isCallerAdmin) {
    return new Response(JSON.stringify({ error: 'Forbidden: Admin or Super Admin role required' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const body = (await request.json()) as GovernanceAction;

  try {
    // Action 1: Multi-Admin Termination Consensus (3-Vote Requirement)
    if (body.action === 'vote_terminate') {
      const { targetUserId, reason } = body;

      // Record admin vote
      await admin.from('account_termination_votes').upsert({
        target_user_id: targetUserId,
        admin_voter_id: user.id,
        reason,
      });

      // Count total votes
      const { count } = await admin
        .from('account_termination_votes')
        .select('*', { count: 'exact', head: true })
        .eq('target_user_id', targetUserId);

      const totalVotes = count || 0;
      let terminated = false;

      if (totalVotes >= 3) {
        // Threshold met: Terminate account and revoke AIDs
        await admin.from('profiles').update({ is_suspended: true, suspended_reason: `Terminated by consensus of ${totalVotes} administrators: ${reason}` }).eq('id', targetUserId);
        await admin.from('admin_identifiers').update({ is_active: false, revoked_at: new Date().toISOString() }).eq('user_id', targetUserId);
        terminated = true;
      }

      await admin.from('audit_events').insert({
        actor_id: user.id,
        event_type: 'governance.vote_terminate',
        entity_type: 'profile',
        entity_id: targetUserId,
        metadata: { votes: totalVotes, terminated, reason },
      });

      return new Response(JSON.stringify({ success: true, totalVotes, votesRequired: 3, terminated }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Action 2: Super Admin Instant Override Termination (No 3-vote wait)
    if (body.action === 'superadmin_terminate') {
      if (!isSuperAdmin) {
        return new Response(JSON.stringify({ error: 'Forbidden: Super Admin override required' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }

      const { targetUserId, reason } = body;
      await admin.from('profiles').update({ is_suspended: true, suspended_reason: `Super Admin Instant Termination: ${reason}` }).eq('id', targetUserId);
      await admin.from('admin_identifiers').update({ is_active: false, revoked_at: new Date().toISOString() }).eq('user_id', targetUserId);

      await admin.from('audit_events').insert({
        actor_id: user.id,
        event_type: 'governance.superadmin_instant_terminate',
        entity_type: 'profile',
        entity_id: targetUserId,
        metadata: { reason },
      });

      return new Response(JSON.stringify({ success: true, terminated: true, mode: 'superadmin_instant' }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Action 3: Assign AID upon promotion
    if (body.action === 'assign_aid') {
      if (!isSuperAdmin && callerAid?.role !== 'super_admin') {
        return new Response(JSON.stringify({ error: 'Only Super Admins can assign AIDs and promote staff' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }

      const { data: newAid, error: aidError } = await admin.rpc('generate_aid');
      const aidString = newAid || `AID-HR-${Math.floor(1000 + Math.random() * 9000)}`;

      await admin.from('admin_identifiers').upsert({
        user_id: body.targetUserId,
        aid: aidString,
        role: body.role,
        assigned_by: user.id,
        is_active: true,
      });

      return new Response(JSON.stringify({ success: true, aid: aidString, role: body.role }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Action 4: Revoke AID upon demotion
    if (body.action === 'revoke_aid') {
      if (!isSuperAdmin) {
        return new Response(JSON.stringify({ error: 'Only Super Admins can revoke AIDs' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }

      await admin.from('admin_identifiers').update({ is_active: false, revoked_at: new Date().toISOString() }).eq('user_id', body.targetUserId);
      return new Response(JSON.stringify({ success: true, revoked: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Action 5: Approve news
    if (body.action === 'approve_news') {
      const { data: submission } = await admin.from('news_submissions').select('*').eq('id', body.submissionId).single();
      if (!submission) return new Response(JSON.stringify({ error: 'Submission not found' }), { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

      await admin.from('news_items').insert({
        title: submission.title,
        content: submission.content,
        source_url: submission.source_url,
        category: submission.category,
        status: 'published',
        approved_by: user.id,
        published_at: new Date().toISOString(),
      });

      await admin.from('news_submissions').update({ status: 'approved' }).eq('id', body.submissionId);
      return new Response(JSON.stringify({ success: true, published: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Action 6: Approve event and assign Event Head
    if (body.action === 'approve_event') {
      const { data: ev } = await admin.from('events').select('*').eq('id', body.eventId).single();
      if (!ev) return new Response(JSON.stringify({ error: 'Event not found' }), { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

      await admin.from('events').update({
        status: 'approved',
        event_head_id: ev.creator_id,
        approved_by: user.id,
      }).eq('id', body.eventId);

      // Automatically create event chat room
      await admin.from('chat_rooms').insert({
        name: `${ev.title} (Event Room)`,
        room_type: 'temporary_event',
        event_id: ev.id,
        created_by: user.id,
      });

      return new Response(JSON.stringify({ success: true, approved: true, eventHeadId: ev.creator_id }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    return new Response(JSON.stringify({ error: 'Unknown action' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Governance processing failed' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});
