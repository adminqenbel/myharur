-- ==============================================================================
-- Login-failure escalation and super-admin recovery.
--
-- Scope: applies to @username + password sign-in ONLY. Google sign-in is never blocked by it.
-- Why: the username is public. If failed guesses could ban the whole account, anyone could lock
-- any resident out of the app. A lock therefore removes only the password path.
--
--   5 consecutive failures (no success in between)  -> password login paused for 24 h   (a "strike")
--   LOCK_STRIKES (3) strikes with no success between -> password login disabled until a super admin
--                                                       recovers the account with a written reason
--   any successful login resets the counters
--
-- Every lock and every recovery is written to security_events; recovery is also in the audit log.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Tables
-- ------------------------------------------------------------------------------
create table if not exists public.login_locks (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  strikes      int         not null default 0,
  locked_until timestamptz,
  permanent    boolean     not null default false,
  last_lock_at timestamptz,
  updated_at   timestamptz not null default now()
);
alter table public.login_locks enable row level security;
revoke all on public.login_locks from anon, authenticated;

create table if not exists public.security_events (
  id         bigserial   primary key,
  user_id    uuid        references auth.users(id) on delete set null,
  kind       text        not null check (kind in ('login_lock_24h', 'login_lock_permanent', 'login_recovered')),
  detail     jsonb       not null default '{}',
  created_at timestamptz not null default now()
);
create index if not exists security_events_created_idx on public.security_events (created_at desc);
alter table public.security_events enable row level security;
revoke all on public.security_events from anon, authenticated;
grant select on public.security_events to authenticated;
drop policy if exists security_events_super_read on public.security_events;
create policy security_events_super_read on public.security_events for select using (public.is_superadmin());

-- ------------------------------------------------------------------------------
-- 2. Profile flag: the person must choose a new password after a recovery
-- ------------------------------------------------------------------------------
alter table public.profiles add column if not exists must_change_password boolean not null default false;

create or replace function public.profiles_protect_columns()
returns trigger language plpgsql set search_path = public as $$
begin
  if current_setting('myharur.profile_guard_bypass', true) = 'on'
     or coalesce(auth.role(), 'service_role') = 'service_role' then
    return new;
  end if;
  new.id                   := old.id;
  new.mmid                 := old.mmid;
  new.qenbel_uid           := old.qenbel_uid;
  new.email                := old.email;
  new.phone_verified       := old.phone_verified;
  new.emergency_strikes    := old.emergency_strikes;
  new.is_active            := old.is_active;
  new.must_change_password := old.must_change_password;
  new.created_at           := old.created_at;
  return new;
end $$;
revoke execute on function public.profiles_protect_columns() from public, anon, authenticated;

-- Called by the app after the person has set their new password.
create or replace function public.clear_must_change_password()
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  perform set_config('myharur.profile_guard_bypass', 'on', true);
  update public.profiles set must_change_password = false where id = auth.uid();
  perform set_config('myharur.profile_guard_bypass', 'off', true);
end $$;
revoke all on function public.clear_must_change_password() from public, anon;
grant execute on function public.clear_must_change_password() to authenticated;

-- ------------------------------------------------------------------------------
-- 3. Called only by the username-login edge function (service role)
-- ------------------------------------------------------------------------------

-- The active lock for an account, if any. No row = password login is allowed.
create or replace function public.login_lock_state(p_user_id uuid)
returns table (permanent boolean, locked_until timestamptz)
language sql stable security definer set search_path = public as $$
  select l.permanent, l.locked_until
    from public.login_locks l
   where l.user_id = p_user_id
     and (l.permanent or l.locked_until > now());
$$;

-- Records an attempt and applies the escalation. Returns 'ok' | 'fail' | 'locked_24h' | 'locked_permanent'.
-- p_user_id is null for a username that does not exist: those attempts are throttled but never locked.
drop function if exists public.record_login_attempt(text, text, boolean);
create or replace function public.record_login_attempt(
  p_user_hash text, p_ip_hash text, p_ok boolean, p_user_id uuid default null)
returns text language plpgsql security definer set search_path = public as $$
declare
  c_fails_per_strike constant int := 5;
  c_lock_strikes     constant int := 3;   -- LOCK_STRIKES: strikes before password login is disabled
  v_lock     public.login_locks%rowtype;
  v_last_ok  timestamptz;
  v_fails    int;
  v_strikes  int;
