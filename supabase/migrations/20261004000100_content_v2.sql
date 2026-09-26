-- ==============================================================================
-- Phase 2, part 1: community news, deletion, abuse controls, bug reports.
--
--  * alerts gets a `kind` ('report' | 'news'), an optional https link, up to 3 image paths and soft delete.
--    News reuses the whole report pipeline (word filter, rate limit, moderation queue, expiry, Review tab).
--  * Authors delete their own posts; staff delete any post with a written reason (audit log).
--  * report_content(): reporters flag a post; 3 distinct reporters (accounts older than a day) within 7 days
--    auto-restrict the author until an admin decides. Staff accounts are never auto-restricted.
--  * block_author(): a resident hides another author's posts from their own feed.
--  * report_bug(): anyone can file a bug; only super admins can read them (client_errors, kind 'bug').
-- Author identity is never exposed to other residents: reports and blocks go through the post, not the person.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. alerts: kind, link, images, soft delete
-- ------------------------------------------------------------------------------
alter table public.alerts
  add column if not exists kind        text        not null default 'report',
  add column if not exists link_url    text,
  add column if not exists image_paths text[]      not null default '{}',
  add column if not exists deleted_at  timestamptz,
  add column if not exists deleted_by  uuid        references auth.users(id) on delete set null;

alter table public.alerts drop constraint if exists alerts_kind_check;
alter table public.alerts add constraint alerts_kind_check check (kind in ('report', 'news'));

alter table public.alerts drop constraint if exists alerts_category_check;
alter table public.alerts add constraint alerts_category_check check (
  (kind = 'report' and category in ('road', 'electricity', 'water', 'govt'))
  or (kind = 'news' and category in ('traffic', 'civic', 'health', 'education', 'community', 'other')));

alter table public.alerts drop constraint if exists alerts_link_check;
alter table public.alerts add constraint alerts_link_check check (
  link_url is null or (link_url ~ '^https://[A-Za-z0-9.-]+(/[^[:space:]]*)?$' and char_length(link_url) <= 500));

alter table public.alerts drop constraint if exists alerts_images_check;
alter table public.alerts add constraint alerts_images_check check (cardinality(image_paths) <= 3);

create index if not exists alerts_kind_status_idx on public.alerts (kind, status, created_at desc);

-- ------------------------------------------------------------------------------
-- 2. Restrictions, blocks, reports
-- ------------------------------------------------------------------------------
alter table public.security_events drop constraint if exists security_events_kind_check;
alter table public.security_events add constraint security_events_kind_check check (kind in (
  'login_lock_24h', 'login_lock_permanent', 'login_recovered',
  'user_auto_restricted', 'user_restricted', 'user_banned', 'user_reinstated'));

create table if not exists public.user_restrictions (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  status     text not null check (status in ('restricted', 'banned')),
  reason     text,
  created_at timestamptz not null default now(),
  decided_by uuid references auth.users(id) on delete set null,
  decided_at timestamptz
);
alter table public.user_restrictions enable row level security;
revoke all on public.user_restrictions from anon, authenticated;
grant select on public.user_restrictions to authenticated;
drop policy if exists user_restrictions_own_read on public.user_restrictions;
create policy user_restrictions_own_read on public.user_restrictions for select using (user_id = auth.uid());

create table if not exists public.user_blocks (
  blocker    uuid not null references auth.users(id) on delete cascade,
  blocked    uuid not null references auth.users(id) on delete cascade,
  label      text not null default '',
  created_at timestamptz not null default now(),
  primary key (blocker, blocked),
  check (blocker <> blocked)
);
alter table public.user_blocks enable row level security;
revoke all on public.user_blocks from anon, authenticated;
grant select on public.user_blocks to authenticated;
drop policy if exists user_blocks_own_read on public.user_blocks;
create policy user_blocks_own_read on public.user_blocks for select using (blocker = auth.uid());

create table if not exists public.user_reports (
  id          uuid primary key default gen_random_uuid(),
  reporter    uuid not null references auth.users(id) on delete cascade,
  target_user uuid not null references auth.users(id) on delete cascade,
  alert_id    uuid references public.alerts(id) on delete set null,
  reason      text not null check (reason in ('spam', 'abuse', 'false', 'harassment', 'inappropriate', 'other')),
  note        text check (char_length(note) <= 200),
  status      text not null default 'new' check (status in ('new', 'reviewed')),
  created_at  timestamptz not null default now(),
  check (reporter <> target_user)
);
-- one report per reporter, post and day
create unique index if not exists user_reports_once_per_day on public.user_reports
  (reporter, target_user, coalesce(alert_id, '00000000-0000-0000-0000-000000000000'::uuid), ((created_at at time zone 'utc')::date));
