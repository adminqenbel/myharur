-- ==============================================================================
-- MyHarur — moderation pipeline + RLS hardening (applies on top of the v2 baseline)
--
-- Alert lifecycle:
--   1. Any signed-in user (resident OR staff) inserts an alert.
--   2. BEFORE INSERT trigger runs the automated filter and FORCES the safe values:
--        - profanity / blocked-dangerous terms  -> status 'rejected'  (auto)
--        - everything else                      -> status 'pending'   (human review)
--        - dangerous terms / links / phone numbers set flagged_by_system + moderation_flags
--   3. Any moderator / admin / superadmin approves or rejects via moderate_alert().
--   4. Only 'published' + unexpired alerts are readable by the public.
--
-- Safe to re-run. Run in: Supabase Dashboard -> SQL Editor (or `supabase db push`).
-- ==============================================================================

do $$
begin
  if to_regclass('public.alerts') is null or to_regclass('public.wards') is null
     or to_regclass('public.moderation_queue') is null then
    raise exception 'v2 baseline not found - apply 20260825000000_v2_baseline.sql first';
  end if;
end $$;

-- ------------------------------------------------------------------------------
-- 1. Roles: add "moderator"
-- ------------------------------------------------------------------------------
alter table public.user_roles drop constraint if exists user_roles_role_check;
alter table public.user_roles add constraint user_roles_role_check
  check (role in ('resident','moderator','govt_official','admin','superadmin'));

-- Staff = anyone allowed to review alerts. SECURITY DEFINER so RLS policies can call it
-- without recursing into user_roles' own policies.
create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles
    where uid = auth.uid() and revoked_at is null
      and role in ('moderator','admin','superadmin')
  );
$$;
revoke all on function public.is_staff() from public;
grant execute on function public.is_staff() to anon, authenticated;

-- Admins additionally may read user PII (moderators review content only).
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles
    where uid = auth.uid() and revoked_at is null and role in ('admin','superadmin')
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- ------------------------------------------------------------------------------
-- 2. Alert moderation columns + moderation rule tables
-- ------------------------------------------------------------------------------
alter table public.alerts
  add column if not exists moderation_flags   text[]      not null default '{}',
  add column if not exists flagged_by_system  boolean     not null default false,
  add column if not exists moderation_reason  text,
  add column if not exists reviewed_by        uuid,
  add column if not exists reviewed_at        timestamptz;

create index if not exists alerts_feed_idx  on public.alerts (status, emergency_tagged desc, created_at desc);
create index if not exists alerts_author_idx on public.alerts (created_by_uid, created_at desc);

-- Profanity list already exists (empty). Make terms unique so seeding is idempotent.
create unique index if not exists profanity_term_uq on public.profanity_wordlist (lower(term), script);

create table if not exists public.moderation_danger_terms (
  term      text primary key,               -- lowercase, matched on word boundaries
  severity  text not null check (severity in ('flag','block')),
  note      text,
  created_at timestamptz not null default now()
);
alter table public.moderation_danger_terms enable row level security;   -- no policies = service role only

-- STARTER lists only. Curate these (especially Tamil / Tanglish) from the SQL editor:
--   insert into profanity_wordlist(term, script) values ('...', 'tamil_tanglish');
insert into public.profanity_wordlist (term, script, variant_type) values
  ('fuck','english','exact'), ('fucking','english','exact'), ('shit','english','exact'),
  ('bitch','english','exact'), ('bastard','english','exact'), ('asshole','english','exact'),
  ('dick','english','exact'), ('slut','english','exact'), ('whore','english','exact'),
  ('cunt','english','exact')
on conflict do nothing;

insert into public.moderation_danger_terms (term, severity, note) values
  ('bomb','flag','violence'), ('explosive','flag','violence'), ('kill','flag','violence'),
  ('murder','flag','violence'), ('gun','flag','weapon'), ('weapon','flag','weapon'),
  ('riot','flag','public order'), ('terrorist','flag','violence'), ('kidnap','flag','violence'),
  ('hostage','flag','violence'), ('rape','flag','sexual violence'),
  ('suicide','flag','self harm'), ('acid attack','flag','violence')
on conflict (term) do nothing;

-- ------------------------------------------------------------------------------
-- 3. Automated filter: BEFORE INSERT on alerts
--    Runs for every API caller; clients cannot choose status/source/author.
-- ------------------------------------------------------------------------------
create or replace function public.alerts_before_insert()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_uid     uuid := auth.uid();
  v_role    text;
  v_active  boolean;
  v_strikes int;
  v_recent  int;
  v_limit   int;
  v_text    text;
  v_raw     text;
  v_flags   text[] := '{}';
  v_block   boolean := false;
