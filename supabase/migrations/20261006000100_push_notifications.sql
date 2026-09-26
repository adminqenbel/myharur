-- ==============================================================================
-- Push notifications (Firebase Cloud Messaging), built to stay useful and never spammy.
--
--   * one report digest a day at most, and only when there is something new
--   * event alerts (when events launch): at most 2 a week
--   * quiet hours 22:00-07:00 India time: nothing is sent
--   * every person can switch it all off, or each kind, in Account > Notifications
-- The caps live here in the database, so a bug or a mis-configured job in the sender cannot exceed them.
-- Tokens are private: nobody can read them through the API; the sender uses service-role helpers.
-- ==============================================================================
create table if not exists public.push_tokens (
  token      text primary key check (char_length(token) between 20 and 4096),
  user_id    uuid not null references auth.users(id) on delete cascade,
  lang       text not null default 'en' check (lang in ('en', 'ta')),
  platform   text not null default 'android' check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  last_seen  timestamptz not null default now()
);
create index if not exists push_tokens_user_idx on public.push_tokens (user_id);
alter table public.push_tokens enable row level security;
revoke all on public.push_tokens from anon, authenticated;

create table if not exists public.notification_prefs (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  enabled    boolean not null default true,     -- master switch
  reports    boolean not null default true,
  events     boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.notification_prefs enable row level security;
revoke all on public.notification_prefs from anon, authenticated;

create table if not exists public.notification_log (
  id         bigserial primary key,
  kind       text not null check (kind in ('reports_digest', 'event')),
  sent_at    timestamptz not null default now(),
  recipients int  not null default 0,
  detail     jsonb not null default '{}'
);
create index if not exists notification_log_kind_idx on public.notification_log (kind, sent_at desc);
alter table public.notification_log enable row level security;
revoke all on public.notification_log from anon, authenticated;

-- ------------------------------------------------------------------------------
-- The app (signed-in person)
-- ------------------------------------------------------------------------------
create or replace function public.register_push_token(p_token text, p_lang text, p_platform text default 'android')
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  if p_token is null or char_length(p_token) not between 20 and 4096 then
    raise exception 'invalid_token' using errcode = '22023';
  end if;
  perform public.enforce_rate_limit('push_token', 20, interval '1 day');

  insert into public.push_tokens (token, user_id, lang, platform)
  values (p_token, auth.uid(), case when p_lang = 'ta' then 'ta' else 'en' end,
          case when p_platform in ('android', 'ios', 'web') then p_platform else 'android' end)
  on conflict (token) do update
    set user_id = auth.uid(), lang = excluded.lang, platform = excluded.platform, last_seen = now();

  -- a phone can hold a few accounts, but never an unbounded number of tokens
  delete from public.push_tokens
   where user_id = auth.uid()
     and token in (select token from public.push_tokens where user_id = auth.uid()
                   order by last_seen desc offset 5);

  insert into public.notification_prefs (user_id) values (auth.uid()) on conflict do nothing;
end $$;
revoke all on function public.register_push_token(text, text, text) from public, anon;
grant execute on function public.register_push_token(text, text, text) to authenticated;

create or replace function public.unregister_push_token(p_token text)
returns void language sql security definer set search_path = public as $$
  delete from public.push_tokens where token = p_token and user_id = auth.uid();
$$;
revoke all on function public.unregister_push_token(text) from public, anon;
grant execute on function public.unregister_push_token(text) to authenticated;

create or replace function public.my_notification_prefs()
returns table (enabled boolean, reports boolean, events boolean)
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  insert into public.notification_prefs (user_id) values (auth.uid()) on conflict do nothing;
  return query select p.enabled, p.reports, p.events from public.notification_prefs p where p.user_id = auth.uid();
end $$;
revoke all on function public.my_notification_prefs() from public, anon;
grant execute on function public.my_notification_prefs() to authenticated;

create or replace function public.set_notification_prefs(p_enabled boolean, p_reports boolean, p_events boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  insert into public.notification_prefs (user_id, enabled, reports, events, updated_at)
  values (auth.uid(), coalesce(p_enabled, true), coalesce(p_reports, true), coalesce(p_events, true), now())
  on conflict (user_id) do update
    set enabled = excluded.enabled, reports = excluded.reports, events = excluded.events, updated_at = now();
end $$;
revoke all on function public.set_notification_prefs(boolean, boolean, boolean) from public, anon;
grant execute on function public.set_notification_prefs(boolean, boolean, boolean) to authenticated;

-- ------------------------------------------------------------------------------
-- The sender (push-digest edge function, service role only)
-- ------------------------------------------------------------------------------

-- True inside quiet hours (22:00-07:00 India time).
create or replace function public.in_quiet_hours(p_at timestamptz default now())
returns boolean language sql immutable set search_path = public as $$
  select extract(hour from p_at at time zone 'Asia/Kolkata') >= 22
      or extract(hour from p_at at time zone 'Asia/Kolkata') < 7;
$$;

-- Everything the sender needs for the daily report digest, or allowed = false when it must stay silent.
-- Silent when: quiet hours, a digest already went out in the last 20 hours, or nothing new is live.
create or replace function public.internal_digest_plan(p_now timestamptz default now())
returns table (allowed boolean, reason text, new_reports int, titles text[])
language plpgsql security definer set search_path = public as $$
declare
  v_last  timestamptz;
  v_since timestamptz;
  v_n     int;
  v_titles text[];
begin
  if public.in_quiet_hours(p_now) then
    return query select false, 'quiet_hours', 0, '{}'::text[]; return;
  end if;
  select max(sent_at) into v_last from public.notification_log where kind = 'reports_digest';
  if v_last is not null and v_last > p_now - interval '20 hours' then
    return query select false, 'already_sent', 0, '{}'::text[]; return;
  end if;
  v_since := coalesce(v_last, p_now - interval '24 hours');

  select count(*)::int, coalesce(array_agg(title order by reviewed_at desc) filter (where true), '{}')
    into v_n, v_titles
    from (select title, reviewed_at from public.alerts
           where kind = 'report' and status = 'published' and deleted_at is null
             and reviewed_at > v_since and (expires_at is null or expires_at > p_now)
           order by reviewed_at desc limit 50) r;
  if v_n = 0 then
    return query select false, 'nothing_new', 0, '{}'::text[]; return;
  end if;
  return query select true, 'ok', v_n, v_titles[1:3];
end $$;

-- Devices to notify about the digest: people with both switches on, active accounts only.
create or replace function public.internal_digest_tokens()
returns table (token text, lang text)
language sql stable security definer set search_path = public as $$
  select t.token, t.lang
    from public.push_tokens t
    join public.notification_prefs p on p.user_id = t.user_id
    join public.profiles pr on pr.id = t.user_id
   where p.enabled and p.reports and pr.is_active
     and not exists (select 1 from public.user_restrictions r where r.user_id = t.user_id and r.status = 'banned');
$$;

create or replace function public.internal_log_notification(p_kind text, p_recipients int, p_detail jsonb default '{}')
returns void language sql security definer set search_path = public as $$
  insert into public.notification_log (kind, recipients, detail) values (p_kind, p_recipients, coalesce(p_detail, '{}'));
$$;

-- Tokens Firebase reported as gone (app uninstalled): forget them.
create or replace function public.internal_drop_tokens(p_tokens text[])
returns int language plpgsql security definer set search_path = public as $$
declare v int;
begin
  delete from public.push_tokens where token = any(p_tokens);
  get diagnostics v = row_count;
  return v;
end $$;

-- Event alerts: at most 2 a week, never in quiet hours. Returns true when one may go out now (and reserves it).
create or replace function public.internal_event_push_allowed(p_now timestamptz default now())
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if public.in_quiet_hours(p_now) then return false; end if;
  if (select count(*) from public.notification_log where kind = 'event' and sent_at > p_now - interval '7 days') >= 2 then
    return false;
  end if;
  insert into public.notification_log (kind, recipients, detail) values ('event', 0, '{"reserved":true}');
  return true;
end $$;

do $$
declare f text;
begin
  foreach f in array array[
    'in_quiet_hours(timestamptz)', 'internal_digest_plan(timestamptz)', 'internal_digest_tokens()',
    'internal_log_notification(text,int,jsonb)', 'internal_drop_tokens(text[])', 'internal_event_push_allowed(timestamptz)'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to service_role', f);
  end loop;
end $$;

create or replace function public.prune_security_tables()
returns void language sql security definer set search_path = public as $$
  delete from public.auth_attempts   where created_at < now() - interval '2 days';
  delete from public.rate_limits     where window_start < now() - interval '2 days';
  delete from public.client_errors   where created_at < now() - interval '90 days';
  delete from public.security_events where created_at < now() - interval '365 days';
  delete from public.user_reports    where status = 'reviewed' and created_at < now() - interval '180 days';
  delete from public.ai_usage        where day < current_date - 30;
  delete from public.notification_log where sent_at < now() - interval '90 days';
  delete from public.push_tokens     where last_seen < now() - interval '120 days';   -- phones that never came back
$$;
revoke all on function public.prune_security_tables() from public, anon, authenticated;

-- Daily digest job (18:00 India time). The function itself decides whether anything is sent.
do $$
begin
  if not exists (select 1 from vault.decrypted_secrets where name = 'myharur_cron_secret') then
    raise notice 'vault secret myharur_cron_secret not found - push digest NOT scheduled';
    return;
  end if;
  perform cron.schedule(
    'myharur-push-digest',
    '30 12 * * *',
    $job$
      select net.http_post(
        url     := 'https://qpuvhhvzygdbvlichbqs.supabase.co/functions/v1/push-digest',
        headers := jsonb_build_object(
                     'Content-Type', 'application/json',
                     'apikey', 'sb_publishable_Fl1qvB5E-gt2hxwE6QDXpQ_7SuU3ZPV',
                     'Authorization', 'Bearer sb_publishable_Fl1qvB5E-gt2hxwE6QDXpQ_7SuU3ZPV',
                     'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'myharur_cron_secret')),
        body    := '{}'::jsonb,
        timeout_milliseconds := 60000
      );
    $job$
  );
exception when others then
  raise notice 'could not schedule push digest: %', sqlerrm;
end $$;