begin
  insert into public.auth_attempts (user_hash, ip_hash, ok) values (p_user_hash, p_ip_hash, p_ok);

  if p_user_id is null then
    return case when p_ok then 'ok' else 'fail' end;
  end if;

  if p_ok then
    update public.login_locks
       set strikes = 0, locked_until = null, updated_at = now()
     where user_id = p_user_id and not permanent;
    return 'ok';
  end if;

  insert into public.login_locks (user_id) values (p_user_id) on conflict (user_id) do nothing;
  select * into v_lock from public.login_locks where user_id = p_user_id for update;
  if v_lock.permanent then return 'locked_permanent'; end if;

  select max(created_at) into v_last_ok from public.auth_attempts where user_hash = p_user_hash and ok;
  select count(*) into v_fails
    from public.auth_attempts
   where user_hash = p_user_hash and not ok
     and created_at > greatest(coalesce(v_last_ok, '-infinity'::timestamptz),
                               coalesce(v_lock.last_lock_at, '-infinity'::timestamptz));

  if v_fails < c_fails_per_strike then return 'fail'; end if;

  v_strikes := v_lock.strikes + 1;
  if v_strikes >= c_lock_strikes then
    update public.login_locks
       set strikes = v_strikes, locked_until = null, permanent = true, last_lock_at = now(), updated_at = now()
     where user_id = p_user_id;
    insert into public.security_events (user_id, kind, detail)
    values (p_user_id, 'login_lock_permanent', jsonb_build_object('strikes', v_strikes));
    return 'locked_permanent';
  end if;

  update public.login_locks
     set strikes = v_strikes, locked_until = now() + interval '24 hours', last_lock_at = now(), updated_at = now()
   where user_id = p_user_id;
  insert into public.security_events (user_id, kind, detail)
  values (p_user_id, 'login_lock_24h', jsonb_build_object('strikes', v_strikes));
  return 'locked_24h';
end $$;

do $$
declare f text;
begin
  foreach f in array array['login_lock_state(uuid)', 'record_login_attempt(text,text,boolean,uuid)'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to service_role', f);
  end loop;
end $$;

-- ------------------------------------------------------------------------------
-- 4. Super-admin recovery
-- ------------------------------------------------------------------------------

-- Locked accounts, for the super-admin screen.
create or replace function public.admin_list_locked_logins()
returns table (user_id uuid, username text, full_name text, strikes int,
               locked_until timestamptz, permanent boolean, last_lock_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_superadmin() then raise exception 'forbidden' using errcode = '42501'; end if;
  return query
    select l.user_id, p.username, p.full_name, l.strikes, l.locked_until, l.permanent, l.last_lock_at
      from public.login_locks l
      join public.profiles p on p.id = l.user_id
     where l.permanent or l.locked_until > now()
     order by l.last_lock_at desc nulls last
     limit 200;
end $$;
revoke all on function public.admin_list_locked_logins() from public, anon;
grant execute on function public.admin_list_locked_logins() to authenticated;

-- Clears the lock, flags "must change password", signs the person out everywhere, and writes the audit
-- trail. The temporary password itself is set by the admin-recover-login edge function AFTER this
-- succeeds; it is never stored or logged.
create or replace function public.admin_recover_login(p_uid uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare v_reason text := btrim(coalesce(p_reason, ''));
begin
  if not public.is_superadmin() then raise exception 'forbidden' using errcode = '42501'; end if;
  if coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' then
    raise exception 'aal2_required' using errcode = '42501';
  end if;
  if char_length(v_reason) < 10 or char_length(v_reason) > 300 then
    raise exception 'reason_required' using errcode = '22023';
  end if;
  if not exists (select 1 from public.profiles where id = p_uid) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;

  delete from public.login_locks where user_id = p_uid;

  perform set_config('myharur.profile_guard_bypass', 'on', true);
  update public.profiles set must_change_password = true where id = p_uid;
  perform set_config('myharur.profile_guard_bypass', 'off', true);

  delete from auth.sessions where user_id = p_uid;

  insert into public.security_events (user_id, kind, detail)
  values (p_uid, 'login_recovered', jsonb_build_object('by', auth.uid(), 'reason', v_reason));
  insert into public.crud_audit_logs (user_id, action, table_name, record_id, details)
  values (auth.uid(), 'login.recover', 'profiles', p_uid::text, jsonb_build_object('reason', v_reason));
end $$;
revoke all on function public.admin_recover_login(uuid, text) from public, anon;
grant execute on function public.admin_recover_login(uuid, text) to authenticated;

-- Housekeeping: old security events are kept a year.
create or replace function public.prune_security_tables()
returns void language sql security definer set search_path = public as $$
  delete from public.auth_attempts  where created_at < now() - interval '2 days';
  delete from public.rate_limits    where window_start < now() - interval '2 days';
  delete from public.client_errors  where created_at < now() - interval '90 days';
  delete from public.security_events where created_at < now() - interval '365 days';
$$;
revoke all on function public.prune_security_tables() from public, anon, authenticated;
