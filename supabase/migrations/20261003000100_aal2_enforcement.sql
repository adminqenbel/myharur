-- ==============================================================================
-- Two-factor enforcement in the database.
--
-- Admins and super admins only count as admins while their session is aal2 (password/Google + authenticator
-- code). A stolen Google session or password alone therefore cannot use any admin function, read any
-- admin-only table, or approve alerts as an admin. Moderators may use two-factor but are not forced to.
--
-- Because the gate lives in is_admin() / is_superadmin() / is_staff(), it covers every admin_* function,
-- moderate_alert() and every RLS policy that calls them, with no per-function changes.
-- ==============================================================================

-- True when the caller's JWT was issued after a second factor. service_role and anon have no aal claim.
create or replace function public.has_aal2()
returns boolean language sql stable set search_path = public as $$
  select coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2';
$$;
revoke all on function public.has_aal2() from public;
grant execute on function public.has_aal2() to anon, authenticated;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles
    where uid = auth.uid() and revoked_at is null
      and (role = 'moderator'
           or (role in ('admin', 'superadmin') and public.has_aal2()))
  );
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select public.has_aal2() and exists (
    select 1 from public.user_roles
    where uid = auth.uid() and revoked_at is null and role in ('admin', 'superadmin')
  );
$$;

create or replace function public.is_superadmin()
returns boolean language sql stable security definer set search_path = public as $$
  select public.has_aal2() and exists (
    select 1 from public.user_roles
    where uid = auth.uid() and revoked_at is null and role = 'superadmin'
  );
$$;

-- Keep the two functions that report "aal2_required" separately (so the app can say "enter your code")
-- reporting it first, before the role check that would now answer "forbidden" for an aal1 session.
create or replace function public.admin_recover_login(p_uid uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare v_reason text := btrim(coalesce(p_reason, ''));
begin
  if coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' then
    raise exception 'aal2_required' using errcode = '42501';
  end if;
  if not public.is_superadmin() then raise exception 'forbidden' using errcode = '42501'; end if;
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

create or replace function public.admin_set_app_config(
  p_latest int, p_min int, p_url text, p_message_en text, p_message_ta text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' then
    raise exception 'aal2_required' using errcode = '42501';
  end if;
  if not public.is_superadmin() then raise exception 'forbidden' using errcode = '42501'; end if;
  if p_min > p_latest or p_min < 0 then raise exception 'invalid_versions' using errcode = '22023'; end if;
  update public.app_config
     set latest_build = p_latest, min_supported_build = p_min,
         update_url = nullif(btrim(p_url), ''),
         message_en = nullif(btrim(p_message_en), ''), message_ta = nullif(btrim(p_message_ta), ''),
         updated_at = now(), updated_by = auth.uid()
   where id = 1;
  insert into public.crud_audit_logs (user_id, action, table_name, record_id, details)
  values (auth.uid(), 'app_config.update', 'app_config', '1',
          jsonb_build_object('latest', p_latest, 'min', p_min));
end $$;
