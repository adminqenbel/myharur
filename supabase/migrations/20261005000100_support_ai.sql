-- ==============================================================================
-- Support bot: AI fallback usage cap.
-- The FAQ bot runs entirely in the app. When it cannot help, the person may ask the `support-ai` edge
-- function (Gemini free tier). Two limits protect the free quota:
--   * per person: 10 questions a day (enforce_rate_limit, checked as the caller)
--   * whole app:  a daily cap (default 300) counted here, so one abusive day cannot exhaust the quota
-- ==============================================================================
create table if not exists public.ai_usage (
  day   date primary key default current_date,
  calls int  not null default 0
);
alter table public.ai_usage enable row level security;
revoke all on public.ai_usage from anon, authenticated;

-- Takes one call from today's budget. Returns false when the cap is used up. Service role only.
create or replace function public.internal_ai_take(p_cap int)
returns boolean language sql security definer set search_path = public as $$
  with r as (
    insert into public.ai_usage (day, calls) values (current_date, 1)
    on conflict (day) do update set calls = public.ai_usage.calls + 1
      where public.ai_usage.calls < greatest(p_cap, 1)
    returning 1
  )
  select exists (select 1 from r);
$$;
revoke all on function public.internal_ai_take(int) from public, anon, authenticated;
grant execute on function public.internal_ai_take(int) to service_role;

create or replace function public.prune_security_tables()
returns void language sql security definer set search_path = public as $$
  delete from public.auth_attempts   where created_at < now() - interval '2 days';
  delete from public.rate_limits     where window_start < now() - interval '2 days';
  delete from public.client_errors   where created_at < now() - interval '90 days';
  delete from public.security_events where created_at < now() - interval '365 days';
  delete from public.user_reports    where status = 'reviewed' and created_at < now() - interval '180 days';
  delete from public.ai_usage        where day < current_date - 30;
$$;
revoke all on function public.prune_security_tables() from public, anon, authenticated;
