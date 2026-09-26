-- Phase 2: trusted local information, service areas, weather, and emergency workflows.

create type public.review_status as enum ('pending', 'approved', 'rejected', 'archived');
create type public.emergency_status as enum ('open', 'acknowledged', 'in_progress', 'resolved', 'closed');
create type public.emergency_kind as enum ('police', 'ambulance', 'nearby_help', 'grievance', 'other');

create table public.service_areas (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  district text not null,
  latitude numeric(9,6) not null,
  longitude numeric(9,6) not null,
  radius_meters integer not null default 15000 check (radius_meters between 500 and 100000),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.user_location_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  service_area_id uuid references public.service_areas(id) on delete set null,
  updated_at timestamptz not null default now()
);

create table public.news_items (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 8 and 180),
  summary text not null check (char_length(summary) between 20 and 1200),
  locality text not null,
  source_name text,
  source_url text,
  image_path text,
  status public.review_status not null default 'pending',
  submitted_by uuid references public.profiles(id) on delete set null,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  published_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (source_url is null or source_url ~ '^https://')
);

create table public.weather_snapshots (
  id uuid primary key default gen_random_uuid(),
  service_area_id uuid not null references public.service_areas(id) on delete cascade,
  temperature_c numeric(4,1),
  feels_like_c numeric(4,1),
  condition text not null,
  humidity_percent integer check (humidity_percent between 0 and 100),
  wind_kph numeric(5,1),
  source_name text not null,
  observed_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table public.weather_reports (
  id uuid primary key default gen_random_uuid(),
  service_area_id uuid not null references public.service_areas(id) on delete cascade,
  condition text not null check (char_length(condition) between 3 and 80),
  note text check (char_length(note) <= 500),
  status public.review_status not null default 'pending',
  submitted_by uuid not null references public.profiles(id) on delete cascade,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.emergency_cases (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete restrict,
  kind public.emergency_kind not null,
  status public.emergency_status not null default 'open',
  title text not null check (char_length(title) between 5 and 120),
  description text not null check (char_length(description) between 10 and 2000),
  service_area_id uuid references public.service_areas(id) on delete set null,
  location_latitude numeric(9,6),
  location_longitude numeric(9,6),
  location_accuracy_meters numeric(8,2),
  location_consent_at timestamptz,
  escalation_radius_meters integer not null default 1000 check (escalation_radius_meters in (1000, 5000, 10000)),
  assigned_official_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz,
  check ((location_latitude is null and location_longitude is null) or (location_latitude between -90 and 90 and location_longitude between -180 and 180))
);

create table public.emergency_media (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.emergency_cases(id) on delete cascade,
  storage_path text not null unique,
  content_type text not null check (content_type in ('image/jpeg', 'image/png', 'image/webp')),
  byte_size integer not null check (byte_size > 0 and byte_size <= 10485760),
  created_at timestamptz not null default now()
);

create table public.emergency_responses (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.emergency_cases(id) on delete cascade,
  responder_id uuid not null references public.profiles(id) on delete restrict,
  message text not null check (char_length(message) between 1 and 1500),
  status_after public.emergency_status,
  is_official boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.emergency_dispatch_attempts (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.emergency_cases(id) on delete cascade,
  radius_meters integer not null check (radius_meters in (1000, 5000, 10000)),
  dispatched_at timestamptz not null default now(),
  recipient_count integer not null default 0,
  acknowledged_at timestamptz
);

create index news_items_feed_index on public.news_items (status, published_at desc);
create index weather_snapshots_area_time_index on public.weather_snapshots (service_area_id, observed_at desc);
create index emergency_cases_reporter_index on public.emergency_cases (reporter_id, created_at desc);
create index emergency_responses_case_index on public.emergency_responses (case_id, created_at asc);

alter table public.service_areas enable row level security;
alter table public.user_location_preferences enable row level security;
alter table public.news_items enable row level security;
alter table public.weather_snapshots enable row level security;
alter table public.weather_reports enable row level security;
alter table public.emergency_cases enable row level security;
alter table public.emergency_media enable row level security;
alter table public.emergency_responses enable row level security;
alter table public.emergency_dispatch_attempts enable row level security;

create policy "active service areas are readable" on public.service_areas for select using (is_active);
create policy "members manage their location preference" on public.user_location_preferences for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "published news is public" on public.news_items for select using (status = 'approved' and (expires_at is null or expires_at > now()));
create policy "members read their news submissions" on public.news_items for select to authenticated using (submitted_by = auth.uid() or public.is_staff());
create policy "members submit pending news" on public.news_items for insert to authenticated with check (submitted_by = auth.uid() and status = 'pending' and reviewed_by is null and published_at is null);
create policy "staff moderate news" on public.news_items for update to authenticated using (public.is_staff()) with check (public.is_staff());

create policy "weather snapshots are readable" on public.weather_snapshots for select using (true);
create policy "staff manage weather snapshots" on public.weather_snapshots for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "members read own weather reports" on public.weather_reports for select to authenticated using (submitted_by = auth.uid() or public.is_staff());
create policy "members submit pending weather reports" on public.weather_reports for insert to authenticated with check (submitted_by = auth.uid() and status = 'pending');
create policy "staff moderate weather reports" on public.weather_reports for update to authenticated using (public.is_staff()) with check (public.is_staff());

-- Emergency cases are created only by the create-emergency Edge Function. The
-- client can read its own cases; staff and government officials can read cases
-- for response/dispatch. Exact coordinates must never be exposed in broad feeds.
create policy "reporters and staff read emergency cases" on public.emergency_cases for select to authenticated using (reporter_id = auth.uid() or public.is_staff());
create policy "staff update emergency cases" on public.emergency_cases for update to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "reporters and staff read emergency media metadata" on public.emergency_media for select to authenticated using (exists (select 1 from public.emergency_cases c where c.id = case_id and (c.reporter_id = auth.uid() or public.is_staff())));
create policy "reporters and staff read emergency responses" on public.emergency_responses for select to authenticated using (exists (select 1 from public.emergency_cases c where c.id = case_id and (c.reporter_id = auth.uid() or public.is_staff())));
create policy "staff and helpers add emergency responses" on public.emergency_responses for insert to authenticated with check (responder_id = auth.uid());
create policy "staff read dispatch attempts" on public.emergency_dispatch_attempts for select to authenticated using (public.is_staff());

insert into public.service_areas (name, district, latitude, longitude, radius_meters)
values
  ('Harur', 'Dharmapuri', 12.053700, 78.480600, 15000),
  ('Dharmapuri', 'Dharmapuri', 12.127700, 78.157900, 25000)
on conflict (name) do nothing;