begin
  -- No end-user JWT: SQL editor / service role (seeding, ingestion). Leave row as given.
  if v_uid is null then
    if coalesce(auth.role(), 'service_role') = 'service_role' then
      return new;
    end if;
    raise exception 'authentication_required' using errcode = '42501';
  end if;

  select is_active, emergency_strikes into v_active, v_strikes
  from public.profiles where id = v_uid;
  if v_active is null then raise exception 'profile_missing' using errcode = 'P0001'; end if;
  if not v_active     then raise exception 'account_disabled' using errcode = '42501'; end if;

  select role into v_role from public.user_roles
  where uid = v_uid and revoked_at is null
    and role in ('superadmin','admin','moderator','govt_official')
  order by array_position(array['superadmin','admin','moderator','govt_official']::text[], role)
  limit 1;

  -- Rate limit: 5 alerts/hour for residents, 30 for staff
  select count(*) into v_recent from public.alerts
  where created_by_uid = v_uid and created_at > now() - interval '1 hour';
  v_limit := case when v_role is null then 5 else 30 end;
  if v_recent >= v_limit then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  new.title := btrim(coalesce(new.title, ''));
  new.body  := btrim(coalesce(new.body, ''));
  if char_length(new.title) not between 5 and 100
     or char_length(new.body) not between 10 and 500 then
    raise exception 'invalid_length' using errcode = 'P0001';
  end if;

  -- Server-controlled fields (never trust the client)
  new.created_by_uid  := v_uid;
  new.source          := case when v_role is null then 'community' else 'official' end;
  new.published_as_role := case v_role
      when 'superadmin'    then 'Official · MyHarur Admin'
      when 'admin'         then 'Official · MyHarur Admin'
      when 'moderator'     then 'Official · MyHarur Moderator'
      when 'govt_official' then 'Official · Govt Dept'
      else null end;
  new.emergency_tagged := coalesce(new.emergency_tagged, false) and coalesce(v_strikes, 0) < 2;
  new.status          := 'pending';
  new.expires_at      := now() + interval '24 hours';   -- review window; reset on approval
  new.reviewed_by     := null;
  new.reviewed_at     := null;
  new.moderation_reason := null;

  -- Normalise for matching: lowercase, undo simple leetspeak, strip ASCII punctuation,
  -- collapse repeated letters ("fuuuck"), pad with spaces for whole-word matching.
  v_raw  := new.title || ' ' || new.body;
  v_text := translate(lower(v_raw), '013457@$', 'oieastas');
  v_text := regexp_replace(v_text, '[[:punct:]]+', ' ', 'g');
  v_text := regexp_replace(v_text, '(.)\1{2,}', '\1', 'g');
  v_text := ' ' || btrim(regexp_replace(v_text, '\s+', ' ', 'g')) || ' ';

  if exists (select 1 from public.profanity_wordlist p
             where strpos(v_text, ' ' || lower(p.term) || ' ') > 0) then
    v_block := true;  v_flags := array_append(v_flags, 'profanity');
  end if;
  if exists (select 1 from public.moderation_danger_terms d
             where d.severity = 'block' and strpos(v_text, ' ' || d.term || ' ') > 0) then
    v_block := true;  v_flags := array_append(v_flags, 'dangerous_blocked');
  end if;
  if exists (select 1 from public.moderation_danger_terms d
             where d.severity = 'flag' and strpos(v_text, ' ' || d.term || ' ') > 0) then
    v_flags := array_append(v_flags, 'dangerous_terms');
  end if;
  if lower(v_raw) ~ '(https?://|www\.|\.(com|net|org|xyz)\y)' then
    v_flags := array_append(v_flags, 'link');
  end if;
  if v_raw ~ '(\d[\s\-]?){10,}' then
    v_flags := array_append(v_flags, 'phone_number');
  end if;

  new.moderation_flags  := v_flags;
  new.flagged_by_system := coalesce(array_length(v_flags, 1), 0) > 0;
  if v_block then
    new.status := 'rejected';
    new.moderation_reason := 'auto_rejected';
    new.expires_at := null;
  end if;
  return new;
end $$;

drop trigger if exists alerts_before_insert on public.alerts;
create trigger alerts_before_insert before insert on public.alerts
  for each row execute function public.alerts_before_insert();

