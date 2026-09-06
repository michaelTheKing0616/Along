/// Fixtures for R-16 pricing widget tests (P2-B-02).
Map<String, dynamic> sampleOpenNegotiationResponse({
  String negotiationId = 'neg-1',
  String context = 'park',
  String anchor = '600.00',
  String etaBand = 'full',
  int roundCap = 4,
  int roundTimeoutS = 20,
  String expiresAt = '2026-09-05T16:01:00Z',
  List<String> chipSteps = const ['100.00', '50.00', '50.00', '100.00'],
}) =>
    {
      'negotiation_id': negotiationId,
      'anchor': {'amount': anchor, 'currency': 'NGN'},
      'chip_steps': [
        for (final step in chipSteps) {'amount': step, 'currency': 'NGN'},
      ],
      'round_cap': roundCap,
      'round_timeout_s': roundTimeoutS,
      'eta_band': etaBand,
      'expires_at': expiresAt,
    };

Map<String, dynamic> sampleNegotiationView({
  String negotiationId = 'neg-1',
  String status = 'open',
  String context = 'park',
  String anchor = '600.00',
  String amount = '600.00',
  String proposedBy = 'rider',
  String? etaBand = 'full',
  int roundCap = 4,
  int round = 1,
  int roundTimeoutS = 20,
  String expiresAt = '2026-09-05T16:01:00Z',
  List<String> chipSteps = const ['100.00', '50.00', '50.00', '100.00'],
  Map<String, dynamic>? trip,
}) =>
    {
      'negotiation_id': negotiationId,
      'status': status,
      'context': context,
      'anchor': {'amount': anchor, 'currency': 'NGN'},
      'agreed_amount': null,
      'round_cap': roundCap,
      'round_timeout_s': roundTimeoutS,
      'eta_band': etaBand,
      'expires_at': expiresAt,
      'round': round,
      'amount': {'amount': amount, 'currency': 'NGN'},
      'proposed_by': proposedBy,
      'chip_steps': [
        for (final step in chipSteps) {'amount': step, 'currency': 'NGN'},
      ],
      'trip': trip,
    };

Map<String, dynamic> sampleTier3PlanTripResponse() => {
      'data': {
        'query_id': 'query-tier3',
        'city_id': 'b1000000-0000-4000-8000-000000000001',
        'degraded': false,
        'candidates': [
          {
            'candidate_id': 'cand-tier3',
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
                  'total': {'amount': '600.00', 'currency': 'NGN'},
                  'tier': 3,
                  'confidence': 0.4,
                  'unconfirmed': true,
                  'quote_id': 'quote-tier3',
                  'expires_at': '2026-09-05T16:00:00Z',
                },
                'supply': {'kind': 'parked', 'vehicles_bucket': '1-2'},
                'load_warning': null,
              },
            ],
            'transfers': [],
            'metrics': {
              'total_fare_minor': 60000,
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
          'recommended': ['cand-tier3'],
          'cheapest': ['cand-tier3'],
          'fastest': ['cand-tier3'],
          'least_strenuous': ['cand-tier3'],
        },
        'coverage_gap': null,
      },
    };

List<Map<String, dynamic>> defaultNegotiationConfigRows() => [
      {
        'key': 'negotiation.park.round_cap',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '4',
      },
      {
        'key': 'negotiation.park.round_timeout_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '20',
      },
      {
        'key': 'negotiation.roaming.eta_none_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '20',
      },
      {
        'key': 'negotiation.roaming.eta_single_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '60',
      },
      {
        'key': 'negotiation.roaming.round_timeout_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '12',
      },
      {
        'key': 'negotiation.roaming.round_cap',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '3',
      },
      {
        'key': 'negotiation.chip_steps',
        'scope_type': 'global',
        'scope_id': '*',
        'value': [-100, -50, 50, 100],
      },
    ];
