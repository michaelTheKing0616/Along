import { ConsoleNav } from '@/components/along/ConsoleNav';
import { getCityBySlug } from '@/lib/city/resolve';
import { parseGeoPoint } from '@/lib/safety/format';
import type {
  AdminAssignee,
  IncidentQueueRow,
  SafetySlaConfig,
  SosBoardRow,
} from '@/lib/safety/types';
import { checkAdminRole, createClient } from '@/lib/supabase/server';
import { SafetyBoard } from './safety-board';

const ACK_ROLES = ['superadmin', 'ops_lead', 'safety'] as const;
const RESOLVE_ROLES = ['superadmin', 'safety'] as const;
const TRIAGE_ROLES = ['superadmin', 'safety', 'ops_agent'] as const;

interface PageProps {
  params: Promise<{ city: string }>;
}

type RawSos = {
  id: string;
  trip_id: string | null;
  journey_id: string | null;
  raised_by: string;
  raised_role: string;
  status: SosBoardRow['status'];
  created_at: string;
  acknowledged_at: string | null;
  location: unknown;
  accuracy_m: number | null;
  profiles: { display_name: string | null } | null;
  trips: {
    id: string;
    status: string;
    journeys: { city_id: string; destination_label: string | null } | null;
    rider: { display_name: string | null } | null;
    driver: { display_name: string | null } | null;
    vehicles: { plate_number: string | null } | null;
  } | null;
  journeys: { city_id: string; destination_label: string | null } | null;
};

type RawIncident = {
  id: string;
  trip_id: string | null;
  type: IncidentQueueRow['type'];
  severity: number;
  status: IncidentQueueRow['status'];
  description: string | null;
  reported_by: string;
  reported_role: string;
  reported_at: string;
  assigned_to: string | null;
  profiles: { display_name: string | null } | null;
  trips: { journeys: { city_id: string } | null } | null;
};

function sosCityId(row: RawSos): string | null {
  return row.trips?.journeys?.city_id ?? row.journeys?.city_id ?? null;
}

function incidentCityId(row: RawIncident): string | null {
  return row.trips?.journeys?.city_id ?? null;
}

async function loadSlaConfig(cityId: string): Promise<SafetySlaConfig> {
  const supabase = await createClient();
  const [{ data: ackSla }, { data: escalateSla }] = await Promise.all([
    supabase.rpc('cfg_num', { p_key: 'sos.ack_sla_s', p_city: cityId }),
    supabase.rpc('cfg_num', { p_key: 'sos.escalate_sla_s', p_city: cityId }),
  ]);

  return {
    ackSlaS: Number(ackSla ?? 60),
    escalateSlaS: Number(escalateSla ?? 180),
  };
}

async function loadOpenSos(cityId: string): Promise<SosBoardRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('sos_alerts')
    .select(
      `
      id,
      trip_id,
      journey_id,
      raised_by,
      raised_role,
      status,
      created_at,
      acknowledged_at,
      location,
      accuracy_m,
      profiles!sos_alerts_raised_by_fkey ( display_name ),
      trips (
        id,
        status,
        journeys ( city_id, destination_label ),
        rider:profiles!trips_rider_id_fkey ( display_name ),
        driver:profiles!trips_driver_id_fkey ( display_name ),
        vehicles ( plate_number )
      ),
      journeys ( city_id, destination_label )
    `
    )
    .in('status', ['open', 'acknowledged'])
    .order('created_at', { ascending: true });

  if (error || !data) {
    console.error('[loadOpenSos]', error?.message);
    return [];
  }

  const now = Date.now();

  return (data as unknown as RawSos[])
    .filter((row) => {
      const rowCity = sosCityId(row);
      return rowCity == null || rowCity === cityId;
    })
    .map((row) => {
      const point = parseGeoPoint(row.location);
      const ageS = Math.max(0, (now - new Date(row.created_at).getTime()) / 1000);
      return {
        id: row.id,
        trip_id: row.trip_id,
        journey_id: row.journey_id,
        raised_by: row.raised_by,
        raised_role: row.raised_role,
        raiser_name: row.profiles?.display_name ?? null,
        status: row.status,
        created_at: row.created_at,
        acknowledged_at: row.acknowledged_at,
        age_s: ageS,
        lat: point?.lat ?? null,
        lng: point?.lng ?? null,
        accuracy_m: row.accuracy_m,
        trip_status: row.trips?.status ?? null,
        rider_name: row.trips?.rider?.display_name ?? null,
        driver_name: row.trips?.driver?.display_name ?? null,
        vehicle_plate: row.trips?.vehicles?.plate_number ?? null,
        destination_label:
          row.trips?.journeys?.destination_label ?? row.journeys?.destination_label ?? null,
      };
    });
}

async function loadIncidentQueue(cityId: string): Promise<IncidentQueueRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('incidents')
    .select(
      `
      id,
      trip_id,
      type,
      severity,
      status,
      description,
      reported_by,
      reported_role,
      reported_at,
      assigned_to,
      profiles!incidents_reported_by_fkey ( display_name ),
      trips ( journeys ( city_id ) )
    `
    )
    .in('status', ['open', 'triaged'])
    .order('reported_at', { ascending: true });

  if (error || !data) {
    console.error('[loadIncidentQueue]', error?.message);
    return [];
  }

  return (data as unknown as RawIncident[])
    .filter((row) => {
      const rowCity = incidentCityId(row);
      return rowCity == null || rowCity === cityId;
    })
    .map((row) => ({
      id: row.id,
      trip_id: row.trip_id,
      type: row.type,
      severity: row.severity,
      status: row.status,
      description: row.description,
      reported_by: row.reported_by,
      reporter_name: row.profiles?.display_name ?? null,
      reported_role: row.reported_role,
      reported_at: row.reported_at,
      assigned_to: row.assigned_to,
    }));
}

async function loadAssignees(): Promise<AdminAssignee[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('admin_users')
    .select('id, role, profiles ( display_name )')
    .in('role', ['safety', 'ops_lead', 'ops_agent'])
    .is('disabled_at', null);

  if (error || !data) return [];

  return (data as Array<{
    id: string;
    role: string;
    profiles: { display_name: string | null } | null;
  }>).map((row) => ({
    id: row.id,
    role: row.role,
    display_name: row.profiles?.display_name ?? null,
  }));
}

export default async function SafetyPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const sosRows = city ? await loadOpenSos(city.id) : [];
  const incidentRows = city ? await loadIncidentQueue(city.id) : [];
  const sla = city ? await loadSlaConfig(city.id) : { ackSlaS: 60, escalateSlaS: 180 };
  const assignees = await loadAssignees();
  const selectedSosId = sosRows.find((row) => row.status === 'open')?.id ?? sosRows[0]?.id ?? null;

  const [canAck, canResolve, canTriage] = await Promise.all([
    checkAdminRole(ACK_ROLES),
    checkAdminRole(RESOLVE_ROLES),
    checkAdminRole(TRIAGE_ROLES),
  ]);

  return (
    <>
      <div className="page-header">
        <h1>Safety board</h1>
        <p>
          Live SOS and incident triage for <strong>{city?.name ?? citySlug}</strong>. Acknowledge
          within {sla.ackSlaS}s; rows escalate at {sla.escalateSlaS}s unacknowledged.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      <SafetyBoard
        citySlug={citySlug}
        cityId={city?.id ?? citySlug}
        initialSosRows={sosRows}
        initialIncidentRows={incidentRows}
        initialSelectedSosId={selectedSosId}
        sla={sla}
        assignees={assignees}
        canAck={canAck}
        canResolve={canResolve}
        canTriage={canTriage}
      />
    </>
  );
}
