-- Runs the news-crawler edge function every 30 minutes.
-- Prerequisites (one-time, done by hand; never committed):
--   1. supabase secrets set CRON_SECRET=<random>          (edge function checks x-cron-secret)
--   2. select vault.create_secret('<same random>', 'myharur_cron_secret');
--   3. supabase functions deploy news-crawler --no-verify-jwt
-- See docs/NEWS.md.
do $$
begin
  if not exists (select 1 from vault.decrypted_secrets where name = 'myharur_cron_secret') then
    raise notice 'vault secret myharur_cron_secret not found - crawler NOT scheduled (see docs/NEWS.md)';
    return;
  end if;
  perform cron.schedule(
    'myharur-news-crawl',
    '*/30 * * * *',
    $job$
      select net.http_post(
        url     := 'https://qpuvhhvzygdbvlichbqs.supabase.co/functions/v1/news-crawler',
        headers := jsonb_build_object(
                     'Content-Type', 'application/json',
                     'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'myharur_cron_secret')),
        body    := '{}'::jsonb,
        timeout_milliseconds := 60000
      );
    $job$
  );
exception when others then
  raise notice 'could not schedule crawler: %', sqlerrm;
end $$;
