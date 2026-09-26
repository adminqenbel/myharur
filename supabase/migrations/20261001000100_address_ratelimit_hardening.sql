-- ==============================================================================
-- MyHarur v1.2 (phase 1) - wards -> optional address, rate limiting, login lockout,
-- client error log, server-side username rules, audit-log immutability, text limits.
-- Safe to re-run.
-- (Regexes below avoid backslashes on purpose so the file survives copy/paste tooling.)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Wards removed; optional address on profiles; structured location on alerts
-- ------------------------------------------------------------------------------
-- alerts_after_insert referenced moderation_queue.ward_id: redefine it first.
create or replace function public.alerts_after_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'pending' then
    insert into public.moderation_queue
      (alert_id, category, emergency_tagged, flagged_by_system, expires_at)
    values
      (new.id, new.category, new.emergency_tagged, new.flagged_by_system,
       coalesce(new.expires_at, now() + interval '24 hours'));
  end if;
  return new;
end $$;
revoke execute on function public.alerts_after_insert() from public, anon, authenticated;

alter table public.moderation_queue drop column if exists ward_id;
alter table public.alerts           drop column if exists ward_id;
alter table public.profiles         drop column if exists ward_id;
alter table public.profiles         drop column if exists ward_verified;
drop table if exists public.wards cascade;

alter table public.profiles
  add column if not exists address_text   text,
  add column if not exists address_lat    double precision,
  add column if not exists address_lng    double precision,
  add column if not exists address_source text;          -- 'map' | 'typed' | 'gps'

alter table public.alerts
  add column if not exists location_text   text,
  add column if not exists location_lat    double precision,
  add column if not exists location_lng    double precision,
  add column if not exists location_source text;

alter table public.profiles drop constraint if exists profiles_address_check;
alter table public.profiles add constraint profiles_address_check check (
  (address_lat is null) = (address_lng is null)
  and (address_lat is null or address_lat between -90 and 90)
  and (address_lng is null or address_lng between -180 and 180)
  and (address_source is null or address_source in ('map','typed','gps'))
  and char_length(coalesce(address_text, '')) <= 200);

alter table public.alerts drop constraint if exists alerts_location_check;
alter table public.alerts add constraint alerts_location_check check (
  (location_lat is null) = (location_lng is null)
  and (location_lat is null or location_lat between -90 and 90)
  and (location_lng is null or location_lng between -180 and 180)
  and (location_source is null or location_source in ('map','typed','gps'))
  and char_length(coalesce(location_text, '')) <= 200);

-- Defence in depth: length limits on every free-text column users can write.
alter table public.alerts drop constraint if exists alerts_text_len;
alter table public.alerts add constraint alerts_text_len check (
  char_length(title) <= 100 and char_length(body) <= 500);

alter table public.profiles drop constraint if exists profiles_text_len;
alter table public.profiles add constraint profiles_text_len check (
  char_length(coalesce(full_name, ''))              <= 80
  and char_length(coalesce(phone, ''))              <= 20
  and char_length(coalesce(bio, ''))                <= 300
  and char_length(coalesce(emergency_contact_name, ''))  <= 80
  and char_length(coalesce(emergency_contact_phone, '')) <= 20);

-- The profile guard referenced the dropped ward_verified column: redefine it.
-- Users may edit their own profile (including the optional address) but not trust/identity columns.
create or replace function public.profiles_protect_columns()
returns trigger language plpgsql set search_path = public as $$
begin
  if current_setting('myharur.profile_guard_bypass', true) = 'on'
     or coalesce(auth.role(), 'service_role') = 'service_role' then
    return new;
  end if;
  new.id                := old.id;
  new.mmid              := old.mmid;
  new.qenbel_uid        := old.qenbel_uid;
  new.email             := old.email;
  new.phone_verified    := old.phone_verified;
  new.emergency_strikes := old.emergency_strikes;
  new.is_active         := old.is_active;
  new.created_at        := old.created_at;
  return new;
end $$;
revoke execute on function public.profiles_protect_columns() from public, anon, authenticated;

-- ------------------------------------------------------------------------------
-- 2. Server-side username rules (previously only checked in the app)
-- ------------------------------------------------------------------------------
-- SECURITY DEFINER: the word list is not readable by API roles, and an invoker-rights version
-- would silently see an empty list and let profanity through.
create or replace function public.profiles_validate_username()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  u text;
begin
  if new.username is null then return new; end if;
  if tg_op = 'UPDATE' and new.username is not distinct from old.username then return new; end if;

  if new.username !~ '^@[a-z0-9_]{3,30}$' then
    raise exception 'username_invalid' using errcode = 'P0001';
  end if;

  u := replace(substr(new.username, 2), '_', '');
  if exists (
    select 1 from (values ('admin'),('superadmin'),('qenbel'),('qenshar'),('official'),('govt'),
                          ('police'),('harur'),('dharmapuri'),('support'),('moderator'),('myharur'),('system')) r(t)
    where u = r.t or (u like r.t || '%' and char_length(u) <= char_length(r.t) + 4)
  ) then
    raise exception 'username_reserved' using errcode = 'P0001';
  end if;

  if exists (select 1 from public.profanity_wordlist p where strpos(u, lower(p.term)) > 0) then
    raise exception 'username_bad' using errcode = 'P0001';
  end if;
  return new;
