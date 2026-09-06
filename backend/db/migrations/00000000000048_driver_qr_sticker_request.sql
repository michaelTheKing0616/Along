-- request_qr_sticker — driver-initiated sticker print request (doc 14 §6 D-25)
create or replace function request_qr_sticker()
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_code text;
  v_row qr_sticker_requests%rowtype;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select d.driver_code into v_code
  from drivers d
  where d.id = v_driver_id
    and d.payout_subaccount_code is not null
    and btrim(d.payout_subaccount_code) <> '';

  if v_code is null or btrim(v_code) = '' then
    raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'payout bank required';
  end if;

  if exists (
    select 1 from qr_sticker_requests q
    where q.driver_id = v_driver_id
      and q.status = 'pending'
      and q.reason = 'initial'
  ) then
    select * into v_row
    from qr_sticker_requests q
    where q.driver_id = v_driver_id
      and q.status = 'pending'
      and q.reason = 'initial'
    order by q.created_at desc
    limit 1;
  else
    insert into qr_sticker_requests (driver_id, driver_code, reason)
    values (v_driver_id, v_code, 'initial')
    returning * into v_row;
  end if;

  return jsonb_build_object(
    'id', v_row.id,
    'driver_code', v_row.driver_code,
    'reason', v_row.reason,
    'status', v_row.status,
    'created_at', v_row.created_at
  );
end;
$$;

grant execute on function request_qr_sticker() to authenticated;
