import { describe, expect, it } from 'vitest';
import {
  applyLiveMapFilters,
  coverageGapHeatOpacity,
  coverageGapHeatRadius,
  DEFAULT_LAYER_VISIBILITY,
  filterRoutes,
  visibleLayerCount,
} from './filters';
import type {
  LiveMapActiveTrip,
  LiveMapPark,
  LiveMapRoute,
  LiveMapStage,
} from './types';

const parks: LiveMapPark[] = [
  {
    id: 'p1',
    name: 'Alpha',
    lat: 11,
    lng: 7,
    verification_status: 'field_verified',
  },
  {
    id: 'p2',
    name: 'Beta',
    lat: 11.1,
    lng: 7.1,
    verification_status: 'candidate',
  },
];

const stages: LiveMapStage[] = [
  {
    id: 's1',
    route_id: 'r1',
    name: 'Stop',
    lat: 11,
    lng: 7,
    verification_status: 'field_verified',
    is_official_park: true,
    sequence: 1,
  },
];

const routes: LiveMapRoute[] = [
  {
    id: 'r1',
    mode_code: 'car',
    verification_status: 'field_verified',
    coordinates: [
      [7, 11],
      [7.1, 11.1],
    ],
  },
  {
    id: 'r2',
    mode_code: 'keke',
    verification_status: 'candidate',
    coordinates: [
      [7.2, 11.2],
      [7.3, 11.3],
    ],
  },
];

describe('live map filters', () => {
  it('filters verified vs candidate routes', () => {
    expect(filterRoutes(routes, true, false).map((r) => r.id)).toEqual(['r1']);
    expect(filterRoutes(routes, false, true).map((r) => r.id)).toEqual(['r2']);
  });

  it('hides layers when toggled off', () => {
    const visibility = { ...DEFAULT_LAYER_VISIBILITY, presence: false, sos: false };
    const result = applyLiveMapFilters({
      parks,
      stages,
      routes,
      presence: [
        {
          driver_id: 'd1',
          lat: 11,
          lng: 7,
          heading: null,
          speed_mps: 0,
          status: 'at_park',
          mode: 'car',
          plate: 'ABC',
          seats_available: 3,
        },
      ],
      trips: [],
      sos: [
        {
          id: 'sos1',
          trip_id: null,
          status: 'open',
          lat: 11,
          lng: 7,
          age_s: 10,
          raiser_name: null,
          rider_name: null,
          driver_name: null,
          vehicle_plate: null,
        },
      ],
      coverageGaps: [],
      visibility,
      routeFilters: { showVerified: true, showCandidate: true },
    });

    expect(result.presence).toHaveLength(0);
    expect(result.sos).toHaveLength(0);
    expect(result.parks).toHaveLength(2);
  });

  it('keeps active trips only when both endpoints exist for links', () => {
    const trips: LiveMapActiveTrip[] = [
      {
        trip_id: 't1',
        status: 'in_transit',
        na_me_color: 'red',
        na_me_shape: 'circle',
        rider_id: 'r1',
        driver_id: 'd1',
        rider_name: 'R',
        driver_name: 'D',
        plate: 'PLATE',
        rider: { lat: 11, lng: 7 },
        driver: { lat: 11.01, lng: 7.01 },
      },
      {
        trip_id: 't2',
        status: 'accepted',
        na_me_color: 'blue',
        na_me_shape: 'square',
        rider_id: 'r2',
        driver_id: 'd2',
        rider_name: null,
        driver_name: null,
        plate: null,
        rider: null,
        driver: { lat: 11.02, lng: 7.02 },
      },
    ];

    const result = applyLiveMapFilters({
      parks: [],
      stages: [],
      routes: [],
      presence: [],
      trips,
      sos: [],
      coverageGaps: [],
      visibility: DEFAULT_LAYER_VISIBILITY,
      routeFilters: { showVerified: true, showCandidate: true },
    });

    expect(result.trips.map((t) => t.trip_id)).toEqual(['t1', 't2']);
  });

  it('scales coverage gap heat by ambient count', () => {
    expect(coverageGapHeatRadius(0)).toBe(12);
    expect(coverageGapHeatRadius(10)).toBe(48);
    expect(coverageGapHeatOpacity(0)).toBeCloseTo(0.18);
    expect(coverageGapHeatOpacity(10)).toBeCloseTo(0.72);
  });

  it('counts visible layers', () => {
    expect(visibleLayerCount(DEFAULT_LAYER_VISIBILITY)).toBe(7);
    expect(
      visibleLayerCount({ ...DEFAULT_LAYER_VISIBILITY, routes: false, parks: false })
    ).toBe(5);
  });
});
