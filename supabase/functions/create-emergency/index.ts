import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

type EmergencyPayload = {
  kind: 'police' | 'ambulance' | 'nearby_help' | 'grievance' | 'other';
  title: string;
  description: string;
  serviceAreaId?: string;
  latitude?: number;
  longitude?: number;
  accuracyMeters?: number;
  shareLocation?: boolean;
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  const authorization = request.headers.get('Authorization');
  const idempotencyKey = request.headers.get('Idempotency-Key');
  if (!authorization || !idempotencyKey) return new Response(JSON.stringify({ error: 'Authentication and Idempotency-Key are required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  const userClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: authorization } } });
  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  const payload = await request.json() as EmergencyPayload;
  if (!payload.title?.trim() || payload.title.length > 120 || !payload.description?.trim() || payload.description.length > 2000) return new Response(JSON.stringify({ error: 'Invalid emergency details' }), { status: 422, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  if (payload.shareLocation && (payload.latitude == null || payload.longitude == null)) return new Response(JSON.stringify({ error: 'Location consent requires coordinates' }), { status: 422, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  const adminClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: existing } = await adminClient.from('audit_events').select('entity_id').eq('actor_id', user.id).eq('event_type', `emergency.create:${idempotencyKey}`).maybeSingle();
  if (existing?.entity_id) return new Response(JSON.stringify({ id: existing.entity_id, reused: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  const { data: emergency, error: insertError } = await adminClient.from('emergency_cases').insert({ reporter_id: user.id, kind: payload.kind, title: payload.title.trim(), description: payload.description.trim(), service_area_id: payload.serviceAreaId ?? null, location_latitude: payload.shareLocation ? payload.latitude : null, location_longitude: payload.shareLocation ? payload.longitude : null, location_accuracy_meters: payload.shareLocation ? payload.accuracyMeters ?? null : null, location_consent_at: payload.shareLocation ? new Date().toISOString() : null }).select('id').single();
  if (insertError) return new Response(JSON.stringify({ error: 'Unable to create emergency request' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  await adminClient.from('audit_events').insert({ actor_id: user.id, event_type: `emergency.create:${idempotencyKey}`, entity_type: 'emergency_case', entity_id: emergency.id, metadata: { kind: payload.kind, locationShared: Boolean(payload.shareLocation) } });
  await adminClient.from('emergency_dispatch_attempts').insert({ case_id: emergency.id, radius_meters: 1000 });
  return new Response(JSON.stringify({ id: emergency.id, escalationRadiusMeters: 1000 }), { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
});

