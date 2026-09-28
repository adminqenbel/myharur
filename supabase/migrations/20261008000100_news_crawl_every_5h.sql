-- Slows the news crawl from every 30 minutes to every 5 hours (user request), since headlines don't
-- change often enough to justify the tighter schedule. cron.schedule() with the same job name replaces
-- the existing schedule in place; this is a no-op (with a notice) if the crawler was never scheduled.
do $$
begin
  if not exists (select 1 from vault.decrypted_secrets where name = 'myharur_cron_secret') then
    raise notice 'vault secret myharur_cron_secret not found - crawler NOT (re)scheduled (see docs/NEWS.md)';
    return;
  end if;
  perform cron.schedule(
    'myharur-news-crawl',
    '0 */5 * * *',
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
  raise notice 'could not reschedule crawler: %', sqlerrm;
end $$;
