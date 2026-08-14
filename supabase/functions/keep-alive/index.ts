import { corsHeaders } from '../_shared/cors.ts';

// Lightweight Keep-Alive Endpoint
// Pinned via scheduled cron to eliminate cold-start delays on free-tier services
Deno.serve((request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const timestamp = new Date().toISOString();
  return new Response(
    JSON.stringify({
      status: 'active',
      service: 'myharur-edge-runtime',
      timestamp,
      region: 'ap-south-1',
      uptime: '100%',
    }),
    {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
});
