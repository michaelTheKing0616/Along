-- P6-D-02: Admin live map (A-03) — active trip links; coverage-gap scope for ops roles.

-- Ops agents and safety need city-scoped coverage gaps on the live map heat layer.
drop policy if exists coverage_gap_reports_select_admin on coverage_gap_reports;
create policy coverage_gap_reports_select_admin
  on coverage_gap_reports for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'safety', 'analyst'])
    and (city_id is null or admin_can_access_city(city_id))
  );

-- Active trips with rider→driver link endpoints for the live map overlay.
create or replace function admin_active_trips_map(p_city_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
begin
  if auth.uid() is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if not has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'safety'])
     or not admin_can_access_city(p_city_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'trip_id', t.id,
        'status', t.status,
        'na_me_color', t.id_signal_color,
        'na_me_shape', t.id_signal_shape,
        'rider_id', t.rider_id,
        'driver_id', t.driver_id,
        'rider_name', pr.display_name,
        'driver_name', pd.display_name,
        'plate', v.plate_number,
        'rider', case
          when rs.trip_id is not null then jsonb_build_object(
            'lat', st_y(rs.location::geometry),
            'lng', st_x(rs.location::geometry)
          )
          else null
        end,
        'driver', coalesce(
          case
            when ds.trip_id is not null then jsonb_build_object(
              'lat', st_y(ds.location::geometry),
              'lng', st_x(ds.location::geometry)
            )
            else null
          end,
          (
            select jsonb_build_object(
              'lat', st_y(dp.current_location::geometry),
              'lng', st_x(dp.current_location::geometry)
            )
            from driver_presence dp
            where dp.driver_id = t.driver_id
          )
        )
      )
      order by t.updated_at desc
    )
    from trips t
    join journeys j on j.id = t.journey_id
    left join profiles pr on pr.id = t.rider_id
    left join profiles pd on pd.id = t.driver_id
    left join vehicles v on v.id = t.vehicle_id
    left join lateral _latest_trip_sample(t.id, 'rider') rs on true
    left join lateral _latest_trip_sample(t.id, 'driver') ds on true
    where j.city_id = p_city_id
      and t.status in ('accepted', 'boarded', 'in_transit')
  ), '[]'::jsonb);
end;
$$;

revoke all on function admin_active_trips_map(uuid) from public;
grant execute on function admin_active_trips_map(uuid) to authenticated;
