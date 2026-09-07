import { describe, expect, it } from 'vitest';
import {
  formatCoordinates,
  graphMapLink,
  parkStatusLabel,
  pendingGeometryRows,
  pendingParkRows,
  pendingRouteRows,
} from './format';
import type { CandidateParkRow, GeometryCorrectionRow, RouteInferenceRow } from './types';

describe('intelligence format helpers', () => {
  it('formats coordinates and graph map links', () => {
    expect(formatCoordinates(11.066, 7.702)).toBe('11.06600, 7.70200');
    expect(graphMapLink('abuja', 9.05, 7.49)).toBe('/abuja/graph?lat=9.05000&lng=7.49000');
  });

  it('labels park and route statuses', () => {
    expect(parkStatusLabel('new')).toBe('Pending');
    expect(parkStatusLabel('promoted_to_stage')).toBe('Promoted');
  });

  it('filters pending queues', () => {
    const parks: CandidateParkRow[] = [
      {
        id: '1',
        status: 'new',
        distinct_driver_count: 5,
        distinct_day_count: 3,
        sample_count: 10,
        first_seen: '',
        last_seen: '',
        lat: 1,
        lng: 2,
        reviewed_at: null,
      },
      {
        id: '2',
        status: 'dismissed',
        distinct_driver_count: 1,
        distinct_day_count: 1,
        sample_count: 1,
        first_seen: '',
        last_seen: '',
        lat: 1,
        lng: 2,
        reviewed_at: null,
      },
    ];
    expect(pendingParkRows(parks)).toHaveLength(1);

    const routes: RouteInferenceRow[] = [
      {
        id: 'r1',
        status: 'new',
        mode_code: 'car',
        supporting_trip_count: 20,
        created_at: '',
        origin_lat: 1,
        origin_lng: 2,
        destination_lat: 3,
        destination_lng: 4,
        route_id: null,
        reviewed_at: null,
      },
    ];
    expect(pendingRouteRows(routes)).toHaveLength(1);

    const geometry: GeometryCorrectionRow[] = [
      {
        id: 'g1',
        status: 'candidate',
        supporting_trace_count: 15,
        created_at: '',
        reviewed_at: null,
      },
      {
        id: 'g2',
        status: 'rejected',
        supporting_trace_count: 5,
        created_at: '',
        reviewed_at: null,
      },
    ];
    expect(pendingGeometryRows(geometry)).toHaveLength(1);
  });
});
