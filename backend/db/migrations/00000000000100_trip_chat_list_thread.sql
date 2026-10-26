-- list_trip_messages returns each line's thread so the apps can show the
-- post-trip lost-and-found lines as their own labelled section.

create or replace function list_trip_messages(p_trip_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_trip trips%rowtype;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_trip from trips where id = p_trip_id;
  if v_trip.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_trip.rider_id <> v_user and v_trip.driver_id is distinct from v_user and not is_admin() then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', m.id,
      'author_role', m.author_role,
      'body', m.body,
      'client_ref', case when m.author_id = v_user then m.client_ref end,
      'created_at', m.created_at,
      'read_at', m.read_at,
      'thread', m.thread
    ) order by m.created_at, m.id)
    from trip_messages m
    where m.trip_id = p_trip_id
  ), '[]'::jsonb);
end;
$$;

revoke all on function list_trip_messages(uuid) from public;
grant execute on function list_trip_messages(uuid) to authenticated;