end $$;
revoke execute on function public.profiles_validate_username() from public, anon, authenticated;

drop trigger if exists profiles_validate_username on public.profiles;
create trigger profiles_validate_username before insert or update of username on public.profiles
  for each row execute function public.profiles_validate_username();

-- ------------------------------------------------------------------------------
-- 3. Generic per-user rate limiting (used by every write path from now on)
-- ------------------------------------------------------------------------------
create table if not exists public.rate_limits (
  user_id      uuid        not null,
  action       text        not null,
  window_start timestamptz not null default now(),
  hits         int         not null default 0,
  primary key (user_id, action)
);
alter table public.rate_limits enable row level security;      -- no policies: functions only
revoke all on public.rate_limits from anon, authenticated;

create or replace function public.enforce_rate_limit(p_action text, p_max int, p_window interval)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := auth.uid();
  v_hits int;
begin
  if v_uid is null then raise exception 'authentication_required' using errcode = '42501'; end if;
  insert into public.rate_limits as r (user_id, action, window_start, hits)
  values (v_uid, p_action, now(), 1)
  on conflict (user_id, action) do update
    set window_start = case when r.window_start < now() - p_window then now() else r.window_start end,
        hits         = case when r.window_start < now() - p_window then 1 else r.hits + 1 end
  returning hits into v_hits;
  if v_hits > p_max then raise exception 'rate_limited' using errcode = 'P0001'; end if;
end $$;
revoke execute on function public.enforce_rate_limit(text, int, interval) from public, anon;
grant  execute on function public.enforce_rate_limit(text, int, interval) to authenticated;

-- ------------------------------------------------------------------------------
-- 4. Username-login lockout (called only by the username-login edge function)
-- ------------------------------------------------------------------------------
create table if not exists public.auth_attempts (
  id         bigserial   primary key,
  user_hash  text        not null,        -- sha256(pepper + username): the raw name is never stored
  ip_hash    text,
  ok         boolean     not null,
  created_at timestamptz not null default now()
);
create index if not exists auth_attempts_user_idx on public.auth_attempts (user_hash, created_at desc);
create index if not exists auth_attempts_ip_idx   on public.auth_attempts (ip_hash, created_at desc);
alter table public.auth_attempts enable row level security;
revoke all on public.auth_attempts from anon, authenticated;

-- Seconds the caller must wait (0 = allowed).
--   per username: 5 failures in 15 min -> locked 15 min from the last failure, doubling (max x16)
--                 for every further 5 failures in 24 h
--   per IP:       20 failures in 1 h   -> locked 1 h from the last failure
create or replace function public.login_retry_after(p_user_hash text, p_ip_hash text)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_last_ok    timestamptz;
  v_fail15     int;
  v_fail24     int;
  v_last_fail  timestamptz;
  v_ip_fail    int;
  v_ip_last    timestamptz;
  v_wait_user  numeric := 0;
  v_wait_ip    numeric := 0;
begin
  select max(created_at) into v_last_ok from public.auth_attempts where user_hash = p_user_hash and ok;

  select count(*) filter (where created_at > now() - interval '15 minutes'),
         count(*),
         max(created_at)
    into v_fail15, v_fail24, v_last_fail
    from public.auth_attempts
   where user_hash = p_user_hash and not ok
     and created_at > now() - interval '24 hours'
     and created_at > coalesce(v_last_ok, '-infinity'::timestamptz);

  if v_fail15 >= 5 then
    v_wait_user := extract(epoch from (
      v_last_fail + interval '15 minutes' * power(2, least(greatest(v_fail24 / 5 - 1, 0), 4)) - now()));
  end if;

  if p_ip_hash is not null then
    select count(*), max(created_at) into v_ip_fail, v_ip_last
      from public.auth_attempts
     where ip_hash = p_ip_hash and not ok and created_at > now() - interval '1 hour';
    if v_ip_fail >= 20 then
      v_wait_ip := extract(epoch from (v_ip_last + interval '1 hour' - now()));
    end if;
  end if;

  return greatest(0, ceil(greatest(v_wait_user, v_wait_ip)))::int;
end $$;

create or replace function public.record_login_attempt(p_user_hash text, p_ip_hash text, p_ok boolean)
returns void language sql security definer set search_path = public as $$
  insert into public.auth_attempts (user_hash, ip_hash, ok) values (p_user_hash, p_ip_hash, p_ok);
