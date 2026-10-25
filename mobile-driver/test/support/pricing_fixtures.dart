import 'package:along_data/along_data.dart';

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
      'trip': null,
    };

NegotiationView sampleNegotiationViewModel({
  String context = 'roaming',
  String? etaBand = 'single',
}) =>
    NegotiationView.fromJson(sampleNegotiationView(context: context, etaBand: etaBand));

Map<String, dynamic> sampleRoamingTripRequestEnvelope({
  String tripId = 'trip-roam-1',
  int dispatchAttempt = 1,
  bool unconfirmedFare = false,
  String riderPhone = '+2348000000000',
}) {
  return {
    'type': 'trip_request',
    'dispatch_attempt': dispatchAttempt,
    'expires_at': '2026-09-05T14:00:00Z',
    'trip': {
      'trip_id': tripId,
      'journey_id': 'j1',
      'journey_sequence': 1,
      'status': 'requested',
      'mode': {
        'code': 'keke',
        'label': 'Keke',
        'icon_key': 'keke',
        'color_token': 'mode.keke',
      },
      'rider': {
        'display_name': 'Ada',
        'rating': 4.8,
        'trip_count': 12,
        'phone': riderPhone,
      },
      'driver': {
        'display_name': 'Driver',
        'rating': 0,
        'trips_completed': 0,
      },
      'vehicle': {
        'plate_number': '',
        'color': '',
        'make_model': '',
        'seat_capacity': 0,
      },
      'board': {
        'stage_id': '',
        'name': 'Pickup',
        'location': {'lat': 9.05, 'lng': 7.49},
        'walk_m': 0,
        'walk_s': 0,
        'wayfinding_available': false,
      },
      'alight': {
        'stage_id': '',
        'name': 'Drop-off',
        'location': {'lat': 9.1, 'lng': 7.5},
      },
      'route_leg_ids': <dynamic>[],
      'fare': {
        'total': {'amount': '450.00', 'currency': 'NGN'},
        'tier': 3,
        'confidence': 0,
        'unconfirmed': unconfirmedFare,
        'components': <dynamic>[],
        'quote_id': 'q-roam',
        'expires_at': '2026-09-05T13:00:00Z',
      },
      'load': {'flagged': false, 'size': 'none', 'note': null},
      'women_only': false,
      'na_me': {
        'color_token': 'green',
        'shape': 'diamond',
        'label': 'Green Diamond',
      },
      'live_channel': 'trip:$tripId',
      'expires_at': '2026-09-05T14:00:00Z',
      'dispatch_attempt': dispatchAttempt,
      'is_roaming_hail': true,
      'timestamps': <String, dynamic>{},
    },
  };
}
