-- R-04: complete_rider_onboarding — creates riders row; optional display_name / home_city_id.
-- Spec: docs/blueprint/03_api_contracts.md §1; UI: docs/blueprint/06_ui_audit_and_screens.md R-04.

create or replace function complete_rider_onboarding(
  display_name text default null,
  home_city_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := nullif(btrim(coalesce(display_name, '')), '');
  v_rider riders%rowtype;
begin
  if v_uid is null then
    raise exception using errcode = 'P0001', message = 'ALONG:UNAUTHENTICATED';
  end if;

  if not exists (select 1 from profiles p where p.id = v_uid) then
    insert into profiles (id, phone_e164)
    select u.id, u.phone
    from auth.users u
    where u.id = v_uid
    on conflict (id) do nothing;
  end if;

  if v_name is not null then
    update profiles
    set display_name = v_name,
        updated_at = now()
    where id = v_uid;
  end if;

  if home_city_id is not null and not exists (
    select 1 from cities c where c.id = home_city_id
  ) then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  insert into riders (id, home_city_id)
  values (v_uid, home_city_id)
  on conflict (id) do update
    set home_city_id = coalesce(excluded.home_city_id, riders.home_city_id),
        updated_at = now()
  returning * into v_rider;

  return jsonb_build_object(
    'rider_id', v_rider.id,
    'home_city_id', v_rider.home_city_id,
    'display_name', (select p.display_name from profiles p where p.id = v_uid)
  );
end;
$$;

revoke all on function complete_rider_onboarding(text, uuid) from public;
grant execute on function complete_rider_onboarding(text, uuid) to authenticated;