create index if not exists user_reports_target_idx on public.user_reports (target_user, created_at desc);
alter table public.user_reports enable row level security;
revoke all on public.user_reports from anon, authenticated;

-- ------------------------------------------------------------------------------
-- 3. Visibility: deleted posts vanish, blocked authors are hidden from the blocker
-- ------------------------------------------------------------------------------
-- Security definer so the feed policy works for anon too (anon has no access to user_blocks itself).
create or replace function public.author_blocked(p_author uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_blocks where blocker = auth.uid() and blocked = p_author);
$$;
revoke all on function public.author_blocked(uuid) from public;
grant execute on function public.author_blocked(uuid) to anon, authenticated;

drop policy if exists alerts_public_read on public.alerts;
create policy alerts_public_read on public.alerts for select
  using (status = 'published' and deleted_at is null
         and (expires_at is null or expires_at > now())
         and not public.author_blocked(created_by_uid));
drop policy if exists alerts_own_read on public.alerts;
create policy alerts_own_read on public.alerts for select
  using (created_by_uid = auth.uid() and deleted_at is null);

-- ------------------------------------------------------------------------------
-- 4. Submission trigger (extends the earlier one: kind, link, images, restrictions, cooldown)
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

  -- Rate limit per kind: residents 5 reports/h or 3 news/h, staff 30/h
  select count(*) into v_recent from public.alerts
  where created_by_uid = v_uid and kind = coalesce(new.kind, 'report') and created_at > now() - interval '1 hour';
  v_limit := case when v_role is not null then 30 when coalesce(new.kind, 'report') = 'news' then 3 else 5 end;
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
  if new.kind = 'report' then new.link_url := null; end if;

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
-- 5. Delete a post: the author, or staff with a written reason
-- ------------------------------------------------------------------------------
create or replace function public.delete_content(p_id uuid, p_reason text default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := auth.uid();
  v_alert public.alerts%rowtype;
  v_own   boolean;
  v_reason text := btrim(coalesce(p_reason, ''));
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  select * into v_alert from public.alerts where id = p_id for update;
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_alert.deleted_at is not null then return; end if;   -- already gone

  v_own := v_alert.created_by_uid = v_uid;
  if not v_own then
    if not public.is_staff() then raise exception 'forbidden' using errcode = '42501'; end if;
    if char_length(v_reason) < 5 or char_length(v_reason) > 200 then
      raise exception 'reason_required' using errcode = '22023';
    end if;
  end if;

  update public.alerts set deleted_at = now(), deleted_by = v_uid, status = 'expired' where id = p_id;
  update public.moderation_queue set status = 'expired' where alert_id = p_id and status = 'pending';

  insert into public.crud_audit_logs (user_id, action, table_name, record_id, details)
  values (v_uid, 'content.delete', 'alerts', p_id::text,
          jsonb_build_object('own', v_own, 'kind', v_alert.kind, 'reason', nullif(v_reason, '')));
end $$;
revoke all on function public.delete_content(uuid, text) from public, anon;
grant execute on function public.delete_content(uuid, text) to authenticated;

-- ------------------------------------------------------------------------------
-- 6. Reporting and blocking (through the post: the author's identity is never revealed)
-- ------------------------------------------------------------------------------
create or replace function public._maybe_restrict(p_target uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_reporters int;
begin
  -- staff are never auto-restricted (that would be a way to silence moderators)
  if exists (select 1 from public.user_roles where uid = p_target and revoked_at is null
                and role in ('moderator', 'admin', 'superadmin', 'govt_official')) then
    return;
  end if;
  if exists (select 1 from public.user_restrictions where user_id = p_target) then return; end if;

  select count(distinct r.reporter) into v_reporters
    from public.user_reports r
    join public.profiles p on p.id = r.reporter
   where r.target_user = p_target and r.status = 'new'
     and r.created_at > now() - interval '7 days'
     and p.created_at < now() - interval '1 day';      -- brand-new accounts do not count

  if v_reporters >= 3 then
    insert into public.user_restrictions (user_id, status, reason)
    values (p_target, 'restricted', 'auto: 3 reporters in 7 days');
    insert into public.security_events (user_id, kind, detail)
    values (p_target, 'user_auto_restricted', jsonb_build_object('reporters', v_reporters));
  end if;
end $$;
revoke all on function public._maybe_restrict(uuid) from public, anon, authenticated;

create or replace function public.report_content(p_alert_id uuid, p_reason text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare v_target uuid;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  if p_reason not in ('spam', 'abuse', 'false', 'harassment', 'inappropriate', 'other') then
    raise exception 'invalid_reason' using errcode = '22023';
  end if;
  perform public.enforce_rate_limit('report_content', 5, interval '1 day');

  select created_by_uid into v_target from public.alerts
   where id = p_alert_id and status = 'published' and deleted_at is null;
  if v_target is null or v_target = auth.uid() then raise exception 'invalid_target' using errcode = 'P0002'; end if;

  insert into public.user_reports (reporter, target_user, alert_id, reason, note)
  values (auth.uid(), v_target, p_alert_id, p_reason, nullif(left(btrim(coalesce(p_note, '')), 200), ''))
  on conflict do nothing;

  perform public._maybe_restrict(v_target);
end $$;
revoke all on function public.report_content(uuid, text, text) from public, anon;
grant execute on function public.report_content(uuid, text, text) to authenticated;

create or replace function public.block_author(p_alert_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_target uuid; v_title text;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  select created_by_uid, title into v_target, v_title from public.alerts
   where id = p_alert_id and status = 'published' and deleted_at is null;
  if v_target is null or v_target = auth.uid() then raise exception 'invalid_target' using errcode = 'P0002'; end if;
  if (select count(*) from public.user_blocks where blocker = auth.uid()) >= 200 then
    raise exception 'too_many_blocks' using errcode = 'P0001';
  end if;
  insert into public.user_blocks (blocker, blocked, label)
  values (auth.uid(), v_target, left(v_title, 60))
  on conflict do nothing;
end $$;
revoke all on function public.block_author(uuid) from public, anon;
grant execute on function public.block_author(uuid) to authenticated;

create or replace function public.unblock_user(p_user uuid)
returns void language sql security definer set search_path = public as $$
  delete from public.user_blocks where blocker = auth.uid() and blocked = p_user;
$$;
revoke all on function public.unblock_user(uuid) from public, anon;
grant execute on function public.unblock_user(uuid) to authenticated;

-- ------------------------------------------------------------------------------
-- 7. Staff: review reported users
-- ------------------------------------------------------------------------------
create or replace function public.admin_list_user_reports()
returns table (target_user uuid, username text, full_name text, restriction text,
               reports bigint, reporters bigint, last_at timestamptz, reasons text[], sample_title text)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'forbidden' using errcode = '42501'; end if;
  return query
    select t.target_user, p.username, p.full_name, coalesce(ur.status, 'none'),
           count(*), count(distinct t.reporter), max(t.created_at),
           array_agg(distinct t.reason),
           (select a.title from public.alerts a where a.id = (array_agg(t.alert_id order by t.created_at desc))[1])
      from public.user_reports t
      join public.profiles p on p.id = t.target_user
      left join public.user_restrictions ur on ur.user_id = t.target_user
     where t.status = 'new' or ur.user_id is not null
     group by t.target_user, p.username, p.full_name, ur.status
     order by count(distinct t.reporter) desc, max(t.created_at) desc
     limit 100;
end $$;
revoke all on function public.admin_list_user_reports() from public, anon;
grant execute on function public.admin_list_user_reports() to authenticated;

create or replace function public.admin_resolve_user_report(p_user uuid, p_action text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_note  text := btrim(coalesce(p_note, ''));
  v_staff boolean;
begin
  if not public.is_admin() then raise exception 'forbidden' using errcode = '42501'; end if;
  if p_action not in ('dismiss', 'warn', 'restrict', 'ban', 'reinstate') then
    raise exception 'invalid_action' using errcode = '22023';
  end if;
  if p_user = auth.uid() then raise exception 'forbidden' using errcode = '42501'; end if;
  if not exists (select 1 from public.profiles where id = p_user) then raise exception 'not_found' using errcode = 'P0002'; end if;

  v_staff := exists (select 1 from public.user_roles where uid = p_user and revoked_at is null
                        and role in ('moderator', 'admin', 'superadmin', 'govt_official'));
  if v_staff and p_action in ('restrict', 'ban') and not public.is_superadmin() then
    raise exception 'superadmin_required' using errcode = '42501';
  end if;
  if exists (select 1 from public.user_roles where uid = p_user and revoked_at is null and role = 'superadmin')
     and p_action in ('restrict', 'ban') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_action in ('restrict', 'ban', 'reinstate') and char_length(v_note) < 5 then
    raise exception 'reason_required' using errcode = '22023';
  end if;

  if p_action in ('dismiss', 'warn') then
    delete from public.user_restrictions where user_id = p_user and status = 'restricted';
    update public.user_reports set status = 'reviewed' where target_user = p_user and status = 'new';
  elsif p_action = 'restrict' then
    insert into public.user_restrictions (user_id, status, reason, decided_by, decided_at)
    values (p_user, 'restricted', v_note, auth.uid(), now())
    on conflict (user_id) do update set status = 'restricted', reason = v_note, decided_by = auth.uid(), decided_at = now();
    update public.user_reports set status = 'reviewed' where target_user = p_user and status = 'new';
    insert into public.security_events (user_id, kind, detail)
    values (p_user, 'user_restricted', jsonb_build_object('by', auth.uid(), 'reason', v_note));
  elsif p_action = 'ban' then
    insert into public.user_restrictions (user_id, status, reason, decided_by, decided_at)
    values (p_user, 'banned', v_note, auth.uid(), now())
    on conflict (user_id) do update set status = 'banned', reason = v_note, decided_by = auth.uid(), decided_at = now();
    perform set_config('myharur.profile_guard_bypass', 'on', true);
    update public.profiles set is_active = false where id = p_user;
    perform set_config('myharur.profile_guard_bypass', 'off', true);
    delete from auth.sessions where user_id = p_user;
    update public.user_reports set status = 'reviewed' where target_user = p_user and status = 'new';
    insert into public.security_events (user_id, kind, detail)
    values (p_user, 'user_banned', jsonb_build_object('by', auth.uid(), 'reason', v_note));
  else -- reinstate
    delete from public.user_restrictions where user_id = p_user;
    perform set_config('myharur.profile_guard_bypass', 'on', true);
    update public.profiles set is_active = true where id = p_user;
    perform set_config('myharur.profile_guard_bypass', 'off', true);
    insert into public.security_events (user_id, kind, detail)
    values (p_user, 'user_reinstated', jsonb_build_object('by', auth.uid(), 'reason', v_note));
  end if;

  insert into public.crud_audit_logs (user_id, action, table_name, record_id, details)
  values (auth.uid(), 'user.' || p_action, 'profiles', p_user::text, jsonb_build_object('note', nullif(v_note, '')));
end $$;
revoke all on function public.admin_resolve_user_report(uuid, text, text) from public, anon;
grant execute on function public.admin_resolve_user_report(uuid, text, text) to authenticated;

-- ------------------------------------------------------------------------------
-- 8. Bug reports (anyone files, only super admins read: client_errors, kind 'bug')
-- ------------------------------------------------------------------------------
create or replace function public.report_bug(p_title text, p_details text, p_app_version text, p_os text)
returns void language plpgsql security definer set search_path = public as $$
declare v_title text := btrim(coalesce(p_title, '')); v_details text := btrim(coalesce(p_details, ''));
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  if char_length(v_title) not between 5 and 100 or char_length(v_details) not between 10 and 2000 then
    raise exception 'invalid_length' using errcode = 'P0001';
  end if;
  perform public.enforce_rate_limit('bug_report', 5, interval '1 day');
  insert into public.client_errors (user_id, kind, message, details, app_version, os, screen)
  values (auth.uid(), 'bug', left(public.redact(v_title), 100), left(public.redact(v_details), 2000),
          left(p_app_version, 40), left(p_os, 80), 'bug_report');
end $$;
revoke all on function public.report_bug(text, text, text, text) from public, anon;
grant execute on function public.report_bug(text, text, text, text) to authenticated;

-- ------------------------------------------------------------------------------
-- 9. Housekeeping: reviewed reports are kept 180 days
-- ------------------------------------------------------------------------------
create or replace function public.prune_security_tables()
returns void language sql security definer set search_path = public as $$
  delete from public.auth_attempts   where created_at < now() - interval '2 days';
  delete from public.rate_limits     where window_start < now() - interval '2 days';
  delete from public.client_errors   where created_at < now() - interval '90 days';
  delete from public.security_events where created_at < now() - interval '365 days';
  delete from public.user_reports    where status = 'reviewed' and created_at < now() - interval '180 days';
$$;
revoke all on function public.prune_security_tables() from public, anon, authenticated;
