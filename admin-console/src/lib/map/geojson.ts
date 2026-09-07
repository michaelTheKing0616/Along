import { coverageGapHeatOpacity, coverageGapHeatRadius } from './filters';
import type {
  LiveMapActiveTrip,
  LiveMapCoverageGap,
  LiveMapPark,
  LiveMapPresenceVehicle,
  LiveMapRoute,
  LiveMapSos,
  LiveMapStage,
} from './types';

type PointFeature = GeoJSON.Feature<GeoJSON.Point, Record<string, unknown>>;

function pointFeature(
  id: string,
  lat: number,
  lng: number,
  properties: Record<string, unknown>
): PointFeature {
  return {
    type: 'Feature',
    id,
    geometry: { type: 'Point', coordinates: [lng, lat] },
    properties,
  };
}

export function parksToGeoJson(parks: LiveMapPark[]): GeoJSON.FeatureCollection {
  return {
    type: 'FeatureCollection',
    features: parks.map((park) =>
      pointFeature(park.id, park.lat, park.lng, {
        kind: 'park',
        name: park.name,
        verification_status: park.verification_status,
      })
    ),
  };
}

export function stagesToGeoJson(stages: LiveMapStage[]): GeoJSON.FeatureCollection {
  return {
    type: 'FeatureCollection',
    features: stages.map((stage) =>
      pointFeature(stage.id, stage.lat, stage.lng, {
        kind: 'stage',
        route_id: stage.route_id,
        name: stage.name,
        verification_status: stage.verification_status,
        is_official_park: stage.is_official_park,
        sequence: stage.sequence,
      })
    ),
  };
}

export function routesToGeoJson(routes: LiveMapRoute[]): GeoJSON.FeatureCollection {
  return {
    type: 'FeatureCollection',
    features: routes
      .filter((route) => route.coordinates.length >= 2)
      .map((route) => ({
        type: 'Feature' as const,
        id: route.id,
        geometry: {
          type: 'LineString' as const,
          coordinates: route.coordinates,
        },
        properties: {
          kind: 'route',
          mode_code: route.mode_code,
          verification_status: route.verification_status,
        },
      })),
  };
}

export function presenceToGeoJson(vehicles: LiveMapPresenceVehicle[]): GeoJSON.FeatureCollection {
  return {
    type: 'FeatureCollection',
    features: vehicles.map((vehicle) =>
      pointFeature(vehicle.driver_id, vehicle.lat, vehicle.lng, {
        kind: 'presence',
        driver_id: vehicle.driver_id,
        status: vehicle.status,
        mode: vehicle.mode,
        plate: vehicle.plate,
        heading: vehicle.heading,
        speed_mps: vehicle.speed_mps,
        seats_available: vehicle.seats_available,
      })
    ),
  };
}

export function sosToGeoJson(rows: LiveMapSos[]): GeoJSON.FeatureCollection {
  return {
    type: 'FeatureCollection',
    features: rows.map((row) =>
      pointFeature(row.id, row.lat, row.lng, {
        kind: 'sos',
        sos_id: row.id,
        trip_id: row.trip_id,
        status: row.status,
        age_s: row.age_s,
        raiser_name: row.raiser_name,
        rider_name: row.rider_name,
        driver_name: row.driver_name,
        vehicle_plate: row.vehicle_plate,
      })
    ),
  };
}

export function coverageGapsToGeoJson(gaps: LiveMapCoverageGap[]): GeoJSON.FeatureCollection {
  return {
    type: 'FeatureCollection',
    features: gaps.map((gap) =>
      pointFeature(gap.id, gap.lat, gap.lng, {
        kind: 'coverage_gap',
        ambient_vehicle_count: gap.ambient_vehicle_count,
        heat_radius: coverageGapHeatRadius(gap.ambient_vehicle_count),
        heat_opacity: coverageGapHeatOpacity(gap.ambient_vehicle_count),
        nearest_known_stage_distance_m: gap.nearest_known_stage_distance_m,
        searched_at: gap.searched_at,
      })
    ),
  };
}

