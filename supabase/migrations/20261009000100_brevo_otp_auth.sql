-- ==============================================================================
-- Brevo-backed email/phone OTP sign-in (Phase 4 of the addendum plan).
--
-- Design: reuse Supabase Auth's own email/phone OTP (signInWithOtp / verifyOtp) rather than
-- inventing a parallel one-time-code system — Supabase already generates, hashes, expires and
-- rate-limits the code itself. Two Auth Hooks (edge functions send-email-hook / send-sms-hook,
-- configured in the Supabase dashboard under Authentication > Hooks, not in this repo) intercept
-- delivery and send the code through Brevo's transactional email/SMS APIs instead of Supabase's
-- built-in mailer or a Twilio-style SMS provider. This migration only adds what those hooks and
-- the app need on the database side:
--   1. otp_dispatch / otp_dispatch_daily — per-identifier and whole-app send caps, checked by the
--      hooks BEFORE calling Brevo (SMS costs real money per message, unlike Supabase's own limits).
--   2. handle_new_myharur_user() extended to also seed phone/phone_verified for a brand-new
--      phone-OTP sign-up (mirrors the existing email seeding), so a person who signs up with just
--      a phone number goes straight into the normal onboarding flow, already marked verified.
--   3. mark_phone_verified() — called once by the app right after a signed-in resident verifies a
--      phone number (Account > "Add phone sign-in"). Trusts auth.users.phone/phone_confirmed_at,
--      which only Supabase Auth itself can set after a real OTP check, never the client's say-so.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. OTP dispatch caps (checked by the Auth Hooks with the service role, before calling Brevo)
-- ------------------------------------------------------------------------------
create table if not exists public.otp_dispatch (
  id              bigserial   primary key,
  channel         text        not null check (channel in ('email', 'sms')),
  identifier_hash text        not null,   -- sha256(pepper + normalised email/phone); the raw value is never stored
  sent_at         timestamptz not null default now()
);
create index if not exists otp_dispatch_lookup_idx on public.otp_dispatch (channel, identifier_hash, sent_at desc);
alter table public.otp_dispatch enable row level security;
revoke all on public.otp_dispatch from anon, authenticated;

create table if not exists public.otp_dispatch_daily (
  day     date not null default current_date,
  channel text not null,
  calls   int  not null default 0,
  primary key (day, channel)
);
alter table public.otp_dispatch_daily enable row level security;
revoke all on public.otp_dispatch_daily from anon, authenticated;

-- Records a send and returns true only when every limit still allows it:
--   p_max_per_id  - most sends to the same identifier in a rolling 24h (stops one phone/e-mail being spammed)
--   p_cooldown    - minimum gap since the last send to that identifier (stops a fast double-tap sending twice)
--   p_global_cap  - whole app, that channel, today (protects the paid SMS quota from a coordinated abuse burst)
-- Nothing is recorded when the caller is refused, so a refusal never itself counts against the caps.
create or replace function public.internal_otp_take(
  p_channel text, p_identifier_hash text, p_max_per_id int, p_cooldown interval, p_global_cap int
) returns boolean language plpgsql security definer set search_path = public as $$
declare
  v_last      timestamptz;
  v_count     int;
  v_global_ok boolean;
begin
  select max(sent_at), count(*) into v_last, v_count
    from public.otp_dispatch
    where channel = p_channel and identifier_hash = p_identifier_hash and sent_at > now() - interval '24 hours';

  if v_last is not null and v_last > now() - p_cooldown then return false; end if;
  if v_count >= p_max_per_id then return false; end if;

  with r as (
    insert into public.otp_dispatch_daily (day, channel, calls) values (current_date, p_channel, 1)
    on conflict (day, channel) do update set calls = public.otp_dispatch_daily.calls + 1
      where public.otp_dispatch_daily.calls < greatest(p_global_cap, 1)
    returning 1
  )
  select exists (select 1 from r) into v_global_ok;
  if not v_global_ok then return false; end if;

  insert into public.otp_dispatch (channel, identifier_hash, sent_at) values (p_channel, p_identifier_hash, now());
  return true;
end;
$$;
revoke all on function public.internal_otp_take(text, text, int, interval, int) from public, anon, authenticated;
grant execute on function public.internal_otp_take(text, text, int, interval, int) to service_role;

-- ------------------------------------------------------------------------------
-- 2. New sign-ups via phone OTP get phone/phone_verified seeded, same as email already is.
--    Rebuilt from the CURRENT function (20260927000100_superadmin_news_profile.sql), which
--    already added the avatar_url copy and the mmid-collision retry loop — only the phone
--    fields are new here. (A CREATE OR REPLACE that started from the original baseline body
--    instead would silently revert both of those.)
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
      insert into public.profiles (id, mmid, full_name, email, avatar_url, phone, phone_verified, onboarding_state)
      values (new.id, new_mmid, v_name, new.email, v_avatar, new.phone, (new.phone is not null and new.phone_confirmed_at is not null), 'PENDING_USERNAME')
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
-- 2b. Email sign-up was blocked outright (20260927000100) to stop the public key being used to
--     farm accounts via the raw auth.signUp(email, password) endpoint, bypassing Google entirely.
--     Email OTP sign-in/sign-up uses the same GoTrue "email" provider, so that trigger would also
--     reject every legitimate OTP sign-up — this is the documented, intended way to lift it now
--     that a real, rate-limited (internal_otp_take) e-mail path exists. Password-based signUp is
--     technically reachable again by calling the API directly, but the app itself never exposes
--     that path, and it still requires owning the target inbox to ever get a confirmed, usable
--     session — the same bar OTP sign-up already sets.
-- ------------------------------------------------------------------------------
drop trigger if exists block_email_signup on auth.users;

-- ------------------------------------------------------------------------------
-- 3. Attach a verified phone to an already-signed-in account (Account > "Add phone sign-in")
-- ------------------------------------------------------------------------------
create or replace function public.mark_phone_verified()
returns void language plpgsql security definer set search_path = public as $$
declare
  v_phone     text;
  v_confirmed timestamptz;
begin
  if auth.uid() is null then raise exception 'authentication_required' using errcode = '42501'; end if;
  select phone, phone_confirmed_at into v_phone, v_confirmed from auth.users where id = auth.uid();
  if v_phone is null or v_confirmed is null then
    raise exception 'phone_not_verified' using errcode = 'P0001';
  end if;
  -- phone_verified is a protected column (profiles_protect_columns); only this trusted, narrow
  -- write is allowed to change it, and only to what Supabase Auth itself already confirmed.
  perform set_config('myharur.profile_guard_bypass', 'on', true);
  update public.profiles set phone = v_phone, phone_verified = true where id = auth.uid();
  perform set_config('myharur.profile_guard_bypass', 'off', true);
end;
$$;
revoke all on function public.mark_phone_verified() from public, anon;
grant execute on function public.mark_phone_verified() to authenticated;

-- ------------------------------------------------------------------------------
-- 4. Housekeeping
-- ------------------------------------------------------------------------------
create or replace function public.prune_security_tables()
returns void language sql security definer set search_path = public as $$
  delete from public.auth_attempts     where created_at < now() - interval '2 days';
  delete from public.rate_limits       where window_start < now() - interval '2 days';
  delete from public.client_errors     where created_at < now() - interval '90 days';
  delete from public.security_events   where created_at < now() - interval '365 days';
  delete from public.user_reports      where status = 'reviewed' and created_at < now() - interval '180 days';
  delete from public.ai_usage          where day < current_date - 30;
  delete from public.otp_dispatch      where sent_at < now() - interval '2 days';
  delete from public.otp_dispatch_daily where day < current_date - 30;
$$;
revoke all on function public.prune_security_tables() from public, anon, authenticated;
