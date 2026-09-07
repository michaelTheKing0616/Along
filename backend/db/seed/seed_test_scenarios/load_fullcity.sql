-- P7-E-02 full-city load fixtures (extends load_presence.sql).
-- 100 drivers, 50 riders, 50 active trips for TS-OPS-02/03 distribution.
-- Requires Zaria-Test city graph + load_presence base (run_scaled_local.sh applies both).

\ir load_presence.sql

do $$
declare
  v_city uuid := '0a000000-0000-4000-8000-000000000001';
  v_park uuid := '0a020000-0000-4000-8000-000000000001';
  v_stage uuid := '0a040000-0000-4000-8000-000000000001';
  v_dest_stage uuid := '0a040000-0000-4000-8000-000000000005';
  v_route uuid := '0a030000-0000-4000-8000-000000000001';
  i int;
  v_driver uuid;
  v_rider uuid;
  v_vehicle uuid;
  v_trip uuid;
  v_quote uuid;
  v_lat double precision := 11.061;
  v_lng double precision := 7.701;
begin
  for i in 11..100 loop
    v_driver := ('0e100000-0000-4000-8000-' || lpad(to_hex(i), 12, '0'))::uuid;
    insert into auth.users (id, aud, role, phone)
    values (v_driver, 'authenticated', 'authenticated', '+2348000030' || lpad(i::text, 3, '0'))
    on conflict (id) do nothing;

    insert into profiles (id, phone_e164, display_name)
    values (v_driver, '+2348000030' || lpad(i::text, 3, '0'), 'Load Driver ' || i)
    on conflict (id) do update set display_name = excluded.display_name;

    insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id)
    values (v_driver, v_city, 'verified', 'good_standing', 'LF' || lpad(i::text, 3, '0'), v_park)
    on conflict (id) do update set verified_status = 'verified', standing = 'good_standing';

    v_vehicle := ('0e150000-0000-4000-8000-' || lpad(to_hex(i), 12, '0'))::uuid;
    insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id)
    values (v_vehicle, 'NG', 'car', 'LF-' || lpad(i::text, 3, '0'), 4, v_driver)
    on conflict (id) do nothing;

    insert into driver_vehicles (driver_id, vehicle_id, active)
    values (v_driver, v_vehicle, true)
    on conflict do nothing;

    perform set_config('request.jwt.claim.sub', v_driver::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    perform set_presence(
      'roaming_available',
      jsonb_build_object('lat', v_lat + (i * 0.00005), 'lng', v_lng + (i * 0.00005)),
      4::smallint,
      (90 + (i % 180))::smallint
    );
    execute 'reset role';
  end loop;

  for i in 6..50 loop
    v_rider := ('0e200000-0000-4000-8000-' || lpad(to_hex(i), 12, '0'))::uuid;
    insert into auth.users (id, aud, role, phone)
    values (v_rider, 'authenticated', 'authenticated', '+2348000040' || lpad(i::text, 3, '0'))
    on conflict (id) do nothing;

    insert into profiles (id, phone_e164, display_name)
    values (v_rider, '+2348000040' || lpad(i::text, 3, '0'), 'Load Rider ' || i)
    on conflict (id) do update set display_name = excluded.display_name;

    insert into riders (id, home_city_id)
    values (v_rider, v_city)
    on conflict (id) do nothing;
  end loop;

  for i in 4..50 loop
    v_driver := ('0e100000-0000-4000-8000-' || lpad(to_hex(((i - 1) % 100) + 1), 12, '0'))::uuid;
    v_rider := ('0e200000-0000-4000-8000-' || lpad(to_hex(((i - 1) % 50) + 1), 12, '0'))::uuid;
    v_quote := ('0e160000-0000-4000-8000-' || lpad(to_hex(i), 12, '0'))::uuid;

    insert into fare_quotes (
      id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
      mode_code, tier, amount, currency, components, confidence, expires_at
    ) values (
      v_quote, v_rider, v_driver, v_route, v_stage, v_dest_stage,
      'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '2 hours'
    ) on conflict (id) do nothing;

    insert into planner_queries (
      rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates
    ) values (
      v_rider, v_city,
      st_setsrid(st_makepoint(v_lng + (i * 0.00001), v_lat + (i * 0.00001)), 4326)::geography,
      st_setsrid(st_makepoint(v_lng + 0.005 + (i * 0.00001), v_lat + 0.005 + (i * 0.00001)), 4326)::geography,
      '{}'::jsonb, 1, 1,
      jsonb_build_array(jsonb_build_object(
        'candidate_id', ('0e170000-0000-4000-8000-' || lpad(to_hex(i), 12, '0'))::text,
        'kind', 'direct', 'source', 'parked', 'viable_direct', true,
        'legs', jsonb_build_array(jsonb_build_object(
          'leg_index', 0,
          'mode', jsonb_build_object('code', 'car'),
          'board', jsonb_build_object(
            'stage_id', v_stage, 'name', 'Test Park Alpha',
            'location', jsonb_build_object('lat', v_lat, 'lng', v_lng),
            'walk_m', 0, 'walk_s', 0, 'wayfinding_available', true
          ),
          'alight', jsonb_build_object(
            'stage_id', v_dest_stage, 'name', 'Test Park Beta',
            'location', jsonb_build_object('lat', v_lat + 0.005, 'lng', v_lng + 0.005)
          ),
          'route_id', v_route,
          'route_leg_ids', '[]'::jsonb,
          'fare', jsonb_build_object(
            'amount', 320, 'currency', 'NGN', 'tier', 2,
            'quote_id', v_quote::text, 'unconfirmed', false
          ),
          'supply', jsonb_build_object('kind', 'parked', 'driver_id', v_driver::text)
        ))
      ))
    );

    perform set_config('request.jwt.claim.sub', v_rider::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    perform request_trip(
      ('0e170000-0000-4000-8000-' || lpad(to_hex(i), 12, '0'))::uuid,
      0, false, gen_random_uuid()
    );
    execute 'reset role';

    select id into v_trip from trips where rider_id = v_rider order by created_at desc limit 1;

    perform set_config('request.jwt.claim.sub', v_driver::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    perform respond_to_trip(v_trip, 'accept', null);
    execute 'reset role';
  end loop;
end $$;
