-- ==============================================================================
-- App update policy. One public row the app reads at launch (before sign-in):
--   build < min_supported_build -> blocking "update required" page
--   build < latest_build        -> dismissible "update available" popup
-- Only a super admin with a two-factor session can change it. Nothing in this row is secret.
-- ==============================================================================
create table if not exists public.app_config (
  id                  int         primary key default 1 check (id = 1),
  latest_build        int         not null default 0 check (latest_build >= 0),
  min_supported_build int         not null default 0 check (min_supported_build >= 0),
  update_url          text        check (update_url is null or (update_url ~ '^https://[A-Za-z0-9.-]+(/.*)?$' and char_length(update_url) <= 500)),
  message_en          text        check (char_length(message_en) <= 200),
  message_ta          text        check (char_length(message_ta) <= 200),
  updated_at          timestamptz not null default now(),
  updated_by          uuid        references auth.users(id) on delete set null,
  check (min_supported_build <= latest_build)
);
insert into public.app_config (id, update_url)
values (1, 'https://play.google.com/store/apps/details?id=com.myharur.app')
on conflict (id) do nothing;

alter table public.app_config enable row level security;
revoke all on public.app_config from anon, authenticated;
grant select on public.app_config to anon, authenticated;
drop policy if exists app_config_public_read on public.app_config;
create policy app_config_public_read on public.app_config for select using (true);

create or replace function public.admin_set_app_config(
  p_latest int, p_min int, p_url text, p_message_en text, p_message_ta text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_superadmin() then raise exception 'forbidden' using errcode = '42501'; end if;
  if coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' then
    raise exception 'aal2_required' using errcode = '42501';
  end if;
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
revoke all on function public.admin_set_app_config(int, int, text, text, text) from public, anon;
grant execute on function public.admin_set_app_config(int, int, text, text, text) to authenticated;
