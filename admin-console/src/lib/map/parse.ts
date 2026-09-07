import { parseGeoPoint } from '@/lib/safety/format';
import type {
  GraphVerificationStatus,
  LiveMapActiveTrip,
  LiveMapCoverageGap,
  LiveMapPark,
  LiveMapRoute,
  LiveMapSos,
  LiveMapStage,
  LiveMapStaticPayload,
  PresenceStatus,
} from './types';

function lineCoordinates(path: unknown): [number, number][] {
  if (!path || typeof path !== 'object') return [];
  const geo = path as { type?: string; coordinates?: number[][] };
  if (geo.type !== 'LineString' || !Array.isArray(geo.coordinates)) return [];
  return geo.coordinates
    .filter((coord) => Array.isArray(coord) && coord.length >= 2)
    .map((coord) => [coord[0]!, coord[1]!] as [number, number]);
}

export function parseLiveMapStaticPayload(input: {
  parks: Array<{
    id: string;
    name: string;
    location: unknown;
    verification_status: GraphVerificationStatus;
  }>;
  stages: Array<{
    id: string;
    route_id: string;
    name: string | null;
    location: unknown;
    verification_status: GraphVerificationStatus;
    is_official_park: boolean;
    sequence: number;
  }>;
  routes: Array<{
    id: string;
    mode_code: string;
    verification_status: GraphVerificationStatus;
    path: unknown;
  }>;
  coverageGaps: Array<{
    id: string;
    searched_location: unknown;
    ambient_vehicle_count: number;
    nearest_known_stage_distance_m: number | null;
    searched_at: string;
  }>;
  sos: Array<{
    id: string;
    trip_id: string | null;
    status: string;
    created_at: string;
    location: unknown;
    profiles: { display_name: string | null } | null;
    trips: {
      rider: { display_name: string | null } | null;
      driver: { display_name: string | null } | null;
      vehicles: { plate_number: string | null } | null;
    } | null;
  }>;
}): LiveMapStaticPayload {
  const now = Date.now();

  const parks: LiveMapPark[] = input.parks.flatMap((park) => {
    const point = parseGeoPoint(park.location);
    if (!point) return [];
    return [
      {
        id: park.id,
        name: park.name,
        lat: point.lat,
        lng: point.lng,
        verification_status: park.verification_status,
      },
    ];
  });

  const stages: LiveMapStage[] = input.stages.flatMap((stage) => {
    const point = parseGeoPoint(stage.location);
    if (!point) return [];
    return [
      {
        id: stage.id,
        route_id: stage.route_id,
        name: stage.name,
        lat: point.lat,
        lng: point.lng,
        verification_status: stage.verification_status,
        is_official_park: stage.is_official_park,
        sequence: stage.sequence,
      },
    ];
  });

  const routes: LiveMapRoute[] = input.routes.map((route) => ({
    id: route.id,
    mode_code: route.mode_code,
    verification_status: route.verification_status,
    coordinates: lineCoordinates(route.path),
  }));

  // Build line coordinates from ordered stages when route.path is absent.
  const stagesByRoute = new Map<string, LiveMapStage[]>();
  for (const stage of stages) {
    const list = stagesByRoute.get(stage.route_id) ?? [];
    list.push(stage);
    stagesByRoute.set(stage.route_id, list);
  }
  for (const route of routes) {
    if (route.coordinates.length >= 2) continue;
    const routeStages = stagesByRoute.get(route.id) ?? [];
    if (routeStages.length < 2) continue;
    route.coordinates = routeStages
      .sort((a, b) => a.sequence - b.sequence)
      .map((stage) => [stage.lng, stage.lat] as [number, number]);
  }

  const coverageGaps: LiveMapCoverageGap[] = input.coverageGaps.flatMap((gap) => {
    const point = parseGeoPoint(gap.searched_location);
    if (!point) return [];
    return [
      {
        id: gap.id,
        lat: point.lat,
        lng: point.lng,
        ambient_vehicle_count: gap.ambient_vehicle_count,
        nearest_known_stage_distance_m: gap.nearest_known_stage_distance_m,
        searched_at: gap.searched_at,
      },
    ];
  });

  const sos: LiveMapSos[] = input.sos.flatMap((row) => {
    const point = parseGeoPoint(row.location);
    if (!point) return [];
    const ageS = Math.max(0, (now - new Date(row.created_at).getTime()) / 1000);
    return [
      {
        id: row.id,
        trip_id: row.trip_id,
        status: row.status,
        lat: point.lat,
        lng: point.lng,
        age_s: ageS,
        raiser_name: row.profiles?.display_name ?? null,
        rider_name: row.trips?.rider?.display_name ?? null,
        driver_name: row.trips?.driver?.display_name ?? null,
        vehicle_plate: row.trips?.vehicles?.plate_number ?? null,
      },
    ];
  });

  return { parks, stages, routes, coverageGaps, sos };
}

export function parseActiveTripsMap(payload: unknown): LiveMapActiveTrip[] {
  if (!Array.isArray(payload)) return [];
  return payload
    .map((row) => {
      if (!row || typeof row !== 'object') return null;
      const trip = row as Record<string, unknown>;
      const rider = trip.rider as { lat?: number; lng?: number } | null;
      const driver = trip.driver as { lat?: number; lng?: number } | null;
      return {
        trip_id: String(trip.trip_id),
        status: String(trip.status),
        na_me_color: String(trip.na_me_color),
        na_me_shape: String(trip.na_me_shape),
        rider_id: String(trip.rider_id),
        driver_id: trip.driver_id ? String(trip.driver_id) : null,
        rider_name: trip.rider_name ? String(trip.rider_name) : null,
        driver_name: trip.driver_name ? String(trip.driver_name) : null,
        plate: trip.plate ? String(trip.plate) : null,
        rider:
          rider?.lat != null && rider.lng != null
            ? { lat: Number(rider.lat), lng: Number(rider.lng) }
            : null,
        driver:
          driver?.lat != null && driver.lng != null
            ? { lat: Number(driver.lat), lng: Number(driver.lng) }
            : null,
      } satisfies LiveMapActiveTrip;
    })
    .filter((row): row is LiveMapActiveTrip => row != null);
}

export function parsePresenceVehicles(payload: unknown) {
  if (!payload || typeof payload !== 'object') return [];
  const root = payload as { vehicles?: unknown };
  if (!Array.isArray(root.vehicles)) return [];
  return root.vehicles
    .map((row) => {
      if (!row || typeof row !== 'object') return null;
      const vehicle = row as Record<string, unknown>;
      if (vehicle.lat == null || vehicle.lng == null || vehicle.driver_id == null) return null;
      return {
        driver_id: String(vehicle.driver_id),
        lat: Number(vehicle.lat),
        lng: Number(vehicle.lng),
        heading: vehicle.heading == null ? null : Number(vehicle.heading),
        speed_mps: Number(vehicle.speed_mps ?? 0),
        status: String(vehicle.status) as PresenceStatus,
        mode: String(vehicle.mode ?? ''),
        plate: String(vehicle.plate ?? ''),
        seats_available: Number(vehicle.seats_available ?? 0),
      };
    })
    .filter((row): row is NonNullable<typeof row> => row != null);
}