export function activeTripsToGeoJson(trips: LiveMapActiveTrip[]): GeoJSON.FeatureCollection {
  const features: GeoJSON.Feature[] = [];

  for (const trip of trips) {
    if (trip.rider && trip.driver) {
      features.push({
        type: 'Feature',
        id: trip.trip_id,
        geometry: {
          type: 'LineString',
          coordinates: [
            [trip.rider.lng, trip.rider.lat],
            [trip.driver.lng, trip.driver.lat],
          ],
        },
        properties: {
          kind: 'trip_link',
          trip_id: trip.trip_id,
          status: trip.status,
          na_me_color: trip.na_me_color,
          na_me_shape: trip.na_me_shape,
          rider_name: trip.rider_name,
          driver_name: trip.driver_name,
          plate: trip.plate,
        },
      });
    }
    if (trip.rider) {
      features.push(
        pointFeature(`${trip.trip_id}-rider`, trip.rider.lat, trip.rider.lng, {
          kind: 'trip_rider',
          trip_id: trip.trip_id,
          status: trip.status,
          rider_name: trip.rider_name,
        })
      );
    }
    if (trip.driver) {
      features.push(
        pointFeature(`${trip.trip_id}-driver`, trip.driver.lat, trip.driver.lng, {
          kind: 'trip_driver',
          trip_id: trip.trip_id,
          status: trip.status,
          driver_name: trip.driver_name,
          plate: trip.plate,
        })
      );
    }
  }

  return { type: 'FeatureCollection', features };
}

export function presenceStatusColor(status: string): string {
  if (status === 'at_park') return 'var(--color-mode-car)';
  if (status === 'roaming_available') return 'var(--color-semantic-success-fill)';
  if (status === 'roaming_full') return 'var(--color-semantic-warning-fill)';
  return 'var(--color-ink-500)';
}

export function graphStatusColor(status: string): string {
  if (status === 'field_verified') return 'var(--color-tier-verified)';
  if (status === 'crowd_verified') return 'var(--color-tier-crowd)';
  if (status === 'candidate') return 'var(--color-tier-candidate)';
  return 'var(--color-tier-estimate)';
}

/** Resolve a design-token CSS variable to a MapLibre-compatible color at runtime. */
export function resolveCssToken(token: string): string {
  const trimmed = token.trim();
  const varMatch = /^var\((--[^,)]+)\)$/.exec(trimmed);
  const property = varMatch?.[1] ?? (trimmed.startsWith('--') ? trimmed : null);
  if (property && typeof document !== 'undefined') {
    const resolved = getComputedStyle(document.documentElement).getPropertyValue(property).trim();
    if (resolved) return resolved;
  }
  return trimmed;
}

export function resolvedPresenceStatusColor(status: string): string {
  return resolveCssToken(presenceStatusColor(status));
}

export function resolvedGraphStatusColor(status: string): string {
  return resolveCssToken(graphStatusColor(status));
}

/** MapLibre paint colors resolved from design tokens (FM20). */
export function buildLiveMapPaintColors() {
  return {
    routeFieldVerified: resolvedGraphStatusColor('field_verified'),
    routeCrowdVerified: resolvedGraphStatusColor('crowd_verified'),
    routeCandidate: resolvedGraphStatusColor('candidate'),
    coverageGap: resolveCssToken('--color-semantic-danger-fill'),
    park: resolvedPresenceStatusColor('at_park'),
    stage: resolveCssToken('--color-semantic-info-fill'),
    tripLink: resolveCssToken('--color-mode-minibus'),
    tripRider: resolvedGraphStatusColor('crowd_verified'),
    tripDriver: resolvedPresenceStatusColor('at_park'),
    presenceAtPark: resolvedPresenceStatusColor('at_park'),
    presenceRoamingAvailable: resolvedPresenceStatusColor('roaming_available'),
    presenceRoamingFull: resolvedPresenceStatusColor('roaming_full'),
    presenceDefault: resolvedPresenceStatusColor('offline'),
    sosFill: resolveCssToken('--color-semantic-danger-fill'),
    sosStroke: resolveCssToken('--color-semantic-danger-tint'),
    strokeLight: resolveCssToken('--color-surface-0'),
  };
}
