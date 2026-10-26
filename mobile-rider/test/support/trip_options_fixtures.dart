import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';

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
            'total_walking_distance_m': 240,
            'strenuousness_score': 0.2,
            'recommended_score': 1.0,
            'explain': {'fare': 0.4, 'time': 0.4, 'strenuous': 0.2},
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

/// Multi-leg `plan-trip` payload for P2-B-01 widget tests.
Map<String, dynamic> sampleMultiLegPlanTripResponse({
  String candidateId = 'cand-multi-1',
}) {
  return {
    'data': {
      'query_id': 'query-multi',
      'city_id': 'b1000000-0000-4000-8000-000000000001',
      'degraded': false,
      'candidates': [
        {
          'candidate_id': 'cand-direct-slow',
          'kind': 'direct',
          'source': 'parked',
          'viable_direct': false,
          'legs': [
            _leg(
              legIndex: 0,
              mode: 'car',
              board: 'Lugbe Park',
              alight: 'Area 1 Park',
              fare: '900.00',
            ),
          ],
          'transfers': [],
          'metrics': _metrics(fareMinor: 90000, timeS: 3600, transfers: 0),
        },
        {
          'candidate_id': candidateId,
          'kind': 'multi_leg',
          'source': 'graph',
          'viable_direct': true,
          'legs': [
            _leg(
              legIndex: 0,
              mode: 'car',
              board: 'Lugbe Park',
              alight: 'Berger Park',
              fare: '320.00',
            ),
            _leg(
              legIndex: 1,
              mode: 'keke',
              board: 'Berger Park',
              alight: 'Area 1 Park',
              fare: '80.00',
            ),
          ],
          'transfers': [
            {
              'park_name': 'Berger Park',
              'walk_m': 180,
              'transfer_s': 180,
            },
          ],
          'metrics': _metrics(
            fareMinor: 40000,
            timeS: 1800,
            transfers: 1,
            explain: {'fare': 0.5, 'time': 0.3, 'strenuous': 0.2},
          ),
        },
      ],
      'sort_orders': {
        'recommended': [candidateId],
        'cheapest': [candidateId, 'cand-direct-slow'],
        'fastest': ['cand-direct-slow', candidateId],
        'least_strenuous': [candidateId, 'cand-direct-slow'],
      },
      'coverage_gap': null,
    },
  };
}

Map<String, dynamic> _leg({
  required int legIndex,
  required String mode,
  required String board,
  required String alight,
  required String fare,
}) =>
    {
      'leg_index': legIndex,
      'mode': {
        'code': mode,
        'label': mode,
        'icon_key': mode,
        'color_token': 'modeKeke',
      },
      'board': {
        'stage_id': 's-$board',
        'name': board,
        'location': {'lat': 9.01, 'lng': 7.40},
        'walk_m': 240,
        'walk_s': 240,
        'wayfinding_available': true,
      },
      'alight': {
        'stage_id': 's-$alight',
        'name': alight,
        'location': {'lat': 9.05, 'lng': 7.45},
      },
      'route_id': 'route-$legIndex',
      'route_leg_ids': ['leg-$legIndex'],
      'in_vehicle_s': 600,
      'wait_s': 120,
      'fare': {
        'total': {'amount': fare, 'currency': 'NGN'},
        'tier': 1,
        'confidence': 0.95,
        'unconfirmed': false,
        'quote_id': 'quote-$legIndex',
        'expires_at': '2026-09-05T16:00:00Z',
      },
      'supply': {'kind': 'parked', 'vehicles_bucket': '2-3'},
      'load_warning': null,
    };

Map<String, dynamic> _metrics({
  required int fareMinor,
  required int timeS,
  required int transfers,
  Map<String, double>? explain,
}) =>
    {
      'total_fare_minor': fareMinor,
      'total_time_s': timeS,
      'transfer_count': transfers,
      'total_walking_distance_m': 420,
      'strenuousness_score': 0.35,
      'recommended_score': 1.0,
      'explain': explain ?? {'fare': 0.4, 'time': 0.4, 'strenuous': 0.2},
    };

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

