// content-purge: nightly clean-up of photos.
//   1. files of posts deleted more than 30 days ago, and uploads never attached to a post (older than a day)
//   2. then the database rows of long-deleted posts whose files are gone
// Files are removed through the Storage API (deleting storage.objects rows in SQL would leave the bytes behind).
//
// Auth: pg_cron/pg_net sends  x-cron-secret: <CRON_SECRET>  (same secret as news-crawler). Deployed with --no-verify-jwt.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' } });

// constant-time comparison so the secret cannot be guessed from response timing
function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json(405, { error: 'method_not_allowed' });
  const secret = Deno.env.get('CRON_SECRET');
  const given = req.headers.get('x-cron-secret') ?? '';
  if (!secret || !safeEqual(given, secret)) return json(401, { error: 'unauthorized' });

  const url = Deno.env.get('SUPABASE_URL')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const db = createClient(url, serviceKey, { auth: { persistSession: false } });

  const { data: rows, error } = await db.rpc('internal_purge_candidates');
  if (error) return json(500, { error: 'candidates_failed' });

  const paths = [...new Set((rows ?? []).map((r: { path: string }) => r.path))];
  let removed = 0;
  for (let i = 0; i < paths.length; i += 100) {
    const batch = paths.slice(i, i + 100);
    const { data, error: rmError } = await db.storage.from('content-images').remove(batch);
    if (!rmError) removed += data?.length ?? 0;
  }

  const { data: purged } = await db.rpc('internal_purge_deleted_rows');
  return json(200, { candidates: paths.length, files_removed: removed, posts_purged: purged ?? 0 });
});
