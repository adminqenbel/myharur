-- ==============================================================================
-- Phase 3: events, jobs, ads.
--
-- Events and jobs reuse the whole report/news pipeline instead of new tables: the same automated
-- filter, moderation queue, Review tab, photos, soft delete, report/block and rate limits already
-- built for alerts.kind in ('report','news') now also serve 'event' and 'job'. This is a deliberate
-- deviation from the original plan's separate `events`/`jobs` tables, which existed from the very
-- first baseline migration but were never used (0 rows, no write policy) — dropped below.
--
-- Ads are a separate, admin-only table: they are not user content, do not go through moderation, and
-- carry no personal data (aggregate impression/click counters only). Every admin write goes through a
-- SECURITY DEFINER RPC rather than a direct table grant, after the earlier column-grant/schema-cache
-- surprise on client_errors — RPCs are simpler to reason about and cannot go stale the same way.
--
-- Both stay behind their existing module_flags rows ('events', 'jobs'; both false) until turned on
-- from the app's own admin panel (added here) — the sibling QenBel Administration project is inactive.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Drop the dormant baseline tables (0 rows in production, no policy allows writing to them, no
--    foreign keys reference them).
-- ------------------------------------------------------------------------------
drop table if exists public.jobs;
drop table if exists public.events;

-- ------------------------------------------------------------------------------
-- 2. alerts: two more kinds, and the columns only events/jobs need
-- ------------------------------------------------------------------------------
alter table public.alerts
  add column if not exists starts_at    timestamptz,   -- events: when it starts
  add column if not exists ends_at      timestamptz,   -- events: optional end; jobs: closing date/time
  add column if not exists all_day      boolean     not null default false,   -- events
  add column if not exists is_paid      boolean     not null default false,   -- events: ticketed vs free
  add column if not exists employer     text,                                  -- jobs
  add column if not exists pay_text     text,                                  -- jobs, free text, optional
  add column if not exists contact_text text;                                  -- jobs: phone/e-mail to apply

alter table public.alerts drop constraint if exists alerts_kind_check;
alter table public.alerts add constraint alerts_kind_check check (kind in ('report', 'news', 'event', 'job'));

alter table public.alerts drop constraint if exists alerts_category_check;
alter table public.alerts add constraint alerts_category_check check (
  (kind = 'report' and category in ('road', 'electricity', 'water', 'govt'))
  or (kind = 'news' and category in ('traffic', 'civic', 'health', 'education', 'community', 'other'))
  or (kind = 'event' and category in ('cultural', 'sports', 'education', 'religious', 'government', 'business', 'other'))
  or (kind = 'job' and category in ('full_time', 'part_time', 'contract', 'internship', 'daily_wage', 'other')));

alter table public.alerts drop constraint if exists alerts_employer_len;
alter table public.alerts add constraint alerts_employer_len check (
  char_length(coalesce(employer, '')) <= 100
  and char_length(coalesce(pay_text, '')) <= 100
  and char_length(coalesce(contact_text, '')) <= 200);

-- An event/job cannot be dated in the past when it is *submitted*, and an end must follow its start.
alter table public.alerts drop constraint if exists alerts_dates_check;
alter table public.alerts add constraint alerts_dates_check check (
  ends_at is null or starts_at is null or ends_at > starts_at);

create index if not exists alerts_ends_at_idx on public.alerts (ends_at) where kind in ('event', 'job');

