/// Sample `plan-trip` payload for rider widget tests (P1-B-03).
Map<String, dynamic> samplePlanTripResponse({
  String candidateId = 'cand-direct-1',
  bool includeCoverageGap = false,
}) {
  if (includeCoverageGap) {
    return {
      'data': {
        'query_id': 'query-1',
        'city_id': 'b1000000-0000-4000-8000-000000000001',
        'degraded': false,
        'candidates': [],
        'sort_orders': {
          'recommended': [],
          'cheapest': [],
          'fastest': [],
          'least_strenuous': [],
        },
        'coverage_gap': {
          'report_id': 'report-1',
          'nearest_stage': {
            'stage_id': 'stage-dutse',
            'name': 'Dutse Junction',
            'location': {'lat': 9.05, 'lng': 7.42},
            'distance_m': 1200,
          },
          'ambient_vehicle_count': 0,
        },
      },
    };
  }

  return {
    'data': {
      'query_id': 'query-1',
      'city_id': 'b1000000-0000-4000-8000-000000000001',
      'degraded': false,
      'candidates': [
        {
          'candidate_id': candidateId,
          'kind': 'direct',
          'source': 'parked',
          'viable_direct': true,
          'legs': [
            {
              'leg_index': 0,
              'mode': {
                'code': 'keke',
                'label': 'Keke',
                'icon_key': 'keke',
                'color_token': 'modeKeke',
              },
              'board': {
                'stage_id': 's-lugbe',
                'name': 'Lugbe Park',
                'location': {'lat': 9.01, 'lng': 7.40},
                'walk_m': 240,
                'walk_s': 240,
                'wayfinding_available': true,
              },
              'alight': {
                'stage_id': 's-area1',
                'name': 'Area 1 Park',
                'location': {'lat': 9.05, 'lng': 7.45},
              },
              'route_id': 'route-1',
              'route_leg_ids': ['leg-1'],
              'in_vehicle_s': 900,
              'wait_s': 360,
              'fare': {
                'total': {'amount': '450.00', 'currency': 'NGN'},
                'tier': 1,
                'confidence': 0.95,
                'unconfirmed': false,
                'quote_id': 'quote-1',
                'expires_at': '2026-09-05T16:00:00Z',
              },
              'supply': {'kind': 'parked', 'vehicles_bucket': '1-2'},
              'load_warning': null,
            },
          ],
          'transfers': [],
          'metrics': {
            'total_fare_minor': 45000,
            'total_time_s': 1500,
            'transfer_count': 0,
          },
        },
      ],
      'sort_orders': {
        'recommended': [candidateId],
        'cheapest': [candidateId],
        'fastest': [candidateId],
        'least_strenuous': [candidateId],
      },
      'coverage_gap': null,
    },
  };
}

/// Sample `request_trip` RPC payload.
Map<String, dynamic> sampleRequestTripResponse({
  String tripId = 'trip-1',
  String expiresAt = '2026-09-05T16:05:00Z',
}) =>
    {
      'trip_id': tripId,
      'journey_id': 'journey-1',
      'journey_sequence': 1,
      'status': 'requested',
      'mode': {
        'code': 'keke',
        'label': 'Keke',
        'icon_key': 'keke',
        'color_token': 'modeKeke',
      },
      'rider': {},
      'driver': {},
      'vehicle': {},
      'board': {
        'stage_id': 's-lugbe',
        'name': 'Lugbe Park',
        'location': {'lat': 9.01, 'lng': 7.40},
        'walk_m': 240,
        'walk_s': 240,
        'wayfinding_available': true,
      },
      'alight': {
        'stage_id': 's-area1',
        'name': 'Area 1 Park',
        'location': {'lat': 9.05, 'lng': 7.45},
      },
      'route_leg_ids': ['leg-1'],
      'fare': {
        'total': {'amount': '450.00', 'currency': 'NGN'},
        'tier': 1,
        'confidence': 0.95,
        'unconfirmed': false,
        'components': [],
        'quote_id': 'quote-1',
        'expires_at': expiresAt,
      },
      'load': {'flagged': false},
      'women_only': false,
      'na_me': {
        'color_token': 'green',
        'shape': 'diamond',
        'label': 'Green Diamond',
      },
      'live_channel': 'trip:$tripId',
      'expires_at': expiresAt,
      'timestamps': {},
    };
