-- ==============================================================================
-- Phase 2, part 2: photos on reports and news.
--
-- Private bucket `content-images`. Nobody gets a public URL; the app asks for short-lived signed URLs, and
-- storage only signs a URL for a caller who may SEE the post that references the file (published posts,
-- your own, or staff). A deleted, pending or blocked-author post therefore has no reachable images.
--   * paths are {user id}/{uuid}.{jpg|png|webp}, uploaded by that user only
--   * <= 2 MB, JPEG/PNG/WebP only (bucket limits), <= 15 uploads per hour, restricted users cannot upload
--   * the app strips EXIF/GPS before upload; posts hold at most 3 images (see alerts_before_insert)
--   * files of posts deleted > 30 days ago and uploads never attached to a post are purged nightly
-- ==============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('content-images', 'content-images', false, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = false, file_size_limit = 2097152, allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.recent_uploads()
returns int language sql stable security definer set search_path = public, storage as $$
  select count(*)::int from storage.objects
   where bucket_id = 'content-images'
     and name like auth.uid()::text || '/%'
     and created_at > now() - interval '1 hour';
$$;
revoke all on function public.recent_uploads() from public, anon;
grant execute on function public.recent_uploads() to authenticated;

drop policy if exists content_images_insert on storage.objects;
create policy content_images_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'content-images'
    and (storage.foldername(name))[1] = auth.uid()::text
    and name ~ ('^' || auth.uid()::text || '/[0-9a-f-]{36}\.(jpg|png|webp)$')
    and public.recent_uploads() < 15
    and not exists (select 1 from public.user_restrictions where user_id = auth.uid())
  );

-- The subquery on alerts runs as the caller, so it only finds posts the caller is allowed to see.
drop policy if exists content_images_select on storage.objects;
create policy content_images_select on storage.objects for select to authenticated
  using (
    bucket_id = 'content-images'
    and ((storage.foldername(name))[1] = auth.uid()::text
         or public.is_staff()
         or exists (select 1 from public.alerts a where storage.objects.name = any(a.image_paths)))
  );

-- Delete: your own uploads that no visible post uses yet, or staff.
drop policy if exists content_images_delete on storage.objects;
create policy content_images_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'content-images'
    and (public.is_staff()
         or ((storage.foldername(name))[1] = auth.uid()::text
             and not exists (select 1 from public.alerts a where storage.objects.name = any(a.image_paths))))
  );
-- no UPDATE policy: files are immutable

-- ------------------------------------------------------------------------------
-- Nightly purge (called by the content-purge edge function with the service role)
-- ------------------------------------------------------------------------------
create or replace function public.internal_purge_candidates()
returns table (alert_id uuid, path text)
language sql stable security definer set search_path = public, storage as $$
  select * from (
    select a.id as alert_id, p as path
      from public.alerts a, unnest(a.image_paths) p
     where a.deleted_at < now() - interval '30 days'
    union all
    select null::uuid, o.name
      from storage.objects o
     where o.bucket_id = 'content-images'
       and o.created_at < now() - interval '1 day'
       and not exists (select 1 from public.alerts a where o.name = any(a.image_paths))
  ) c
  limit 500;
$$;

-- Removes the database rows of long-deleted posts once none of their files remain.
create or replace function public.internal_purge_deleted_rows()
returns int language plpgsql security definer set search_path = public, storage as $$
declare v_n int;
begin
  delete from public.alerts a
   where a.deleted_at < now() - interval '30 days'
     and not exists (select 1 from storage.objects o
                      where o.bucket_id = 'content-images' and o.name = any(a.image_paths));
  get diagnostics v_n = row_count;
  return v_n;
end $$;

revoke all on function public.internal_purge_candidates()   from public, anon, authenticated;
revoke all on function public.internal_purge_deleted_rows() from public, anon, authenticated;
grant execute on function public.internal_purge_candidates()   to service_role;
grant execute on function public.internal_purge_deleted_rows() to service_role;

do $$
begin
  if not exists (select 1 from vault.decrypted_secrets where name = 'myharur_cron_secret') then
    raise notice 'vault secret myharur_cron_secret not found - purge NOT scheduled';
    return;
  end if;
  perform cron.schedule(
    'myharur-content-purge',
    '30 21 * * *',                                   -- 03:00 IST
    $job$
      select net.http_post(
        url     := 'https://qpuvhhvzygdbvlichbqs.supabase.co/functions/v1/content-purge',
        headers := jsonb_build_object(
                     'Content-Type', 'application/json',
                     'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'myharur_cron_secret')),
        body    := '{}'::jsonb,
        timeout_milliseconds := 60000
      );
    $job$
  );
exception when others then
  raise notice 'could not schedule purge: %', sqlerrm;
end $$;