-- Pending alerts get a review-queue row
create or replace function public.alerts_after_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'pending' then
    insert into public.moderation_queue
      (alert_id, category, ward_id, emergency_tagged, flagged_by_system, expires_at)
    values
      (new.id, new.category, new.ward_id, new.emergency_tagged, new.flagged_by_system,
       coalesce(new.expires_at, now() + interval '24 hours'));
  end if;
  return new;
end $$;

drop trigger if exists alerts_after_insert on public.alerts;
create trigger alerts_after_insert after insert on public.alerts
  for each row execute function public.alerts_after_insert();

-- ------------------------------------------------------------------------------
-- 4. Human review: any moderator / admin / superadmin
-- ------------------------------------------------------------------------------
create or replace function public.moderate_alert(
  p_alert_id uuid,
  p_decision text,                 -- 'approve' | 'reject'
  p_reason   text default null,    -- required for reject
  p_hours    int  default 168      -- how long an approved alert stays live (1..720)
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_alert public.alerts%rowtype;
begin
  if not public.is_staff() then raise exception 'forbidden' using errcode = '42501'; end if;
  if p_decision not in ('approve','reject') then raise exception 'invalid_decision'; end if;

  select * into v_alert from public.alerts where id = p_alert_id for update;
  if not found then raise exception 'not_found'; end if;
  if v_alert.status <> 'pending' then raise exception 'already_reviewed'; end if;

  if p_decision = 'approve' then
    update public.alerts
       set status = 'published', reviewed_by = auth.uid(), reviewed_at = now(),
           expires_at = now() + make_interval(hours => greatest(1, least(coalesce(p_hours,168), 720)))
     where id = p_alert_id;
    update public.moderation_queue
       set status = 'approved', decision_by = auth.uid(), decision_at = now()
     where alert_id = p_alert_id and status = 'pending';
  else
    if p_reason is null or p_reason not in ('spam','false','duplicate','low_quality','inappropriate') then
      raise exception 'reason_required';
    end if;
    update public.alerts
       set status = 'rejected', reviewed_by = auth.uid(), reviewed_at = now(),
           moderation_reason = p_reason
     where id = p_alert_id;
    update public.moderation_queue
       set status = 'rejected', decision_by = auth.uid(), decision_at = now(), reason = p_reason
     where alert_id = p_alert_id and status = 'pending';

    -- False / spam EMERGENCY reports cost the author a strike (2 strikes = no emergency tag)
    if v_alert.emergency_tagged and p_reason in ('false','spam') and v_alert.created_by_uid is not null then
      perform set_config('myharur.profile_guard_bypass', 'on', true);
      update public.profiles set emergency_strikes = emergency_strikes + 1
       where id = v_alert.created_by_uid;
      perform set_config('myharur.profile_guard_bypass', 'off', true);
    end if;
  end if;

  insert into public.crud_audit_logs (user_id, action, table_name, record_id, details)
  values (auth.uid(), 'alert.' || p_decision, 'alerts', p_alert_id::text,
          jsonb_build_object('reason', p_reason, 'flags', v_alert.moderation_flags));
end $$;
revoke all on function public.moderate_alert(uuid, text, text, int) from public;
grant execute on function public.moderate_alert(uuid, text, text, int) to authenticated;

-- Expiry sweep (unreviewed after 24h -> expired; published past expires_at -> expired)
create or replace function public.expire_moderation_items()
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.alerts set status = 'expired'
   where status in ('pending','published') and expires_at is not null and expires_at < now();
  update public.moderation_queue q set status = 'expired'
   where q.status = 'pending'
     and (q.expires_at < now()
          or exists (select 1 from public.alerts a where a.id = q.alert_id and a.status = 'expired'));
end $$;
revoke all on function public.expire_moderation_items() from public, anon, authenticated;

do $$
begin
  create extension if not exists pg_cron;
  perform cron.schedule('myharur-expire-alerts', '*/15 * * * *', 'select public.expire_moderation_items()');
exception when others then
  raise notice 'pg_cron unavailable (%). Enable it under Database > Extensions, then schedule public.expire_moderation_items() every 15 min.', sqlerrm;
end $$;

-- ------------------------------------------------------------------------------
-- 5. RLS: alerts
-- ------------------------------------------------------------------------------
drop policy if exists "Public read published alerts" on public.alerts;
drop policy if exists "Authenticated insert alerts"  on public.alerts;
drop policy if exists alerts_public_read on public.alerts;
drop policy if exists alerts_own_read    on public.alerts;
drop policy if exists alerts_staff_read  on public.alerts;
drop policy if exists alerts_insert      on public.alerts;

create policy alerts_public_read on public.alerts for select
  using (status = 'published' and (expires_at is null or expires_at > now()));
create policy alerts_own_read on public.alerts for select
  using (created_by_uid = auth.uid());
create policy alerts_staff_read on public.alerts for select
  using (public.is_staff());
-- Trigger overwrites created_by_uid with auth.uid() before this check runs.
create policy alerts_insert on public.alerts for insert to authenticated
  with check (created_by_uid = auth.uid());
-- No UPDATE / DELETE policy for clients: reviews go through moderate_alert().

-- ------------------------------------------------------------------------------
-- 6. RLS: profiles (PII) + role table
-- ------------------------------------------------------------------------------
drop policy if exists "Public read profiles"       on public.profiles;
drop policy if exists "Users update own profile"   on public.profiles;
drop policy if exists profiles_read_own   on public.profiles;
drop policy if exists profiles_read_staff on public.profiles;
drop policy if exists profiles_read_admin on public.profiles;
drop policy if exists profiles_update_own on public.profiles;

create policy profiles_read_own   on public.profiles for select using (id = auth.uid());
create policy profiles_read_admin on public.profiles for select using (public.is_admin());
create policy profiles_update_own on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

-- Users may edit their own profile but not the trust/identity columns.
create or replace function public.profiles_protect_columns()
returns trigger language plpgsql as $$
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
  new.ward_verified     := old.ward_verified;
  new.emergency_strikes := old.emergency_strikes;
  new.is_active         := old.is_active;
  new.created_at        := old.created_at;
  return new;
end $$;

drop trigger if exists profiles_protect_columns on public.profiles;
create trigger profiles_protect_columns before update on public.profiles
  for each row execute function public.profiles_protect_columns();

drop policy if exists "Public read user_roles" on public.user_roles;
drop policy if exists user_roles_read_own on public.user_roles;
create policy user_roles_read_own on public.user_roles for select
  using (uid = auth.uid() or public.is_staff());

-- ------------------------------------------------------------------------------
-- 7. Close open write policies on tables the app doesn't use yet
--    (feature flags are client-side only; RLS must be the real gate)
-- ------------------------------------------------------------------------------
drop policy if exists "Authenticated insert jobs"   on public.jobs;
drop policy if exists "Authenticated insert events" on public.events;
drop policy if exists "Authenticated insert chat"   on public.chat_messages;
drop policy if exists "Public read chat"            on public.chat_messages;
drop policy if exists "Authenticated insert audit"  on public.crud_audit_logs;

-- ------------------------------------------------------------------------------
-- 8. Signup trigger: survive MMID collisions (previous version could fail signup)
-- ------------------------------------------------------------------------------
create or replace function public.handle_new_myharur_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  new_mmid text;
begin
  for i in 1..8 loop
    new_mmid := to_char(now() at time zone 'UTC', 'YYYYMMDDHH24MISS')
                || lpad((floor(random() * 9000) + 1000)::int::text, 4, '0');
    begin
      insert into public.profiles (id, mmid, full_name, email, onboarding_state)
      values (new.id, new_mmid,
              coalesce(new.raw_user_meta_data->>'full_name', 'Harur Resident'),
              new.email, 'PENDING_USERNAME')
      on conflict (id) do nothing;
      exit;
    exception when unique_violation then
      if i = 8 then raise; end if;
    end;
  end loop;

  insert into public.user_roles (uid, role, scope, granted_at)
  values (new.id, 'resident', 'global', now())
  on conflict (uid, role, scope) do nothing;
  return new;
end $$;

-- ------------------------------------------------------------------------------
-- 9. Account deletion (required by Google Play for apps with sign-up)
--    Public alerts stay, un-linked from the author; profile + roles + login are removed.
-- ------------------------------------------------------------------------------
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'authentication_required' using errcode = '42501'; end if;
  update public.alerts set created_by_uid = null where created_by_uid = v_uid;
  delete from public.user_roles where uid = v_uid;
  delete from auth.users where id = v_uid;          -- cascades to public.profiles
end $$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- ------------------------------------------------------------------------------
-- 10. Bootstrapping staff (run manually, once per person; replace the UUID):
--   insert into public.user_roles (uid, role, scope) values ('<auth.users.id>', 'moderator', 'global');
--   insert into public.user_roles (uid, role, scope) values ('<auth.users.id>', 'admin',     'global');
-- ------------------------------------------------------------------------------
