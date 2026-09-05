-- P1-E-04: public PMTiles bucket for staging (doc 09 §1 interim tiles posture).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'tiles-staging',
  'tiles-staging',
  true,
  524288000,
  array['application/octet-stream', 'application/json', 'image/png', 'image/webp', 'font/ttf', 'font/woff2']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Anonymous read for map style, sprites, glyphs, and PMTiles range requests.
create policy tiles_staging_objects_select_public
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'tiles-staging');

-- Service role / admin uploads happen out-of-band via dashboard or CI with service key.
create policy tiles_staging_objects_insert_service
  on storage.objects for insert to service_role
  with check (bucket_id = 'tiles-staging');

create policy tiles_staging_objects_update_service
  on storage.objects for update to service_role
  using (bucket_id = 'tiles-staging')
  with check (bucket_id = 'tiles-staging');

create policy tiles_staging_objects_delete_service
  on storage.objects for delete to service_role
  using (bucket_id = 'tiles-staging');
