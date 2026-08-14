-- MyHarur base identity. This migration intentionally stores no passwords.
-- Authentication lives in Supabase Auth; application authorization lives here.

create extension if not exists pgcrypto;
create extension if not exists citext;

create type public.app_role as enum (
  'member',
  'moderator',
  'admin',
  'government_official',
  'shop_admin',
  'super_admin',
  'event_head',
  'organizing_secretary'
);

create or replace function public.generate_mmid()
returns text
language sql
volatile
as $$
  select 'MM-' || to_char(now() at time zone 'utc', 'YYYYMMDDHH24MISS') || '-' ||
    lpad((floor(random() * 10000))::int::text, 4, '0') || '-' ||
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  mmid text not null unique default public.generate_mmid(),
  username citext unique,
  display_name text,
  avatar_path text,
  home_area text,
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (username is null or username ~ '^[a-zA-Z0-9_]{3,30}$')
);

create table public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.app_role not null,
  assigned_by uuid references public.profiles(id) on delete set null,
  assigned_at timestamptz not null default now(),
  revoked_at timestamptz,
  primary key (user_id, role)
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.has_active_role(required_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and role = required_role and revoked_at is null
  );
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid()
      and revoked_at is null
      and role in ('moderator', 'admin', 'government_official', 'super_admin')
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'));

  insert into public.user_roles (user_id, role) values (new.id, 'member');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.audit_events enable row level security;

create policy "profiles are readable to signed-in members"
  on public.profiles for select to authenticated using (true);
create policy "members update their own profile"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy "members read their roles"
  on public.user_roles for select to authenticated
  using (user_id = auth.uid() or public.is_staff());
create policy "staff read audit events"
  on public.audit_events for select to authenticated using (public.is_staff());

revoke all on function public.has_active_role(public.app_role) from public;
revoke all on function public.is_staff() from public;
grant execute on function public.has_active_role(public.app_role) to authenticated;
grant execute on function public.is_staff() to authenticated;

