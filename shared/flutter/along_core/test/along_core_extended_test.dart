import 'dart:math';

import 'package:along_core/along_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money extended', () {
    test('zero, fromMinorUnits, roundToMinorUnits, compare, subtract', () {
      final zero = Money.zero();
      expect(zero.minorUnits, 0);

      final fromMinor = Money.fromMinorUnits(12345, currency: 'NGN');
      expect(fromMinor.toApiString(), '123.45');

      final rounded = Money.parse('10.999', currency: 'NGN').roundToMinorUnits();
      expect(rounded.toApiString(), '11.00');

      final a = Money.parse('10', currency: 'NGN');
      final b = Money.parse('20', currency: 'NGN');
      expect(a.compareTo(b), lessThan(0));
      expect(b - a, Money.parse('10', currency: 'NGN'));
      expect(a == Money.parse('10.00', currency: 'NGN'), isTrue);
      expect(a.toString(), contains('NGN'));
    });
  });

  group('formatting extended', () {
    test('formatMoney with decimals and non-NGN', () {
      final ngn = formatMoney(
        Money.parse('10.50', currency: 'NGN'),
        showDecimals: true,
      );
      expect(ngn, contains('10.50'));

      final usd = formatMoney(Money.parse('5', currency: 'USD'));
      expect(usd, contains('USD'));
    });

    test('formatMoneySpoken zero and fallback locale', () {
      expect(
        formatMoneySpoken(Money.zero()),
        'zero naira',
      );
      expect(
        formatMoneySpoken(Money.parse('10', currency: 'NGN'), locale: 'ha'),
        contains('10'),
      );
    });

    test('formatDuration seconds and whole hours', () {
      expect(formatDuration(const Duration(seconds: 30)), '30 sec');
      expect(formatDuration(const Duration(hours: 2)), '2 hr');
    });
  });

  group('enums', () {
    test('FareTier fromInt throws on unknown', () {
      expect(FareTier.fromInt(1), FareTier.throughFare);
      expect(() => FareTier.fromInt(99), throwsArgumentError);
    });

    test('TransportMode tryParse', () {
      expect(TransportMode.tryParse('keke'), TransportMode.keke);
      expect(TransportMode.tryParse(null), isNull);
      expect(TransportMode.tryParse('bus'), isNull);
    });

    test('TripStatus tryParse all known values', () {
      for (final raw in [
        'requested',
        'accepted',
        'boarded',
        'in_transit',
        'transfer',
        'completed',
        'declined',
        'expired',
        'cancelled',
      ]) {
        expect(TripStatus.tryParse(raw), isNotNull);
      }
      expect(TripStatus.tryParse('unknown'), isNull);
    });

    test('AlongErrorCode covers all API values', () {
      for (final code in AlongErrorCode.values) {
        if (code == AlongErrorCode.unknown) continue;
        expect(AlongErrorCode.parse(code.apiValue), code);
      }
      expect(AlongErrorCode.parse(null), AlongErrorCode.unknown);
      expect(AlongErrorCode.parse(''), AlongErrorCode.unknown);
    });
  });

  group('AlongException', () {
    test('toString includes code and request id', () {
      const ex = AlongException(
        code: AlongErrorCode.forbidden,
        message: 'nope',
        requestId: 'req-1',
      );
      expect(ex.toString(), contains('FORBIDDEN'));
      expect(ex.toString(), contains('req-1'));
    });
  });

  group('FareQuote', () {
    test('fromJson parses nested money', () {
      final quote = FareQuote.fromJson({
        'total': {'amount': '100.00', 'currency': 'NGN'},
        'tier': 2,
        'confidence': 0.5,
        'unconfirmed': true,
        'quote_id': 'q',
        'expires_at': '2026-09-04T12:00:00Z',
      });
      expect(quote.tier, FareTier.summedLegs);
      expect(quote.unconfirmed, isTrue);
    });
  });

  group('NaMe extended', () {
    test('pickNaMePairing throws on empty palette', () {
      expect(
        () => pickNaMePairing(
          colorPalette: [],
          shapePalette: ['diamond'],
          inUse: {},
          labelBuilder: (c, s) => '$c $s',
        ),
        throwsArgumentError,
      );
    });

    test('parseInUsePairs and sortPairingsByLabel', () {
      final inUse = parseInUsePairs([
        {'color_token': 'red', 'shape': 'square'},
      ]);
      expect(inUse.length, 1);

      final sorted = sortPairingsByLabel([
        const NaMePairing(colorToken: 'b', shape: 'c', label: 'Zebra'),
        const NaMePairing(colorToken: 'a', shape: 'c', label: 'Apple'),
      ]);
      expect(sorted.first.label, 'Apple');
    });

    test('pickNaMePairing throws when all pairs taken', () {
      expect(
        () => pickNaMePairing(
          colorPalette: ['red'],
          shapePalette: ['square'],
          inUse: {(colorToken: 'red', shape: 'square')},
          labelBuilder: (c, s) => '$c $s',
        ),
        throwsStateError,
      );
    });
  });

  group('models', () {
    test('GeoPoint json and equality', () {
      const point = GeoPoint(lat: 1, lng: 2);
      expect(GeoPoint.fromJson(point.toJson()), point);
      expect(point.toString(), contains('1'));
    });

    test('PlanCandidate getters', () {
      const direct = PlanCandidate(
        candidateId: 'c',
        kind: 'direct',
        source: 'parked',
        viableDirect: true,
        legs: [],
        totalFareMinorUnits: 1,
        totalTimeSeconds: 1,
        transferCount: 0,
      );
      expect(direct.isDirect, isTrue);
      expect(direct.isMultiLeg, isFalse);
    });

    test('PresenceState getters', () {
      final state = PresenceState(
        driverId: 'd1',
        mode: TransportMode.car,
        status: 'roaming_available',
        location: const GeoPoint(lat: 1, lng: 2),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      expect(state.isOnline, isTrue);
      expect(state.isRoaming, isTrue);
    });

    test('Journey orderedTrips sorts sequences', () {
      final journey = Journey(
        journeyId: 'j',
        trips: [
          _trip('t2', 2, TripStatus.requested),
          _trip('t1', 1, TripStatus.completed),
        ],
      );
      expect(journey.orderedTrips.map((t) => t.tripId), ['t1', 't2']);
      expect(journey.activeTrip?.tripId, 't2');
    });

    test('PlanResult sortedBy returns copy when order missing', () {
      const c = PlanCandidate(
        candidateId: 'c',
        kind: 'direct',
        source: 'parked',
        viableDirect: true,
        legs: [],
        totalFareMinorUnits: 0,
        totalTimeSeconds: 0,
        transferCount: 0,
      );
      final result = PlanResult(
        queryId: 'q',
        cityId: 'city',
        degraded: false,
        candidates: [c],
        sortOrders: {},
      );
      expect(result.sortedBy(SortCriterion.fastest), [c]);
    });

    test('Clock.system returns utc time', () {
      expect(Clock.system.now().isUtc, isTrue);
      expect(Clock.fixed(DateTime.utc(2020)).now(), DateTime.utc(2020));
    });

    test('TripSummary isActive covers active and terminal statuses', () {
      for (final status in [
        TripStatus.requested,
        TripStatus.accepted,
        TripStatus.boarded,
        TripStatus.inTransit,
        TripStatus.transfer,
      ]) {
        expect(_trip('t', 1, status).isActive, isTrue);
      }
      expect(_trip('t', 1, TripStatus.completed).isActive, isFalse);
    });

    test('multi-leg candidate flag', () {
      const multi = PlanCandidate(
        candidateId: 'm',
        kind: 'multi_leg',
        source: 'graph',
        viableDirect: false,
        legs: [],
        totalFareMinorUnits: 0,
        totalTimeSeconds: 0,
        transferCount: 1,
      );
      expect(multi.isMultiLeg, isTrue);
      expect(multi.isDirect, isFalse);
    });
  });

  group('_englishNumber branches', () {
    test('covers teens tens hundreds thousands', () {
      expect(formatMoneySpoken(Money.parse('15', currency: 'NGN')), contains('fifteen'));
      expect(formatMoneySpoken(Money.parse('42', currency: 'NGN')), contains('forty two'));
      expect(formatMoneySpoken(Money.parse('105', currency: 'NGN')), contains('hundred'));
      expect(formatMoneySpoken(Money.parse('1000', currency: 'NGN')), contains('thousand'));
      expect(formatMoneySpoken(Money.parse('-5', currency: 'NGN')), contains('negative'));
      expect(formatMoneySpoken(Money.parse('1000000', currency: 'NGN')), '1000000 naira');
    });
  });
}

TripSummary _trip(String id, int seq, TripStatus status) => TripSummary(
      tripId: id,
      journeyId: 'j',
      journeySequence: seq,
      status: status,
      fare: FareQuote(
        total: Money.parse('1', currency: 'NGN'),
        tier: FareTier.throughFare,
        confidence: 1,
        unconfirmed: false,
        quoteId: 'q',
        expiresAt: DateTime.utc(2026, 1, 1),
      ),
      naMe: const NaMePairing(
        colorToken: 'c',
        shape: 's',
        label: 'l',
      ),
      liveChannel: 'trip:$id',
      expiresAt: DateTime.utc(2026, 1, 1),
    );
