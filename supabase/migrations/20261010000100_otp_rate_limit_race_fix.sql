-- Closes a race in internal_otp_take(): two concurrent sends to the same identifier could both
-- read the per-identifier count before either had inserted its row (no row lock under READ
-- COMMITTED), letting the per-identifier cap be overrun by roughly the number of concurrent
-- requests. The whole-app daily cap was already race-safe (an atomic INSERT ... ON CONFLICT ...
-- WHERE); this makes the per-identifier check equally atomic with a transaction-scoped advisory
-- lock keyed on (channel, identifier_hash), taken before the count check.
create or replace function public.internal_otp_take(
  p_channel text, p_identifier_hash text, p_max_per_id int, p_cooldown interval, p_global_cap int
) returns boolean language plpgsql security definer set search_path = public as $$
declare
  v_last      timestamptz;
  v_count     int;
  v_global_ok boolean;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_channel || ':' || p_identifier_hash, 0));

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
