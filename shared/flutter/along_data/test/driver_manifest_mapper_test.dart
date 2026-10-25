import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_data/src/mappers/domain_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('driver manifest mapper', () {
    test('manifestEntryFromJson parses driver_manifest row', () {
      final entry = DomainMappers.manifestEntryFromJson({
        'trip_id': 'trip-1',
        'status': 'accepted',
        'journey_sequence': 2,
        'rider': {
          'display_name': 'Ada',
          'rating': 4.5,
          'trip_count': 3,
        },
        'board': {
          'stage_id': 's1',
          'name': 'Lugbe Park',
          'location': {'lat': 9.0, 'lng': 7.0},
        },
        'na_me': {
          'color_token': 'green',
          'shape': 'diamond',
          'label': 'Green Diamond',
        },
        'expires_at': '2026-09-05T14:00:00Z',
      });

      expect(entry.tripId, 'trip-1');
      expect(entry.status, TripStatus.accepted);
      expect(entry.rider.displayName, 'Ada');
      expect(entry.board.name, 'Lugbe Park');
      expect(entry.naMe.label, 'Green Diamond');
      expect(entry.canMarkBoarded, isTrue);
    });

    test('completeTripFromJson parses trip + fare lines', () {
      final result = DomainMappers.completeTripFromJson({
        'trip': {
          'trip_id': 'trip-1',
          'journey_id': 'j1',
          'journey_sequence': 1,
          'status': 'completed',
          'mode': {
            'code': 'car',
            'label': 'Car',
            'icon_key': 'car',
            'color_token': 'mode.car',
          },
          'rider': {'display_name': 'Ada', 'rating': 0, 'trip_count': 0},
          'driver': <String, dynamic>{},
          'vehicle': <String, dynamic>{},
          'board': {
            'stage_id': 's1',
            'name': 'Lugbe',
            'location': {'lat': 9, 'lng': 7},
            'walk_m': 0,
            'walk_s': 0,
            'wayfinding_available': true,
          },
          'alight': {
            'stage_id': 's2',
            'name': 'Area 1',
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
          'load': {'flagged': false, 'size': 'none'},
          'women_only': false,
          'na_me': {
            'color_token': 'green',
            'shape': 'diamond',
            'label': 'Green Diamond',
          },
          'live_channel': 'trip:trip-1',
          'expires_at': '2026-09-05T14:00:00Z',
          'timestamps': <String, dynamic>{},
        },
        'commission': {'amount': '34.00', 'currency': 'NGN'},
        'fare': {'amount': '450.00', 'currency': 'NGN'},
      });

      expect(result.trip.status, TripStatus.completed);
      expect(result.commission.minorUnits, 3400);
      expect(result.fare.minorUnits, 45000);
    });
  });
}
