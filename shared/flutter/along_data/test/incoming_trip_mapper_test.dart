import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('incomingTripFromEnvelope prefers envelope expires_at', () {
    final summary = DomainMappers.incomingTripFromEnvelope({
      'type': 'trip_request',
      'expires_at': '2026-09-05T14:00:00Z',
      'trip': {
        'trip_id': 't1',
        'journey_id': 'j1',
        'journey_sequence': 1,
        'status': 'requested',
        'mode': {
          'code': 'car',
          'label': 'Car',
          'icon_key': 'car',
          'color_token': 'mode.car',
        },
        'rider': {
          'display_name': 'Ada',
          'rating': 4.8,
          'trip_count': 12,
        },
        'driver': <String, dynamic>{},
        'vehicle': <String, dynamic>{},
        'board': {
          'stage_id': 's1',
          'name': 'Lugbe Park',
          'location': {'lat': 9.0, 'lng': 7.0},
          'walk_m': 400,
          'walk_s': 300,
          'wayfinding_available': true,
        },
        'alight': {
          'stage_id': 's2',
          'name': 'Area 1 Park',
          'location': {'lat': 9.1, 'lng': 7.1},
        },
        'route_leg_ids': <dynamic>[],
        'fare': {
          'total': {'amount': '450.00', 'currency': 'NGN'},
          'tier': 1,
          'confidence': 1,
          'unconfirmed': false,
          'components': <dynamic>[],
          'quote_id': 'q1',
          'expires_at': '2026-09-05T13:00:00Z',
        },
        'load': {
          'flagged': true,
          'size': 'Medium',
          'note': '1 bag, needs boot',
        },
        'women_only': false,
        'na_me': {
          'color_token': 'green',
          'shape': 'diamond',
          'label': 'Green Diamond',
        },
        'live_channel': 'trip:t1',
        'expires_at': '2026-09-05T13:30:00Z',
        'timestamps': <String, dynamic>{},
      },
    });

    expect(summary.tripId, 't1');
    expect(summary.rider.displayName, 'Ada');
    expect(summary.load.flagged, isTrue);
    expect(summary.expiresAt, DateTime.parse('2026-09-05T14:00:00Z'));
  });
}
