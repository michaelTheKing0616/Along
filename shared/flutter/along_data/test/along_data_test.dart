import 'package:along_core/along_core.dart' hide Money;
import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_along_supabase.dart';

void main() {
  group('DomainMappers', () {
    test('maps TripView DTO to TripSummary', () {
      final view = TripView(
        trip_id: 't1',
        journey_id: 'j1',
        journey_sequence: 1,
        status: 'accepted',
        mode: const ModeRef(
          code: 'car',
          label: 'Car',
          icon_key: 'car',
          color_token: 'mode.car',
        ),
        rider: const {},
        driver: const {},
        vehicle: const {},
        board: BoardStop(
          stage_id: 's1',
          name: 'Park A',
          location: const Point(lat: 9.0, lng: 7.0),
          walk_m: 100,
          walk_s: 120,
          wayfinding_available: true,
        ),
        alight: StageLocation(
          stage_id: 's2',
          name: 'Park B',
          location: const Point(lat: 9.1, lng: 7.1),
        ),
        route_leg_ids: const ['leg1'],
        fare: Fare(
          total: const Money(amount: '450.00', currency: 'NGN'),
          tier: 1,
          confidence: 0.9,
          unconfirmed: false,
          components: const [],
          quote_id: 'q1',
          expires_at: '2026-09-04T12:00:00Z',
        ),
        load: const LoadFlag(flagged: false, size: 'none'),
        women_only: false,
        na_me: const {
          'color_token': 'green',
          'shape': 'diamond',
          'label': 'Green Diamond',
        },
        live_channel: 'trip:t1',
        expires_at: '2026-09-04T12:15:00Z',
        timestamps: const {},
      );

      final summary = DomainMappers.tripFromDto(view);
      expect(summary.tripId, 't1');
      expect(summary.status, TripStatus.accepted);
      expect(summary.naMe.label, 'Green Diamond');
      expect(summary.fare.total.minorUnits, 45000);
    });
  });

  group('TripsRepository', () {
    test('requestTrip calls RPC and caches trip', () async {
      final fake = FakeAlongSupabase(
        rpcHandler: (fn, params) {
          expect(fn, 'request_trip');
          return {
            'trip_id': 't1',
            'journey_id': 'j1',
            'journey_sequence': 1,
            'status': 'requested',
            'mode': {
              'code': 'keke',
              'label': 'Keke',
              'icon_key': 'keke',
              'color_token': 'mode.keke',
            },
            'rider': {},
            'driver': {},
            'vehicle': {},
            'board': {
              'stage_id': 's1',
              'name': 'A',
              'location': {'lat': 1, 'lng': 2},
              'walk_m': 0,
              'walk_s': 0,
              'wayfinding_available': false,
            },
            'alight': {
              'stage_id': 's2',
              'name': 'B',
              'location': {'lat': 3, 'lng': 4},
            },
            'route_leg_ids': [],
            'fare': {
              'total': {'amount': '300.00', 'currency': 'NGN'},
              'tier': 2,
              'confidence': 0.8,
              'unconfirmed': false,
              'components': [],
              'quote_id': 'q2',
              'expires_at': '2026-09-04T12:00:00Z',
            },
            'load': {'flagged': false, 'size': 'none'},
            'women_only': false,
            'na_me': {
              'color_token': 'blue',
              'shape': 'circle',
              'label': 'Blue Circle',
            },
            'live_channel': 'trip:t1',
            'expires_at': '2026-09-04T12:10:00Z',
            'timestamps': {},
          };
        },
      );
      final db = AlongDatabase.memory();
      final repo = TripsRepository(fake, db);

      final summary = await repo.requestTrip(
        const RequestTripRequest(
          p_candidate_id: 'cand1',
          p_leg_index: 0,
          p_client_ref: 'ref1',
          p_women_only: false,
        ),
      );

      expect(summary.tripId, 't1');
      expect(fake.rpcCalls.single.$1, 'request_trip');
      final cached = await repo.cachedActiveTrip();
      expect(cached?.tripId, 't1');
    });
  });

  group('PlannerRepository', () {
    test('planTrip maps candidates and sort orders', () async {
      final fake = FakeAlongSupabase(
        functionHandler: (slug, body) => {
          'data': {
            'query_id': 'q1',
            'city_id': 'city1',
            'degraded': false,
            'candidates': [
              {
                'candidate_id': 'c1',
                'kind': 'direct',
                'source': 'parked',
                'viable_direct': true,
                'legs': [
                  {
                    'leg_index': 0,
                    'mode': {
                      'code': 'car',
                      'label': 'Car',
                      'icon_key': 'car',
                      'color_token': 'mode.car',
                    },
                    'board': {'name': 'A'},
                    'alight': {'name': 'B'},
                    'in_vehicle_s': 600,
                    'wait_s': 60,
                    'fare': {
                      'total': {'amount': '500.00', 'currency': 'NGN'},
                      'tier': 1,
                      'confidence': 1,
                      'unconfirmed': false,
                      'components': [],
                      'quote_id': 'fq1',
                      'expires_at': '2026-09-04T12:00:00Z',
                    },
                  },
                ],
                'metrics': {
                  'total_fare_minor': 50000,
                  'total_time_s': 660,
                  'transfer_count': 0,
                },
              },
            ],
            'sort_orders': {
              'recommended': ['c1'],
              'cheapest': ['c1'],
            },
          },
        },
      );

      final repo = PlannerRepository(fake);
      final result = await repo.planTrip(requestBody: {'origin': {}});

      expect(result.candidates, hasLength(1));
      expect(result.candidates.first.kind, 'direct');
      expect(result.sortOrders[SortCriterion.recommended], ['c1']);
      expect(fake.functionCalls.single.$1, 'plan-trip');
    });
  });

  group('PresenceRepository', () {
    test('setPresence forwards RPC params', () async {
      final fake = FakeAlongSupabase(rpcHandler: (_, __) => {});
      final repo = PresenceRepository(fake);

      await repo.setPresence(
        const SetPresenceRequest(
          p_status: 'at_park',
          p_location: Point(lat: 9, lng: 7),
          p_seats_available: 4,
        ),
      );

      expect(fake.rpcCalls.single.$1, 'set_presence');
    });
  });

  group('PendingActionQueue', () {
    test('replays FIFO and removes successful actions', () async {
      final db = AlongDatabase.memory();
      var now = DateTime.utc(2026, 9, 4, 10);
      final queue = PendingActionQueue(
        db,
        clock: _SteppingClock(() => now, () => now = now.add(const Duration(seconds: 1))),
      );

      await queue.enqueue(
        id: 'a1',
        type: 'rate_trip',
        payload: {'p_client_ref': 'ref1'},
      );
      await queue.enqueue(
        id: 'a2',
        type: 'confirm_fare',
        payload: {'p_client_ref': 'ref2'},
      );

      final processed = <String>[];
      final count = await queue.replay((action) async {
        processed.add(action.id);
      });

      expect(count, 2);
      expect(processed, ['a1', 'a2']);
      expect(await queue.pendingFifo(), isEmpty);
    });

    test('retains failed actions and increments attempts', () async {
      final db = AlongDatabase.memory();
      final queue = PendingActionQueue(db, clock: Clock.fixed(DateTime.utc(2026, 9, 4)));

      await queue.enqueue(
        id: 'fail1',
        type: 'submit_correction',
        payload: {'p_client_ref': 'ref'},
      );

      await queue.replay((_) async {
        throw Exception('network');
      });

      final pending = await queue.pendingFifo();
      expect(pending, hasLength(1));
      expect(pending.first.attempts, 1);
    });
  });
}

class _SteppingClock implements Clock {
  _SteppingClock(this._read, this._advance);

  final DateTime Function() _read;
  final void Function() _advance;

  @override
  DateTime now() {
    final value = _read();
    _advance();
    return value;
  }
}
