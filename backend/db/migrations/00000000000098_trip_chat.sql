-- Free in-app trip chat on the existing trip_messages thread (migration 86).
-- Opens while the trip is live (accepted, boarded, in_transit) and keeps the
-- 48 h lost-and-found window after it ends. Only the trip's rider and its
-- accepted driver; writes only through post_trip_message (author = caller).
-- Adds: per-sender rate limit (6 per 10 s, 200 per trip), read receipts, and
-- a private Realtime broadcast on trip_chat:{trip_id}. Quick replies live in
-- config (chat.quick_replies), not in the apps.

select config_default('chat.quick_replies', '{
  "rider": ["I''m at the pickup", "Running 2 min late", "Where are you?", "Okay, thanks"],
  "driver": ["I''m here", "Arriving in 2 min", "Walk up a little, I can''t stop here", "Okay, thanks"]
}');

alter table trip_messages add column read_at timestamptz;

create or replace function _trip_chat_open(v_trip trips)
returns boolean
language sql
stable
as $$
  select v_trip.status in ('accepted', 'boarded', 'in_transit')
    or (v_trip.ended_at is not null and now() <= v_trip.ended_at + interval '48 hours');
$$;

revoke execute on function _trip_chat_open(trips) from public, anon, authenticated;

-- Free FCM wake-up for the other party (no message text in the push).
create or replace function private.enqueue_fcm_trip_message(p_trip_id uuid, p_recipient uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_url text;
  v_key text;
begin
  if p_recipient is null then
    return;
  end if;
  begin
    v_url := nullif(current_setting('app.settings.api_external_url', true), '');
    v_key := nullif(current_setting('app.settings.service_role_key', true), '');
  exception
    when others then
      return;
  end;
  if v_url is null or v_key is null then
    return;
  end if;
  perform net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/notify',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    body := jsonb_build_object(
      'kind', 'trip_message', 'trip_id', p_trip_id, 'recipient_id', p_recipient
    )
  );
exception
  when others then
    null;
end;
$$;

revoke all on function private.enqueue_fcm_trip_message(uuid, uuid) from public;
grant execute on function private.enqueue_fcm_trip_message(uuid, uuid) to service_role;

create or replace function post_trip_message(
  p_trip_id uuid,
  p_body text,
  p_client_ref text
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
  if not _trip_chat_open(v_trip) then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  select * into v_row from trip_messages
  where author_id = v_user and client_ref = p_client_ref;
  if v_row.id is not null then
    return jsonb_build_object(
      'id', v_row.id, 'author_role', v_row.author_role, 'body', v_row.body,
      'client_ref', v_row.client_ref, 'created_at', v_row.created_at,
      'read_at', v_row.read_at, 'replayed', true
    );
  end if;

  if (select count(*) from trip_messages
      where trip_id = p_trip_id and author_id = v_user
        and created_at > now() - interval '10 seconds') >= 6
     or (select count(*) from trip_messages where trip_id = p_trip_id) >= 200 then
    raise exception 'RATE_LIMITED' using errcode = 'P0001';
  end if;

  insert into trip_messages (trip_id, author_id, author_role, body, client_ref)
  values (p_trip_id, v_user, v_role, v_body, p_client_ref)
  returning * into v_row;

  v_out := jsonb_build_object(
    'id', v_row.id, 'author_role', v_role, 'body', v_body,
    'client_ref', v_row.client_ref, 'created_at', v_row.created_at,
    'read_at', null, 'replayed', false
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

revoke all on function post_trip_message(uuid, text, text) from public;
grant execute on function post_trip_message(uuid, text, text) to authenticated;

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
      'read_at', m.read_at
    ) order by m.created_at, m.id)
    from trip_messages m
    where m.trip_id = p_trip_id
  ), '[]'::jsonb);
end;
$$;

revoke all on function list_trip_messages(uuid) from public;
grant execute on function list_trip_messages(uuid) to authenticated;

-- Marks the other party's messages read and broadcasts a read receipt.
create or replace function mark_trip_messages_read(p_trip_id uuid)
returns integer
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_n integer;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from trips t
    where t.id = p_trip_id and (t.rider_id = v_user or t.driver_id = v_user)
  ) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  update trip_messages set read_at = now()
  where trip_id = p_trip_id and author_id <> v_user and read_at is null;
  get diagnostics v_n = row_count;
  if v_n > 0 then
    perform realtime.send(
      jsonb_build_object('type', 'read', 'read_at', now()),
      'chat', 'trip_chat:' || p_trip_id::text, true
    );
  end if;
  return v_n;
end;
$$;

revoke all on function mark_trip_messages_read(uuid) from public;
grant execute on function mark_trip_messages_read(uuid) to authenticated;

-- Realtime: only the trip's rider and driver may join trip_chat:{trip_id}.
create or replace function realtime_trip_chat_party(p_topic text, p_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_uid is not null and exists (
    select 1 from trips t
    where p_topic = 'trip_chat:' || t.id::text
      and (t.rider_id = p_uid or t.driver_id = p_uid)
  );
$$;

revoke all on function realtime_trip_chat_party(text, uuid) from public;
grant execute on function realtime_trip_chat_party(text, uuid) to authenticated, service_role;

drop policy if exists realtime_trip_chat_select on realtime.messages;
create policy realtime_trip_chat_select
  on realtime.messages for select to authenticated
  using (
    realtime.messages.extension = 'broadcast'
    and (select realtime.topic()) like 'trip_chat:%'
    and realtime_trip_chat_party((select realtime.topic()), (select auth.uid()))
  );
