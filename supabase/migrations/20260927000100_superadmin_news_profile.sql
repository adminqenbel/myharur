-- ==============================================================================
-- MyHarur — super admin tooling, local news, Google profile sync, signup lock-down
--
--   1. news_articles           : headlines gathered by the news-crawler edge function
--   2. Admin RPCs              : role management, user search, filter-word lists, stats
--   3. Profile sync            : name + Google photo copied into profiles on signup
--   4. Email sign-up lock-down : accounts are created through Google only; staff add a
--                                password afterwards (Account > Staff password)
-- Safe to re-run.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. News
-- ------------------------------------------------------------------------------
create table if not exists public.news_articles (
  id            uuid primary key default gen_random_uuid(),
  guid          text not null unique,                 -- feed item id (dedupe key)
  title         text not null,
  url           text not null,
  source        text,
  summary       text,
  category      text not null default 'general'
                check (category in ('traffic','weather','civic','farming','general')),
  region        text not null default 'both'
                check (region in ('harur','dharmapuri','both')),
  language      text not null default 'en' check (language in ('en','ta')),
  published_at  timestamptz not null,
  created_at    timestamptz not null default now()
);
create index if not exists news_articles_feed_idx on public.news_articles (published_at desc);
create index if not exists news_articles_cat_idx  on public.news_articles (category, published_at desc);

alter table public.news_articles enable row level security;
drop policy if exists news_public_read on public.news_articles;
create policy news_public_read on public.news_articles for select using (true);
-- writes: service role only (the crawler); no client policies.

create or replace function public.prune_news()
returns void language sql security definer set search_path = public as $$
  delete from public.news_articles where published_at < now() - interval '30 days';
$$;
revoke all on function public.prune_news() from public, anon, authenticated;

-- ------------------------------------------------------------------------------
-- 2. Admin RPCs
-- ------------------------------------------------------------------------------
-- Role rules:
--   moderator / govt_official : granted or revoked by an admin or superadmin
--   admin                     : superadmin only
--   superadmin                : superadmin only, at most 3 active, never the last one removed
create or replace function public.admin_set_role(p_user uuid, p_role text, p_grant boolean)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_caller_super boolean;
  v_caller_admin boolean;
  v_active_supers int;
begin
  select exists (select 1 from public.user_roles where uid = auth.uid() and revoked_at is null and role = 'superadmin'),
         public.is_admin()
    into v_caller_super, v_caller_admin;

  if not v_caller_admin then raise exception 'forbidden' using errcode = '42501'; end if;
  if p_role not in ('moderator','govt_official','admin','superadmin') then
    raise exception 'invalid_role';
  end if;
  if p_role in ('admin','superadmin') and not v_caller_super then
    raise exception 'superadmin_required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.profiles where id = p_user) then
    raise exception 'user_not_found';
  end if;

  if p_grant then
    if p_role = 'superadmin' then
      select count(*) into v_active_supers from public.user_roles
       where role = 'superadmin' and revoked_at is null and uid <> p_user;
      if v_active_supers >= 3 then raise exception 'superadmin_limit_reached'; end if;
    end if;
    insert into public.user_roles (uid, role, scope, granted_by, granted_at, revoked_at)
    values (p_user, p_role, 'global', auth.uid(), now(), null)
    on conflict (uid, role, scope)
    do update set revoked_at = null, granted_by = auth.uid(), granted_at = now();
  else
    if p_role = 'superadmin' then
      select count(*) into v_active_supers from public.user_roles
       where role = 'superadmin' and revoked_at is null and uid <> p_user;
      if v_active_supers = 0 then raise exception 'last_superadmin'; end if;
    end if;
    update public.user_roles set revoked_at = now()
     where uid = p_user and role = p_role and revoked_at is null;
  end if;

  insert into public.crud_audit_logs (user_id, action, table_name, record_id, details)
  values (auth.uid(), case when p_grant then 'role.grant' else 'role.revoke' end,
          'user_roles', p_user::text, jsonb_build_object('role', p_role));
end $$;

-- User search for the admin panel (admins and superadmins only).
create or replace function public.admin_search_users(p_query text default '')
returns table (id uuid, username text, full_name text, email text, avatar_url text, roles text[])
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'forbidden' using errcode = '42501'; end if;
  return query
    select p.id, p.username, p.full_name, p.email, p.avatar_url,
           coalesce((select array_agg(r.role order by r.role) from public.user_roles r
                      where r.uid = p.id and r.revoked_at is null), '{}'::text[])
      from public.profiles p
     where coalesce(p_query, '') = ''
        or p.email ilike '%' || p_query || '%'
        or p.username ilike '%' || p_query || '%'
        or p.full_name ilike '%' || p_query || '%'
     order by p.created_at desc
     limit 25;
end $$;

-- Filter-word lists (superadmin only). kind: 'profanity' | 'danger'
create or replace function public.admin_filter_terms()
returns table (kind text, term text, detail text)
language plpgsql stable security definer set search_path = public as $$
begin
  if not exists (select 1 from public.user_roles where uid = auth.uid() and revoked_at is null and role = 'superadmin') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
    select 'profanity'::text, p.term, p.script from public.profanity_wordlist p
    union all
    select 'danger'::text, d.term, d.severity from public.moderation_danger_terms d
    order by 1, 2;
