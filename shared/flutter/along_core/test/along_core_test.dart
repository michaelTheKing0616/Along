import 'dart:math';

import 'package:along_core/along_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('parses API string and rounds to minor units', () {
      final money = Money.parse('450.50', currency: 'NGN');
      expect(money.minorUnits, 45050);
      expect(money.toApiString(), '450.50');
    });

    test('adds same-currency amounts', () {
      final a = Money.parse('100.00', currency: 'NGN');
      final b = Money.parse('50.25', currency: 'NGN');
      expect((a + b).toApiString(), '150.25');
    });

    test('rejects currency mismatch', () {
      final a = Money.parse('1', currency: 'NGN');
      final b = Money.parse('1', currency: 'USD');
      expect(() => a + b, throwsArgumentError);
    });
  });

  group('formatMoney', () {
    test('formats NGN with naira symbol', () {
      final formatted = formatMoney(Money.parse('450', currency: 'NGN'));
      expect(formatted, contains('450'));
      expect(formatted, contains('₦'));
    });
  });

  group('formatMoneySpoken', () {
    test('speaks whole naira in English', () {
      expect(
        formatMoneySpoken(Money.parse('450', currency: 'NGN')),
        'four hundred fifty naira',
      );
    });
  });

  group('formatDuration', () {
    test('formats minutes and hours', () {
      expect(formatDuration(const Duration(minutes: 14)), '14 min');
      expect(formatDuration(const Duration(hours: 1, minutes: 5)), '1 hr 5 min');
    });
  });

  group('NaMePairing', () {
    test('pickNaMePairing avoids in-use color and pair', () {
      final pairing = pickNaMePairing(
        colorPalette: ['green', 'blue'],
        shapePalette: ['diamond', 'circle'],
        inUse: {(colorToken: 'green', shape: 'diamond')},
        labelBuilder: (c, s) => '$c $s',
        random: _SeededRandom(0),
      );
      expect(pairing.colorToken, isNot('green'));
    });

    test('fromJson round-trips', () {
      const pairing = NaMePairing(
        colorToken: 'yellow',
        shape: 'square',
        label: 'Yellow Square',
        tripId: 't1',
      );
      final restored = NaMePairing.fromJson(pairing.toJson());
      expect(restored, pairing);
    });
  });

  group('geo helpers', () {
    test('haversineDistanceM is symmetric', () {
      const a = GeoPoint(lat: 9.0765, lng: 7.3986);
      const b = GeoPoint(lat: 9.0579, lng: 7.4951);
      final d1 = haversineDistanceM(a, b);
      final d2 = haversineDistanceM(b, a);
      expect(d1, closeTo(d2, 0.001));
      expect(d1, greaterThan(1000));
    });

    test('bearingDegrees points roughly east for due-east hop', () {
      const from = GeoPoint(lat: 0, lng: 0);
      const to = GeoPoint(lat: 0, lng: 1);
      expect(bearingDegrees(from, to), closeTo(90, 1));
    });
  });

  group('Itinerary', () {
    test('orderedStops sorts by sequence', () {
      const itinerary = Itinerary(
        itineraryId: 'i1',
        stops: [
          ItineraryStop(
            stopId: 's2',
            sequence: 2,
            label: 'B',
            lat: 1,
            lng: 2,
          ),
          ItineraryStop(
            stopId: 's1',
            sequence: 1,
            label: 'A',
            lat: 3,
            lng: 4,
          ),
        ],
        selectedCandidate: null,
      );
      expect(itinerary.orderedStops.map((s) => s.stopId), ['s1', 's2']);
    });
  });

  group('Journey', () {
    test('activeTrip returns first active leg', () {
      final journey = Journey(
        journeyId: 'j1',
        trips: [
          TripSummary(
            tripId: 't1',
            journeyId: 'j1',
            journeySequence: 1,
            status: TripStatus.completed,
            fare: FareQuote(
              total: Money.parse('100', currency: 'NGN'),
              tier: FareTier.throughFare,
              confidence: 1,
              unconfirmed: false,
              quoteId: 'q',
              expiresAt: DateTime.utc(2026, 9, 4),
            ),
            naMe: const NaMePairing(
              colorToken: 'red',
              shape: 'triangle',
              label: 'Red Triangle',
            ),
            liveChannel: 'trip:t1',
            expiresAt: DateTime.utc(2026, 9, 4),
          ),
          TripSummary(
            tripId: 't2',
            journeyId: 'j1',
            journeySequence: 2,
            status: TripStatus.accepted,
            fare: FareQuote(
              total: Money.parse('200', currency: 'NGN'),
              tier: FareTier.summedLegs,
              confidence: 0.9,
              unconfirmed: false,
              quoteId: 'q2',
              expiresAt: DateTime.utc(2026, 9, 4),
            ),
            naMe: const NaMePairing(
              colorToken: 'blue',
              shape: 'circle',
              label: 'Blue Circle',
            ),
            liveChannel: 'trip:t2',
            expiresAt: DateTime.utc(2026, 9, 4),
          ),
        ],
      );
      expect(journey.activeTrip?.tripId, 't2');
    });
  });

  group('AlongErrorCode', () {
    test('parses known API codes', () {
      expect(
        AlongErrorCode.parse('LEDGER_BLOCKED'),
        AlongErrorCode.ledgerBlocked,
      );
      expect(AlongErrorCode.parse('NOPE'), AlongErrorCode.unknown);
    });
  });

  group('PlanResult', () {
    test('sortedBy respects server order', () {
      const c1 = PlanCandidate(
        candidateId: 'cheap',
        kind: 'direct',
        source: 'parked',
        viableDirect: true,
        legs: [],
        totalFareMinorUnits: 100,
        totalTimeSeconds: 100,
        transferCount: 0,
      );
      const c2 = PlanCandidate(
        candidateId: 'fast',
        kind: 'direct',
        source: 'roaming',
        viableDirect: true,
        legs: [],
        totalFareMinorUnits: 200,
        totalTimeSeconds: 50,
        transferCount: 0,
      );
      final result = PlanResult(
        queryId: 'q',
        cityId: 'city',
        degraded: false,
        candidates: [c1, c2],
        sortOrders: {
          SortCriterion.cheapest: ['cheap', 'fast'],
        },
      );
      expect(result.sortedBy(SortCriterion.cheapest).map((c) => c.candidateId),
          ['cheap', 'fast']);
    });
  });
}

class _SeededRandom implements Random {
  _SeededRandom(this._seed);
  int _seed;

  @override
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => nextInt(1 << 32) / (1 << 32);
}
