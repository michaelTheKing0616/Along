-- Splits the two trip_messages threads (migration 86 + 98):
--   chat        live rider/driver chat: while the trip is accepted, boarded
--               or in_transit, and for 15 min after it ends.
--   lost_found  post-trip lost-and-found: up to 48 h after it ends.
-- post_trip_message takes p_thread; the trip chat sends 'chat', so it shuts
-- 15 min after the trip. Older callers (no thread) get whichever is open.

alter table trip_messages
  add column thread text not null default 'chat'
  check (thread in ('chat', 'lost_found'));

create or replace function _trip_chat_open(v_trip trips)
returns boolean
language sql
stable
as $$
  select v_trip.status in ('accepted', 'boarded', 'in_transit')
    or (v_trip.ended_at is not null and now() <= v_trip.ended_at + interval '15 minutes');
$$;

create or replace function _trip_lost_found_open(v_trip trips)
returns boolean
language sql
stable
as $$
  select v_trip.ended_at is not null and now() <= v_trip.ended_at + interval '48 hours';
$$;

revoke execute on function _trip_chat_open(trips) from public, anon, authenticated;
revoke execute on function _trip_lost_found_open(trips) from public, anon, authenticated;

drop function post_trip_message(uuid, text, text);

create function post_trip_message(
  p_trip_id uuid,
  p_body text,
  p_client_ref text,
  p_thread text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_trip trips%rowtype;
  v_role text;
  v_body text := btrim(p_body);
  v_row trip_messages%rowtype;
  v_out jsonb;
  v_thread text;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_client_ref is null or char_length(p_client_ref) not between 8 and 80 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if v_body is null or char_length(v_body) not between 1 and 280 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select * into v_trip from trips where id = p_trip_id;
  if v_trip.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_trip.rider_id = v_user then
    v_role := 'rider';
  elsif v_trip.driver_id = v_user then
    v_role := 'driver';
  else
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_thread is not null and p_thread not in ('chat', 'lost_found') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  -- Live chat: the trip plus 15 min. Lost and found: its own 48 h rule.
  -- No thread given (older lost-and-found clients): whichever is open.
  v_thread := case
    when p_thread = 'chat' and _trip_chat_open(v_trip) then 'chat'
    when p_thread = 'lost_found' and _trip_lost_found_open(v_trip) then 'lost_found'
    when p_thread is null and _trip_chat_open(v_trip) then 'chat'
    when p_thread is null and _trip_lost_found_open(v_trip) then 'lost_found'
  end;

  select * into v_row from trip_messages
  where author_id = v_user and client_ref = p_client_ref;
  if v_row.id is not null then
    return jsonb_build_object(
      'id', v_row.id, 'author_role', v_row.author_role, 'body', v_row.body,
      'client_ref', v_row.client_ref, 'created_at', v_row.created_at,
      'read_at', v_row.read_at, 'thread', v_row.thread, 'replayed', true
    );
  end if;

  if v_thread is null then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if (select count(*) from trip_messages
      where trip_id = p_trip_id and author_id = v_user
        and created_at > now() - interval '10 seconds') >= 6
     or (select count(*) from trip_messages where trip_id = p_trip_id) >= 200 then
    raise exception 'RATE_LIMITED' using errcode = 'P0001';
  end if;

  insert into trip_messages (trip_id, author_id, author_role, body, client_ref, thread)
  values (p_trip_id, v_user, v_role, v_body, p_client_ref, v_thread)
  returning * into v_row;

  v_out := jsonb_build_object(
    'id', v_row.id, 'author_role', v_role, 'body', v_body,
    'client_ref', v_row.client_ref, 'created_at', v_row.created_at,
    'read_at', null, 'thread', v_thread, 'replayed', false
  );
  perform realtime.send(
    jsonb_build_object('type', 'message', 'message', v_out),
    'chat', 'trip_chat:' || p_trip_id::text, true
  );
  perform private.enqueue_fcm_trip_message(
    p_trip_id,
    case when v_role = 'rider' then v_trip.driver_id else v_trip.rider_id end
  );
  return v_out;
end;
$$;

revoke all on function post_trip_message(uuid, text, text, text) from public;
grant execute on function post_trip_message(uuid, text, text, text) to authenticated;