/// Sample accepted trip with live driver position (P3-B-01).
Map<String, dynamic> sampleAcceptedTripResponse({
  String tripId = 'trip-accepted-1',
  String status = 'accepted',
  int? heading,
  DateTime? liveAsOf,
}) {
  final asOf = (liveAsOf ?? DateTime.utc(2026, 9, 5, 15, 0)).toIso8601String();
  return {
    ...sampleRequestTripResponse(tripId: tripId),
    'status': status,
    'driver': {
      'display_name': 'Musa',
      'rating': 4.8,
      'trips_completed': 320,
      'driver_code': 'TEST0301',
    },
    'vehicle': {
      'plate_number': 'ABC-123-XY',
      'color': 'Silver',
      'make_model': 'Toyota Corolla',
      'seat_capacity': 4,
    },
    'extension': {'eta_minutes': 2},
    'live': {
      'as_of': asOf,
      'driver': {
        'lat': 9.012,
        'lng': 7.401,
        'heading': heading ?? 45,
        'speed_mps': 8.5,
        'ts': asOf,
      },
    },
  };
}

/// Trip snapshot with a driver-initiated pending extension (TripView.extension).
Map<String, dynamic> sampleTripWithPendingExtension({
  String tripId = 'trip-accepted-1',
}) {
  return {
    ...sampleAcceptedTripResponse(tripId: tripId, status: 'in_transit'),
    'extension': {
      'extension_id': 'ext-view-1',
      'status': 'proposed',
      'proposed_by': 'driver',
      'destination_name': 'Wuse Market',
      'fare_delta': {'amount': '150.00', 'currency': 'NGN'},
    },
  };
}

/// Builds a [TripSummary] from fixture JSON for widget tests.
TripSummary tripSummaryFromFixture(Map<String, dynamic> json) {
  final view = TripView.fromJson(json);
  return DomainMappers.tripFromDto(view, raw: json);
}

/// Three direct options for one trip: keke (recommended), danfo bus
/// (cheapest) and a shared car (fastest), so sort chips and cards render.
Map<String, dynamic> sampleThreeOptionPlanTripResponse() {
  Map<String, dynamic> option({
    required String id,
    required String mode,
    required String label,
    required String board,
    required int fareMinor,
    required int walkS,
    required int waitS,
    required int rideS,
    required int tier,
    required double score,
  }) {
    final base = samplePlanTripResponse(candidateId: id);
    final candidate =
        ((base['data'] as Map)['candidates'] as List).first
            as Map<String, dynamic>;
    final leg = (candidate['legs'] as List).first as Map<String, dynamic>;
    leg['mode'] = {
      'code': mode,
      'label': label,
      'icon_key': mode,
      'color_token': 'modeKeke',
    };
    (leg['board'] as Map)['name'] = board;
    (leg['board'] as Map)['walk_s'] = walkS;
    leg['wait_s'] = waitS;
    leg['in_vehicle_s'] = rideS;
    final fare = leg['fare'] as Map;
    fare['total'] = {
      'amount': (fareMinor / 100).toStringAsFixed(2),
      'currency': 'NGN',
    };
    fare['tier'] = tier;
    final metrics = candidate['metrics'] as Map;
    metrics['total_fare_minor'] = fareMinor;
    metrics['total_time_s'] = walkS + waitS + rideS;
    metrics['recommended_score'] = score;
    return candidate;
  }

  final keke = option(
    id: 'cand-keke',
    mode: 'keke',
    label: 'Keke',
    board: 'Lugbe Park',
    fareMinor: 45000,
    walkS: 240,
    waitS: 360,
    rideS: 900,
    tier: 1,
    score: 1.0,
  );
  final bus = option(
    id: 'cand-bus',
    mode: 'minibus',
    label: 'Danfo',
    board: 'Lugbe Junction',
    fareMinor: 30000,
    walkS: 480,
    waitS: 600,
    rideS: 1200,
    tier: 2,
    score: 0.8,
  );
  final shared = option(
    id: 'cand-shared',
    mode: 'car',
    label: 'Shared car',
    board: 'Lugbe Park',
    fareMinor: 80000,
    walkS: 240,
    waitS: 120,
    rideS: 720,
    tier: 1,
    score: 0.7,
  );
  return {
    'data': {
      'query_id': 'query-3',
      'city_id': 'b1000000-0000-4000-8000-000000000001',
      'degraded': false,
      'candidates': [keke, bus, shared],
      'sort_orders': {
        'recommended': ['cand-keke', 'cand-bus', 'cand-shared'],
        'cheapest': ['cand-bus', 'cand-keke', 'cand-shared'],
        'fastest': ['cand-shared', 'cand-keke', 'cand-bus'],
        'least_strenuous': ['cand-shared', 'cand-keke', 'cand-bus'],
      },
      'coverage_gap': null,
    },
  };
}
