-- P5-D-01: admin SOS/incident RPCs, SLA config, sos_ack notify (doc 03 §11, A-12)

select config_default('sos.ack_sla_s', '60');
select config_default('sos.escalate_sla_s', '180');

-- ---------------------------------------------------------------------------
-- Notify raiser on admin acknowledge (doc 08 §5 — sos_ack to raiser app)
-- ---------------------------------------------------------------------------
create or replace function private.enqueue_notify_sos_ack(p_sos_id uuid)
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
      'kind', 'sos_ack',
      'sos_id', p_sos_id
    )
  );
exception
  when others then
    null;
end;
$$;

revoke all on function private.enqueue_notify_sos_ack(uuid) from public;
grant execute on function private.enqueue_notify_sos_ack(uuid) to service_role;

create or replace function private.sos_city_id(p_sos sos_alerts)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select j.city_id from trips t join journeys j on j.id = t.journey_id where t.id = p_sos.trip_id),
    (select j.city_id from journeys j where j.id = p_sos.journey_id)
  )
$$;

revoke all on function private.sos_city_id(sos_alerts) from public;
grant execute on function private.sos_city_id(sos_alerts) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_ack_sos — safety / ops_lead (doc 03 §11)
-- ---------------------------------------------------------------------------
create or replace function admin_ack_sos(p_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_sos sos_alerts%rowtype;
  v_city_id uuid;
begin
  if not has_admin_role(array['safety', 'ops_lead']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select * into v_sos from sos_alerts where id = p_id for update;
  if v_sos.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_city_id := private.sos_city_id(v_sos);
  if v_city_id is not null and not admin_can_access_city(v_city_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_sos.status <> 'open' then
    raise exception using errcode = 'P0001', message = 'SOS is not open';
  end if;

  update sos_alerts
  set
    status = 'acknowledged',
    acknowledged_by = auth.uid(),
    acknowledged_at = now()
  where id = p_id;

  perform private.enqueue_notify_sos_ack(p_id);

  return jsonb_build_object(
    'sos_id', p_id,
    'status', 'acknowledged',
    'acknowledged_at', now()
  );
end;
$$;

revoke all on function admin_ack_sos(uuid) from public;
grant execute on function admin_ack_sos(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_resolve_sos — safety (doc 03 §11)
-- ---------------------------------------------------------------------------
create or replace function admin_resolve_sos(
  p_id uuid,
  p_status text,
  p_note text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_sos sos_alerts%rowtype;
  v_city_id uuid;
  v_status sos_status;
begin
  if not has_admin_role(array['safety']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_status is null or p_status not in ('resolved', 'false_alarm') then
    raise exception using errcode = 'P0001', message = 'status must be resolved or false_alarm';
  end if;

  v_status := p_status::sos_status;

  select * into v_sos from sos_alerts where id = p_id for update;
  if v_sos.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_city_id := private.sos_city_id(v_sos);
  if v_city_id is not null and not admin_can_access_city(v_city_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_sos.status not in ('open', 'acknowledged') then
    raise exception using errcode = 'P0001', message = 'SOS is not active';
  end if;

  update sos_alerts
  set
    status = v_status,
    resolved_at = now(),
    resolution_note = nullif(btrim(p_note), '')
  where id = p_id;

  return jsonb_build_object(
    'sos_id', p_id,
    'status', v_status::text,
    'resolved_at', now()
  );
end;
$$;

revoke all on function admin_resolve_sos(uuid, text, text) from public;
grant execute on function admin_resolve_sos(uuid, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_triage_incident — safety / ops_agent (doc 03 §11)
-- ---------------------------------------------------------------------------
create or replace function admin_triage_incident(
  p_id uuid,
  p_status text,
  p_assigned_to uuid default null,
  p_severity smallint default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_incident incidents%rowtype;
  v_city_id uuid;
  v_status incident_status;
begin
  if not has_admin_role(array['safety', 'ops_agent']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_status is null or p_status not in ('open', 'triaged', 'resolved', 'dismissed') then
    raise exception using errcode = 'P0001', message = 'invalid incident status';
  end if;

  v_status := p_status::incident_status;

  if p_severity is not null and (p_severity < 1 or p_severity > 4) then
    raise exception using errcode = 'P0001', message = 'severity must be between 1 and 4';
  end if;

  select * into v_incident from incidents where id = p_id for update;
  if v_incident.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_incident.trip_id is not null then
    select j.city_id into v_city_id
    from trips t join journeys j on j.id = t.journey_id
    where t.id = v_incident.trip_id;
    if v_city_id is not null and not admin_can_access_city(v_city_id) then
      raise exception 'FORBIDDEN' using errcode = 'P0001';
    end if;
  end if;

  if p_assigned_to is not null then
    if not exists (
      select 1 from admin_users a
      where a.id = p_assigned_to and a.disabled_at is null
    ) then
      raise exception using errcode = 'P0001', message = 'assigned_to is not an active admin';
    end if;
  end if;

  update incidents
  set
    status = v_status,
    assigned_to = coalesce(p_assigned_to, assigned_to),
    severity = coalesce(p_severity, severity),
    resolved_at = case
      when v_status in ('resolved', 'dismissed') then coalesce(resolved_at, now())
      else resolved_at
    end
  where id = p_id;

  return jsonb_build_object(
    'incident_id', p_id,
    'status', v_status::text,
    'assigned_to', coalesce(p_assigned_to, v_incident.assigned_to),
    'severity', coalesce(p_severity, v_incident.severity)
  );
end;
$$;

revoke all on function admin_triage_incident(uuid, text, uuid, smallint) from public;
grant execute on function admin_triage_incident(uuid, text, uuid, smallint) to authenticated;