-- ------------------------------------------------------------------------------
-- 3. Submission trigger: event/job specific required fields and rate limits
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
  v_path    text;
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
  if exists (select 1 from public.user_restrictions where user_id = v_uid) then
    raise exception 'account_restricted' using errcode = '42501';
  end if;

  select role into v_role from public.user_roles
  where uid = v_uid and revoked_at is null
    and role in ('superadmin','admin','moderator','govt_official')
  order by array_position(array['superadmin','admin','moderator','govt_official']::text[], role)
  limit 1;

  -- Rate limit per kind: residents 5 reports/h, 3 news/h, 2 events/h, 2 jobs/h; staff 30/h for anything
  select count(*) into v_recent from public.alerts
  where created_by_uid = v_uid and kind = coalesce(new.kind, 'report') and created_at > now() - interval '1 hour';
  v_limit := case
    when v_role is not null then 30
    when coalesce(new.kind, 'report') = 'news' then 3
    when coalesce(new.kind, 'report') in ('event', 'job') then 2
    else 5 end;
  if v_recent >= v_limit then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  -- Cooldown: 3 auto-rejected posts within 24 h pause posting for the rest of that window
  if v_role is null and (select count(*) from public.alerts
                          where created_by_uid = v_uid and moderation_reason = 'auto_rejected'
                            and created_at > now() - interval '24 hours') >= 3 then
    raise exception 'cooldown' using errcode = 'P0001';
  end if;

  new.kind  := coalesce(new.kind, 'report');
  new.title := btrim(coalesce(new.title, ''));
  new.body  := btrim(coalesce(new.body, ''));
  if char_length(new.title) not between 5 and 100
     or char_length(new.body) not between 10 and 500 then
    raise exception 'invalid_length' using errcode = 'P0001';
  end if;

  -- Images must be objects this user uploaded: {uid}/{uuid}.{jpg|png|webp}
  foreach v_path in array coalesce(new.image_paths, '{}') loop
    if v_path !~ ('^' || v_uid::text || '/[0-9a-f-]{36}\.(jpg|png|webp)$') then
      raise exception 'invalid_image' using errcode = 'P0001';
    end if;
  end loop;
  if (select count(distinct p) from unnest(coalesce(new.image_paths, '{}')) p) <> cardinality(coalesce(new.image_paths, '{}')) then
    raise exception 'invalid_image' using errcode = 'P0001';
  end if;

  if new.kind = 'event' then
    if new.starts_at is null or new.starts_at < now() - interval '1 hour' then
      raise exception 'starts_at_required' using errcode = 'P0001';
    end if;
    new.employer := null; new.pay_text := null; new.contact_text := null;
    -- A venue is required: a typed place, a pinned point, or both (never neither).
    if btrim(coalesce(new.location_text, '')) = '' and new.location_lat is null then
      raise exception 'venue_required' using errcode = 'P0001';
    end if;
  elsif new.kind = 'job' then
    new.employer     := btrim(coalesce(new.employer, ''));
    new.contact_text := btrim(coalesce(new.contact_text, ''));
    new.pay_text      := nullif(btrim(coalesce(new.pay_text, '')), '');
    if new.employer = '' or new.contact_text = '' then
      raise exception 'employer_and_contact_required' using errcode = 'P0001';
    end if;
    if new.ends_at is null or new.ends_at < now() then
      raise exception 'closing_date_required' using errcode = 'P0001';
    end if;
    new.starts_at := null; new.all_day := false; new.is_paid := false;
  else
    new.starts_at := null; new.ends_at := null; new.all_day := false; new.is_paid := false;
    new.employer := null; new.pay_text := null; new.contact_text := null;
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
  new.emergency_tagged := new.kind = 'report' and coalesce(new.emergency_tagged, false) and coalesce(v_strikes, 0) < 2;
  new.status          := 'pending';
  new.expires_at      := now() + interval '24 hours';   -- review window; reset on approval
  new.reviewed_by     := null;
  new.reviewed_at     := null;
  new.moderation_reason := null;
  new.deleted_at      := null;
  new.deleted_by      := null;
  new.image_paths     := coalesce(new.image_paths, '{}');
  if new.kind not in ('news', 'event', 'job') then new.link_url := null; end if;

  -- Normalise for matching: lowercase, undo simple leetspeak, strip ASCII punctuation,
  -- collapse repeated letters ("fuuuck"), pad with spaces for whole-word matching.
  v_raw  := new.title || ' ' || new.body || ' ' || coalesce(new.employer, '') || ' ' || coalesce(new.contact_text, '');
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
  if new.link_url is not null or lower(v_raw) ~ '(https?://|www\.|\.(com|net|org|xyz)\y)' then
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
revoke execute on function public.alerts_before_insert() from public, anon, authenticated;

