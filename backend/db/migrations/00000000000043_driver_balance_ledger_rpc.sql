-- P4-C-01: driver_balance + driver_ledger RPCs (doc 03 §7, own-select only)

-- ---------------------------------------------------------------------------
-- rpc.driver_balance() — balance, thresholds, standing (doc 03 §7)
-- ---------------------------------------------------------------------------
create or replace function driver_balance()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_driver_id uuid := auth.uid();
  v_city_id uuid;
  v_standing driver_standing;
  v_balance numeric := 0;
  v_currency char(3);
  v_grace_deadline timestamptz;
  v_deposit numeric;
  v_warned_at timestamptz;
  v_grace_hours numeric;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select d.city_id, d.standing
  into v_city_id, v_standing
  from drivers d
  where d.id = v_driver_id;

  if v_city_id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  select k.currency_code
  into v_currency
  from cities ci
  join countries k on k.code = ci.country_code
  where ci.id = v_city_id;

  select coalesce(db.balance, 0)
  into v_balance
  from driver_balances db
  where db.driver_id = v_driver_id
  limit 1;

  v_deposit := private.driver_deposit_held(v_driver_id);

  if v_standing = 'warned' then
    select dst.created_at
    into v_warned_at
    from driver_standing_transitions dst
    where dst.driver_id = v_driver_id
      and dst.to_standing = 'warned'
    order by dst.created_at desc
    limit 1;

    if v_warned_at is not null then
      v_grace_hours := cfg_num('ledger.grace_period_hours', v_city_id);
      v_grace_deadline := v_warned_at + make_interval(hours => v_grace_hours::int);
    end if;
  end if;

  return jsonb_build_object(
    'balance', jsonb_build_object(
      'amount', to_char(v_balance, 'FM999999990.00'),
      'currency', v_currency
    ),
    'block_threshold', jsonb_build_object(
      'amount', to_char(cfg_num('ledger.block_threshold', v_city_id), 'FM999999990.00'),
      'currency', v_currency
    ),
    'standing', v_standing::text,
    'grace_deadline', v_grace_deadline,
    'deposit_held', jsonb_build_object(
      'amount', to_char(v_deposit, 'FM999999990.00'),
      'currency', v_currency
    )
  );
end;
$$;

grant execute on function driver_balance() to authenticated;

-- ---------------------------------------------------------------------------
-- rpc.driver_ledger(p_cursor?, p_limit) — paginated own entries (doc 03 §7)
-- ---------------------------------------------------------------------------
create or replace function driver_ledger(p_cursor text default null, p_limit int default 50)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_driver_id uuid := auth.uid();
  v_limit int;
  v_cursor_id bigint;
  v_entries jsonb;
  v_next_cursor text;
  v_last_id bigint;
  v_has_more boolean;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  v_limit := least(greatest(coalesce(p_limit, 50), 1), 50);

  if p_cursor is not null and btrim(p_cursor) <> '' then
    begin
      v_cursor_id := p_cursor::bigint;
    exception
      when others then
        raise exception 'VALIDATION' using errcode = 'P0001', message = 'invalid cursor';
    end;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', e.id::text,
        'entry_type', e.entry_type::text,
        'amount', jsonb_build_object(
          'amount', to_char(e.amount, 'FM999999990.00'),
          'currency', e.currency
        ),
        'balance_after', jsonb_build_object(
          'amount', to_char(e.balance_after, 'FM999999990.00'),
          'currency', e.currency
        ),
        'created_at', e.created_at,
        'memo', e.memo,
        'trip_id', e.trip_id,
        'destination_label', coalesce(rs.name, t.destination_label)
      )
      order by e.id desc
    ),
    '[]'::jsonb
  )
  into v_entries
  from (
    select dle.*
    from driver_ledger_entries dle
    where dle.driver_id = v_driver_id
      and (v_cursor_id is null or dle.id < v_cursor_id)
    order by dle.id desc
    limit v_limit
  ) e
  left join trips t on t.id = e.trip_id
  left join route_stages rs on rs.id = t.alighting_stage_id;

  select min((entry->>'id')::bigint)
  into v_last_id
  from jsonb_array_elements(v_entries) entry;

  if v_last_id is not null then
    select exists (
      select 1
      from driver_ledger_entries dle
      where dle.driver_id = v_driver_id
        and dle.id < v_last_id
    )
    into v_has_more;

    if v_has_more then
      v_next_cursor := v_last_id::text;
    end if;
  end if;

  return jsonb_build_object(
    'entries', v_entries,
    'meta', jsonb_build_object('next_cursor', v_next_cursor)
  );
end;
$$;

grant execute on function driver_ledger(text, int) to authenticated;
