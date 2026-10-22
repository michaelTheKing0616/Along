import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('anchored window stays inside the ceiling and allows one counter', () {
    expect(
      anchoredWindow(anchorMinor: 100000, percent: null, timeoutSeconds: 15),
      isNull,
    );
    final wide = anchoredWindow(
      anchorMinor: 100000,
      percent: 40,
      timeoutSeconds: 15,
    );
    expect(wide?.percent, anchoredPercentCap);
    expect(wide?.lowMinor, 80000);
    expect(wide?.highMinor, 120000);
    expect(anchoredAmountAllowed(wide!, 110000), isTrue);
    expect(anchoredAmountAllowed(wide, 130000), isFalse);
    expect(anchoredCounterAllowed(0), isTrue);
    expect(anchoredCounterAllowed(1), isFalse);
    expect(
      anchoredWindow(anchorMinor: 100000, percent: 10, timeoutSeconds: 90),
      isNull,
    );
  });

  test('fair fare shield speaks only at the city confidence', () {
    final quiet = fairFareShield(
      offeredMinor: 150000,
      paidAmounts: [80000, 90000, 100000],
      minSamples: null,
      showAt: 0.8,
    );
    expect(quiet.showComparison, isFalse);
    expect(quiet.medianMinor, 90000);

    final shown = fairFareShield(
      offeredMinor: 150000,
      paidAmounts: [80000, 90000, 100000, 110000],
      minSamples: 4,
      showAt: 0.8,
    );
    expect(shown.confidence, 1);
    expect(shown.showComparison, isTrue);
    expect(shown.aboveUsual, isTrue);
    expect(disputeChangesFare(), isFalse);
  });

  test(
    'fare history ignores disputes and weather needs a reason and a cap',
    () {
      final history = fareHistoryByHour(const [
        FareSample(hour: 7, amountMinor: 80000, kind: 'paid'),
        FareSample(hour: 7, amountMinor: 100000, kind: 'paid'),
        FareSample(hour: 7, amountMinor: 500000, kind: 'dispute'),
        FareSample(hour: 18, amountMinor: 120000, kind: 'paid'),
      ]);
      expect(history[7], 90000);
      expect(history[18], 120000);

      final silent = explainWeatherFare(
        baseMinor: 100000,
        multiplier: 1.5,
        reason: '',
        cap: 1.2,
      );
      expect(silent.applied, isFalse);
      expect(silent.amountMinor, 100000);

      final rain = explainWeatherFare(
        baseMinor: 100000,
        multiplier: 1.5,
        reason: 'Heavy rain on Nyanya road',
        cap: 1.2,
      );
      expect(rain.applied, isTrue);
      expect(rain.amountMinor, 120000);
      expect(rain.reason, 'Heavy rain on Nyanya road');
    },
  );

  test('goal, tip, fuel and route requests follow what people set', () {
    expect(
      dailyGoal(targetMinor: null, earnedMinor: 0, typicalFareMinor: 50000),
      isNull,
    );
    final goal = dailyGoal(
      targetMinor: 200000,
      earnedMinor: 50000,
      typicalFareMinor: 50000,
    );
    expect(goal?.seatsLeft, 3);

    expect(corridorTip(const []), isNull);
    expect(
      corridorTip(const [
        CorridorDemand(label: 'Lugbe', requests: 4),
        CorridorDemand(label: 'Nyanya', requests: 11),
      ]),
      'Nyanya',
    );

    final pumps = cheaperPumps(
      notes: const [
        FuelNote(label: 'Near park', priceNaira: 900, lat: 9.06, lng: 7.49),
        FuelNote(label: 'Far', priceNaira: 700, lat: 6.5, lng: 3.4),
        FuelNote(label: 'Dear', priceNaira: 1100, lat: 9.061, lng: 7.491),
      ],
      lat: 9.06,
      lng: 7.49,
      radiusMeters: 2000,
      lastPriceNaira: 1000,
    );
    expect(pumps.map((note) => note.label), ['Near park']);
    expect(
      cheaperPumps(
        notes: pumps,
        lat: 9,
        lng: 7,
        radiusMeters: null,
        lastPriceNaira: null,
      ),
      isEmpty,
    );

    expect(routeRequestNotifies(count: 30, threshold: null), isFalse);
    expect(routeRequestNotifies(count: 29, threshold: 30), isFalse);
    expect(routeRequestNotifies(count: 30, threshold: 30), isTrue);
  });

  test('stage radar, cells, favourites and trust order the board', () {
    final early = DateTime.utc(2026, 10, 22, 8);
    final ordered = stageRadarOrder([
      StageVehicle(
        driverId: 'b',
        name: 'Ada',
        plate: 'ABC-123XY',
        seatsFree: 3,
        seatsTotal: 6,
        startedAt: early,
      ),
      StageVehicle(
        driverId: 'a',
        name: 'Musa',
        plate: 'KJA-22-AA',
        seatsFree: 1,
        seatsTotal: 6,
        startedAt: early.add(const Duration(minutes: 5)),
      ),
    ]);
    expect(ordered.first.driverId, 'a');
    expect(ordered.first.name, isNot(contains('+234')));

    final cell = marketplaceCell(9.06, 7.49);
    final ranked = rankMatches(
      riderCell: cell,
      favouriteIds: {'fav'},
      candidates: [
        MatchCandidate(
          driverId: 'other-cell',
          cell: marketplaceCell(9.2, 7.2),
          seatsFree: 4,
          trust: 9,
        ),
        MatchCandidate(
          driverId: 'same',
          cell: cell,
          seatsFree: 2,
          trust: driverTrustRank(
            verifiedStatus: 'verified',
            standing: 'good_standing',
            ratingCount: 10,
          ),
        ),
        MatchCandidate(
          driverId: 'fav',
          cell: cell,
          seatsFree: 1,
          trust: driverTrustRank(
            verifiedStatus: 'unverified',
            standing: 'good_standing',
            ratingCount: 0,
          ),
        ),
      ],
    );
    expect(ranked.map((row) => row.driverId), ['fav', 'same', 'other-cell']);
    expect(
      driverTrustRank(
        verifiedStatus: 'verified',
        standing: 'matching_paused',
        ratingCount: 40,
      ),
      0,
    );

    final start = DateTime.utc(2026, 10, 22, 18);
    expect(
      pickupEventOpen(
        starts: start,
        ends: start.add(const Duration(hours: 3)),
        now: start.add(const Duration(hours: 1)),
      ),
      isTrue,
    );
    expect(
      pickupEventOpen(
        starts: start,
        ends: start.add(const Duration(hours: 3)),
        now: start.add(const Duration(hours: 3)),
      ),
      isFalse,
    );
  });
}