-- ------------------------------------------------------------------------------
-- 4. Approval: an event/job's expiry follows its own end date, not the flat 7-day default
-- ------------------------------------------------------------------------------
create or replace function public.moderate_alert(
  p_alert_id uuid,
  p_decision text,
  p_reason   text default null,
  p_hours    int  default 168
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_alert   public.alerts%rowtype;
  v_expires timestamptz;
begin
  if not public.is_staff() then raise exception 'forbidden' using errcode = '42501'; end if;
  if p_decision not in ('approve','reject') then raise exception 'invalid_decision'; end if;

  select * into v_alert from public.alerts where id = p_alert_id for update;
  if not found then raise exception 'not_found'; end if;
  if v_alert.status <> 'pending' then raise exception 'already_reviewed'; end if;

  if p_decision = 'approve' then
    v_expires := case
      when v_alert.kind in ('event', 'job') and v_alert.ends_at is not null then v_alert.ends_at
      else now() + make_interval(hours => greatest(1, least(coalesce(p_hours,168), 720))) end;
    update public.alerts
       set status = 'published', reviewed_by = auth.uid(), reviewed_at = now(), expires_at = v_expires
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

-- ------------------------------------------------------------------------------
-- 5. Module flags: let a super admin turn 'events'/'jobs' on from this app (the sibling QenBel
--    Administration project is inactive; nothing else can flip them today).
-- ------------------------------------------------------------------------------
create or replace function public.admin_set_module_flag(p_module text, p_enabled boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' then
    raise exception 'aal2_required' using errcode = '42501';
  end if;
  if not public.is_superadmin() then raise exception 'forbidden' using errcode = '42501'; end if;
  update public.module_flags set enabled = p_enabled, updated_by = auth.uid(), updated_at = now()
   where module = p_module;
  if not found then raise exception 'unknown_module' using errcode = 'P0002'; end if;
  insert into public.crud_audit_logs (user_id, action, table_name, record_id, details)
  values (auth.uid(), 'module_flag.set', 'module_flags', p_module, jsonb_build_object('enabled', p_enabled));
end $$;
revoke all on function public.admin_set_module_flag(text, boolean) from public, anon;
grant execute on function public.admin_set_module_flag(text, boolean) to authenticated;

-- ------------------------------------------------------------------------------
-- 6. Ads. Admin-owned, not user content, no moderation queue, no personal data.
-- ------------------------------------------------------------------------------
create table if not exists public.ads (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(title) between 3 and 100),
  body        text not null check (char_length(body) between 3 and 300),
  image_path  text,
  link_url    text not null check (link_url ~ '^https://[A-Za-z0-9.-]+(/[^[:space:]]*)?$' and char_length(link_url) <= 500),
  placement   text not null check (placement in ('home', 'news', 'reports')),
  priority    int  not null default 0,
  starts_at   timestamptz not null default now(),
  ends_at     timestamptz,
  status      text not null default 'draft' check (status in ('draft', 'active', 'paused')),
  impressions bigint not null default 0,
  clicks      bigint not null default 0,
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  check (ends_at is null or ends_at > starts_at)
);
create index if not exists ads_active_idx on public.ads (placement, priority desc) where status = 'active';
alter table public.ads enable row level security;
revoke all on public.ads from anon, authenticated;

-- Anyone (including anon) may see a currently-active ad for its placement — this is what actually
-- renders in the feed; nothing here is personal, so the wider anon grant is deliberate.
grant select on public.ads to anon, authenticated;
drop policy if exists ads_public_read on public.ads;
create policy ads_public_read on public.ads for select
  using (status = 'active' and starts_at <= now() and (ends_at is null or ends_at > now()));

create or replace function public.admin_list_ads()
returns setof public.ads language sql stable security definer set search_path = public as $$
  select * from public.ads where public.is_superadmin() order by created_at desc;
$$;
revoke all on function public.admin_list_ads() from public, anon;
grant execute on function public.admin_list_ads() to authenticated;

create or replace function public.admin_create_ad(
  p_title text, p_body text, p_image_path text, p_link text, p_placement text,
  p_priority int, p_starts_at timestamptz, p_ends_at timestamptz)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' then
    raise exception 'aal2_required' using errcode = '42501';
  end if;
  if not public.is_superadmin() then raise exception 'forbidden' using errcode = '42501'; end if;
  insert into public.ads (title, body, image_path, link_url, placement, priority, starts_at, ends_at, created_by)
  values (btrim(p_title), btrim(p_body), nullif(btrim(coalesce(p_image_path, '')), ''), btrim(p_link),
          p_placement, coalesce(p_priority, 0), coalesce(p_starts_at, now()), p_ends_at, auth.uid())
  returning id into v_id;
  insert into public.crud_audit_logs (user_id, action, table_name, record_id, details)
  values (auth.uid(), 'ad.create', 'ads', v_id::text, jsonb_build_object('placement', p_placement));
  return v_id;
end $$;
revoke all on function public.admin_create_ad(text, text, text, text, text, int, timestamptz, timestamptz) from public, anon;
grant execute on function public.admin_create_ad(text, text, text, text, text, int, timestamptz, timestamptz) to authenticated;

create or replace function public.admin_set_ad_status(p_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' then
    raise exception 'aal2_required' using errcode = '42501';
  end if;
  if not public.is_superadmin() then raise exception 'forbidden' using errcode = '42501'; end if;
  if p_status not in ('draft','active','paused') then raise exception 'invalid_status' using errcode = '22023'; end if;
  update public.ads set status = p_status, updated_at = now() where id = p_id;
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  insert into public.crud_audit_logs (user_id, action, table_name, record_id, details)
  values (auth.uid(), 'ad.status', 'ads', p_id::text, jsonb_build_object('status', p_status));
end $$;
revoke all on function public.admin_set_ad_status(uuid, text) from public, anon;
grant execute on function public.admin_set_ad_status(uuid, text) to authenticated;

create or replace function public.admin_delete_ad(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' then
    raise exception 'aal2_required' using errcode = '42501';
  end if;
  if not public.is_superadmin() then raise exception 'forbidden' using errcode = '42501'; end if;
  delete from public.ads where id = p_id;
  insert into public.crud_audit_logs (user_id, action, table_name, record_id, details)
  values (auth.uid(), 'ad.delete', 'ads', p_id::text, '{}');
end $$;
revoke all on function public.admin_delete_ad(uuid) from public, anon;
grant execute on function public.admin_delete_ad(uuid) to authenticated;

-- Impression/click counters: signed-in users only (the whole app requires sign-in already), aggregate
-- only, generously rate limited so a runaway client loop cannot spin the counters or the database.
create or replace function public.record_ad_event(p_id uuid, p_kind text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  if p_kind not in ('impression', 'click') then raise exception 'invalid_kind' using errcode = '22023'; end if;
  perform public.enforce_rate_limit('ad_event', 300, interval '1 day');
  -- same window as ads_public_read: an ad past its own end date does not earn credit just because
  -- nobody got around to pausing it
  if p_kind = 'impression' then
    update public.ads set impressions = impressions + 1
     where id = p_id and status = 'active' and starts_at <= now() and (ends_at is null or ends_at > now());
  else
    update public.ads set clicks = clicks + 1
     where id = p_id and status = 'active' and starts_at <= now() and (ends_at is null or ends_at > now());
  end if;
end $$;
revoke all on function public.record_ad_event(uuid, text) from public, anon;
grant execute on function public.record_ad_event(uuid, text) to authenticated;

-- ------------------------------------------------------------------------------
-- 7. Storage: a small PUBLIC bucket for ad creatives (not user content, nothing private about them;
--    a public bucket avoids a signed-URL round trip for something that renders in every feed).
-- ------------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('ad-images', 'ad-images', true, 1048576, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = true, file_size_limit = 1048576, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists ad_images_admin_write on storage.objects;
create policy ad_images_admin_write on storage.objects for all to authenticated
  using (bucket_id = 'ad-images' and public.is_superadmin())
  with check (bucket_id = 'ad-images' and public.is_superadmin());
-- Public bucket: anyone (including anon) can read the files directly by URL; no select policy needed
-- for that (Storage serves public-bucket objects unauthenticated), but Postgres GRANT still applies to
-- the objects table for API listing — deliberately left ungranted since no screen lists this bucket.