end $$;

-- detail: script for profanity (english|tamil_unicode|tamil_tanglish|hindi_tanglish), severity for danger (flag|block)
create or replace function public.admin_save_filter_term(p_kind text, p_term text, p_detail text)
returns void language plpgsql security definer set search_path = public as $$
declare
  -- Stored in the same normalised form the filter compares against (3+ repeated letters
  -- collapse to one, see alerts_before_insert), otherwise such a term could never match.
  v_term text := regexp_replace(lower(btrim(coalesce(p_term, ''))), '(.)\1{2,}', '\1', 'g');
begin
  if not exists (select 1 from public.user_roles where uid = auth.uid() and revoked_at is null and role = 'superadmin') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if char_length(v_term) < 2 or char_length(v_term) > 60 then raise exception 'invalid_term'; end if;
  if p_kind = 'profanity' then
    insert into public.profanity_wordlist (term, script, added_by)
    values (v_term, coalesce(p_detail, 'english'), auth.uid())
    on conflict (lower(term), script) do nothing;
  elsif p_kind = 'danger' then
    insert into public.moderation_danger_terms (term, severity)
    values (v_term, coalesce(p_detail, 'flag'))
    on conflict (term) do update set severity = excluded.severity;
  else
    raise exception 'invalid_kind';
  end if;
end $$;

create or replace function public.admin_delete_filter_term(p_kind text, p_term text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.user_roles where uid = auth.uid() and revoked_at is null and role = 'superadmin') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_kind = 'profanity' then
    delete from public.profanity_wordlist where lower(term) = lower(p_term);
  elsif p_kind = 'danger' then
    delete from public.moderation_danger_terms where term = lower(p_term);
  else
    raise exception 'invalid_kind';
  end if;
end $$;

-- Headline numbers for the admin panel
create or replace function public.admin_stats()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'forbidden' using errcode = '42501'; end if;
  return jsonb_build_object(
    'users',           (select count(*) from public.profiles),
    'staff',           (select count(distinct uid) from public.user_roles
                         where revoked_at is null and role in ('moderator','admin','superadmin')),
    'pending_alerts',  (select count(*) from public.alerts where status = 'pending'),
    'published_alerts',(select count(*) from public.alerts where status = 'published'),
    'auto_rejected',   (select count(*) from public.alerts where status = 'rejected' and moderation_reason = 'auto_rejected'),
    'news_articles',   (select count(*) from public.news_articles),
    'last_news_at',    (select max(created_at) from public.news_articles)
  );
end $$;

do $$
declare f text;
begin
  foreach f in array array[
    'admin_set_role(uuid,text,boolean)', 'admin_search_users(text)', 'admin_filter_terms()',
    'admin_save_filter_term(text,text,text)', 'admin_delete_filter_term(text,text)', 'admin_stats()'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- ------------------------------------------------------------------------------
-- 3. Profile sync from Google (name + photo)
-- ------------------------------------------------------------------------------
create or replace function public.handle_new_myharur_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  new_mmid text;
  v_name   text := coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Harur Resident');
  v_avatar text := coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture');
begin
  for i in 1..8 loop
    new_mmid := to_char(now() at time zone 'UTC', 'YYYYMMDDHH24MISS')
                || lpad((floor(random() * 9000) + 1000)::int::text, 4, '0');
    begin
      insert into public.profiles (id, mmid, full_name, email, avatar_url, onboarding_state)
      values (new.id, new_mmid, v_name, new.email, v_avatar, 'PENDING_USERNAME')
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
revoke execute on function public.handle_new_myharur_user() from public, anon, authenticated;

-- ------------------------------------------------------------------------------
-- 4. Email sign-up lock-down
--    Anyone with the public key could otherwise call auth.signUp(email, password) and
--    farm accounts around the per-account alert limits. Google creates residents;
--    staff get a password afterwards via updateUser (which does not insert a user).
--    To allow email sign-ups again:  drop trigger block_email_signup on auth.users;
-- ------------------------------------------------------------------------------
create or replace function public.block_email_signup()
returns trigger language plpgsql set search_path = public as $$
begin
  if coalesce(new.raw_app_meta_data->>'provider', '') = 'email' then
    raise exception 'email_signup_disabled' using errcode = 'P0001';
  end if;
  return new;
end $$;
revoke execute on function public.block_email_signup() from public, anon, authenticated;

drop trigger if exists block_email_signup on auth.users;
create trigger block_email_signup before insert on auth.users
  for each row execute function public.block_email_signup();

-- ------------------------------------------------------------------------------
-- 5. Schedule (only when the extensions exist; the crawler secret is created separately,
--    see docs/NEWS.md — nothing secret lives in this file)
-- ------------------------------------------------------------------------------
do $$
begin
  create extension if not exists pg_net;
  perform cron.schedule('myharur-prune-news', '17 3 * * *', 'select public.prune_news()');
exception when others then
  raise notice 'pg_cron / pg_net unavailable (%); schedule prune_news() and the crawler manually.', sqlerrm;
end $$;
