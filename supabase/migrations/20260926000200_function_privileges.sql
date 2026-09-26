-- ==============================================================================
-- Function hardening (from Supabase security advisor, applied after the moderation
-- pipeline). Supabase's default privileges grant EXECUTE on every new public
-- function to anon + authenticated, and "REVOKE ... FROM PUBLIC" does not undo that.
-- ==============================================================================

-- Pin search_path (advisor 0011)
alter function public.profiles_protect_columns() set search_path = public;
alter function public.handle_updated_at()        set search_path = public;

-- Trigger functions are never meant to be called through /rest/v1/rpc.
-- (Triggers still fire: EXECUTE is only checked when the trigger is created.)
revoke execute on function public.alerts_before_insert()     from public, anon, authenticated;
revoke execute on function public.alerts_after_insert()      from public, anon, authenticated;
revoke execute on function public.handle_new_myharur_user()  from public, anon, authenticated;
revoke execute on function public.profiles_protect_columns() from public, anon, authenticated;
revoke execute on function public.handle_updated_at()        from public, anon, authenticated;

-- Signed-in only
revoke execute on function public.moderate_alert(uuid, text, text, int) from public, anon;
revoke execute on function public.delete_my_account()                   from public, anon;
grant  execute on function public.moderate_alert(uuid, text, text, int) to authenticated;
grant  execute on function public.delete_my_account()                   to authenticated;

-- is_staff() / is_admin() stay callable by anon + authenticated: RLS policies evaluate them
-- as the calling role. They only ever report on the caller's own roles.