$$;

-- Email for a username, only if the account is active. Service role only.
create or replace function public.internal_lookup_login(p_username text)
returns table (user_id uuid, email text) language sql stable security definer set search_path = public as $$
  select p.id, u.email::text
    from public.profiles p
    join auth.users u on u.id = p.id
   where p.username = lower(p_username) and p.is_active;
$$;

do $$
declare f text;
begin
  foreach f in array array['login_retry_after(text,text)', 'record_login_attempt(text,text,boolean)', 'internal_lookup_login(text)'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to service_role', f);
  end loop;
end $$;

-- ------------------------------------------------------------------------------
-- 5. Client error log (crash / login failure reports). Super admins read it.
-- ------------------------------------------------------------------------------
create or replace function public.is_superadmin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles
                  where uid = auth.uid() and revoked_at is null and role = 'superadmin');
$$;
revoke all on function public.is_superadmin() from public;
grant execute on function public.is_superadmin() to anon, authenticated;

create table if not exists public.client_errors (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete set null,
  kind        text not null check (kind in ('crash','auth','network','bug')),
  message     text,
  stack       text,
  screen      text,
  app_version text,
  os          text,
  details     text,
  status      text not null default 'new' check (status in ('new','seen','fixed')),
  created_at  timestamptz not null default now()
);
create index if not exists client_errors_created_idx on public.client_errors (created_at desc);
alter table public.client_errors enable row level security;
revoke all on public.client_errors from anon, authenticated;
grant select, update (status) on public.client_errors to authenticated;
drop policy if exists client_errors_super_read   on public.client_errors;
drop policy if exists client_errors_super_update on public.client_errors;
create policy client_errors_super_read   on public.client_errors for select using (public.is_superadmin());
create policy client_errors_super_update on public.client_errors for update
  using (public.is_superadmin()) with check (public.is_superadmin());

-- Strips anything that looks like a token or e-mail address before storing.
create or replace function public.redact(p_text text)
returns text language sql immutable set search_path = public as $$
  select regexp_replace(
           regexp_replace(coalesce(p_text, ''),
             'eyJ[-A-Za-z0-9_]{8,}([.][-A-Za-z0-9_]+){1,2}', '[token]', 'g'),
           '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}', '[email]', 'g');
$$;

create or replace function public.log_client_error(
  p_kind text, p_message text, p_stack text, p_screen text,
  p_app_version text, p_os text, p_details text default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.enforce_rate_limit('client_error', 20, interval '1 day');
  insert into public.client_errors (user_id, kind, message, stack, screen, app_version, os, details)
  values (auth.uid(),
          case when p_kind in ('crash','auth','network','bug') then p_kind else 'crash' end,
          left(public.redact(p_message), 500),
          left(public.redact(p_stack), 4000),
          left(p_screen, 80), left(p_app_version, 40), left(p_os, 80),
          left(public.redact(p_details), 2000));
end $$;
revoke execute on function public.log_client_error(text,text,text,text,text,text,text) from public, anon;
grant  execute on function public.log_client_error(text,text,text,text,text,text,text) to authenticated;

-- ------------------------------------------------------------------------------
-- 6. Audit log is append-only
-- ------------------------------------------------------------------------------
-- The only allowed change: deleting a user nulls user_id on their old rows (ON DELETE SET NULL),
-- which the database performs as an UPDATE. Everything else is refused.
create or replace function public.audit_log_immutable()
returns trigger language plpgsql set search_path = public as $$
begin
  if tg_op = 'UPDATE'
     and new.user_id is null and old.user_id is not null
     and (to_jsonb(new) - 'user_id') = (to_jsonb(old) - 'user_id') then
    return new;
  end if;
  raise exception 'audit_log_is_append_only' using errcode = '42501';
end $$;
revoke execute on function public.audit_log_immutable() from public, anon, authenticated;

drop trigger if exists audit_log_no_update on public.crud_audit_logs;
create trigger audit_log_no_update before update or delete on public.crud_audit_logs
  for each row execute function public.audit_log_immutable();
revoke update, delete on public.crud_audit_logs from anon, authenticated;

-- ------------------------------------------------------------------------------
-- 7. Housekeeping
-- ------------------------------------------------------------------------------
create or replace function public.prune_security_tables()
returns void language sql security definer set search_path = public as $$
  delete from public.auth_attempts where created_at < now() - interval '2 days';
  delete from public.rate_limits   where window_start < now() - interval '2 days';
  delete from public.client_errors where created_at < now() - interval '90 days';
$$;
revoke all on function public.prune_security_tables() from public, anon, authenticated;

do $$
begin
  perform cron.schedule('myharur-prune-security', '43 3 * * *', 'select public.prune_security_tables()');
exception when others then
  raise notice 'pg_cron unavailable (%); schedule prune_security_tables() manually.', sqlerrm;
end $$;
