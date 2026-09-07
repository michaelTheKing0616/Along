import type {
  GraphVerificationStatus,
  LiveMapActiveTrip,
  LiveMapCoverageGap,
  LiveMapLayerId,
  LiveMapLayerVisibility,
  LiveMapPark,
  LiveMapPresenceVehicle,
  LiveMapRoute,
  LiveMapSos,
  LiveMapStage,
} from './types';

export const DEFAULT_LAYER_VISIBILITY: LiveMapLayerVisibility = {
  routes: true,
  parks: true,
  stages: true,
  presence: true,
  trips: true,
  sos: true,
  coverageGaps: true,
};

export function isVerifiedGraphStatus(status: GraphVerificationStatus): boolean {
  return status === 'field_verified' || status === 'crowd_verified';
}

export function filterRoutes(
  routes: LiveMapRoute[],
  showVerified: boolean,
  showCandidate: boolean
): LiveMapRoute[] {
  return routes.filter((route) => {
    const verified = isVerifiedGraphStatus(route.verification_status);
    if (verified && showVerified) return true;
    if (!verified && showCandidate) return true;
    return false;
  });
}

export function filterGraphPoints<T extends { verification_status: GraphVerificationStatus }>(
  items: T[],
  showVerified: boolean,
  showCandidate: boolean
): T[] {
  return items.filter((item) => {
    const verified = isVerifiedGraphStatus(item.verification_status);
    if (verified && showVerified) return true;
    if (!verified && showCandidate) return true;
    return false;
  });
}

export function filterByLayer<T>(
  layer: LiveMapLayerId,
  visibility: LiveMapLayerVisibility,
  items: T[]
): T[] {
  return visibility[layer] ? items : [];
}

export function filterActiveTripsWithLinks(trips: LiveMapActiveTrip[]): LiveMapActiveTrip[] {
  return trips.filter((trip) => trip.driver != null && (trip.rider != null || trip.driver != null));
}

export function coverageGapHeatRadius(count: number): number {
  return Math.min(48, 12 + count * 6);
}

export function coverageGapHeatOpacity(count: number): number {
  return Math.min(0.72, 0.18 + count * 0.08);
}

export function visibleLayerCount(visibility: LiveMapLayerVisibility): number {
  return Object.values(visibility).filter(Boolean).length;
}

export type RouteFilterState = { showVerified: boolean; showCandidate: boolean };

export function applyLiveMapFilters(input: {
  parks: LiveMapPark[];
  stages: LiveMapStage[];
  routes: LiveMapRoute[];
  presence: LiveMapPresenceVehicle[];
  trips: LiveMapActiveTrip[];
  sos: LiveMapSos[];
  coverageGaps: LiveMapCoverageGap[];
  visibility: LiveMapLayerVisibility;
  routeFilters: RouteFilterState;
}) {
  const parks = filterByLayer(
    'parks',
    input.visibility,
    filterGraphPoints(input.parks, input.routeFilters.showVerified, input.routeFilters.showCandidate)
  );
  const stages = filterByLayer(
    'stages',
    input.visibility,
    filterGraphPoints(input.stages, input.routeFilters.showVerified, input.routeFilters.showCandidate)
  );
  const routes = filterByLayer(
    'routes',
    input.visibility,
    filterRoutes(input.routes, input.routeFilters.showVerified, input.routeFilters.showCandidate)
  );
  const presence = filterByLayer('presence', input.visibility, input.presence);
  const trips = filterByLayer(
    'trips',
    input.visibility,
    filterActiveTripsWithLinks(input.trips)
  );
  const sos = filterByLayer('sos', input.visibility, input.sos);
  const coverageGaps = filterByLayer('coverageGaps', input.visibility, input.coverageGaps);

  return { parks, stages, routes, presence, trips, sos, coverageGaps };
}
