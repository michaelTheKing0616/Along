import 'package:along_data/src/seats/ride_rules.dart';
import 'package:along_data/src/seats/seat_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Abuja along car preset is 2 front and 4 back', () {
    final layout = SeatLayout.fromJson(alongCarPreset);
    expect(layout.passengerCount, 6);
    expect(layout.rowIdOf('fl'), 'front');
    expect(layout.rowIdOf('b4'), 'back');
    expect(layout.rows.first.seats.where((seat) => seat.isPassenger).length, 2);
    expect(layout.overCapacity(6), isFalse);
    expect(layout.overCapacity(4), isTrue);
  });

  test('starter is a generic cabin and keeps one driver', () {
    final layout = SeatLayout.starter(passengerSeats: 4);
    expect(layout.body, 'cabin');
    expect(layout.passengerCount, 4);
    expect(
      layout.rows
          .expand((row) => row.seats)
          .where((seat) => seat.role == 'driver'),
      hasLength(1),
    );
  });

  test('editor adds a row, a seat, and keeps a single driver', () {
    final layout = SeatLayout.fromJson(alongCarPreset);
    final grown = layout.addRow().addSeat('front').markDriver('b1');
    expect(grown.rows.length, 3);
    expect(grown.rowIdOf('b1') != null, isTrue);
    expect(
      grown.rows
          .expand((row) => row.seats)
          .where((seat) => seat.role == 'driver'),
      hasLength(1),
    );
    expect(grown.seatById('fl')!.isPassenger, isTrue);
    expect(grown.passengerCount, layout.passengerCount + 2);
  });

  test('removing the last passenger seat is refused', () {
    final layout = SeatLayout.starter(passengerSeats: 1);
    final only = layout.rows
        .expand((row) => row.seats)
        .firstWhere((seat) => seat.isPassenger);
    final rowId = layout.rowIdOf(only.id)!;
    expect(layout.removeSeat(rowId, only.id).passengerCount, 1);
  });

  test('a layout cannot grow past 80 seats', () {
    var layout = SeatLayout.starter(passengerSeats: 1);
    for (var i = 0; i < 90; i++) {
      layout = layout.addRow();
    }
    expect(layout.totalSeats <= SeatLayout.maxTotalSeats, isTrue);
  });

  test('rule engine reads effect and params, not preset names', () {
    final layout = SeatLayout.fromJson(alongCarPreset);
    const engine = SeatRuleEngine();
    final rules = [
      RideRule(
        id: 'cap',
        presetId: 'max_front_passengers',
        effect: 'cap_seats',
        targetScope: 'row',
        targetRef: 'front',
        title: 'Two in front',
        params: const {'max': 1},
        enabled: true,
      ),
      RideRule(
        id: 'ack',
        presetId: 'women_only_row',
        effect: 'acknowledge',
        targetScope: 'row',
        targetRef: 'back',
        title: 'Women only in the back',
        body: 'Please acknowledge.',
        enabled: true,
      ),
      RideRule(
        id: 'hold-row',
        effect: 'hold_minutes',
        targetScope: 'row',
        targetRef: 'front',
        title: 'Front hold',
        params: const {'duration_minutes': 5},
        enabled: true,
      ),
      RideRule(
        id: 'hold-car',
        presetId: 'seat_hold',
        effect: 'hold_minutes',
        targetScope: 'vehicle',
        title: 'Car hold',
        params: const {'duration_minutes': 3},
        enabled: true,
      ),
      RideRule(
        id: 'note',
        effect: 'badge',
        targetScope: 'vehicle',
        title: 'Quiet cabin',
        body: 'No loud calls',
        enabled: true,
      ),
    ];

    final states = {'fl': const SeatOccupancy(status: 'occupied')};
    final blocked = engine.capBlocksClaim(
      rules: rules,
      layout: layout,
      seatId: 'fr',
      states: states,
    );
    expect(blocked.map((rule) => rule.title), ['Two in front']);
    expect(
      engine
          .acknowledgementsRequired(rules: rules, seatId: 'b1', rowId: 'back')
          .single
          .title,
      'Women only in the back',
    );
    expect(engine.holdMinutes(rules: rules, seatId: 'fl', rowId: 'front'), 5);
    expect(engine.holdMinutes(rules: rules, seatId: 'b1', rowId: 'back'), 3);
    expect(
      rulesMatchFilter(
        rules: rules,
        presetIds: const ['women_only_row'],
        query: 'quiet',
      ),
      isTrue,
    );
    expect(
      rulesMatchFilter(
        rules: rules,
        presetIds: const ['front_seat_offered'],
        query: null,
      ),
      isFalse,
    );
  });

  test('stale and hidden thresholds and delta size', () {
    final updated = DateTime.utc(2026, 10, 22, 12);
    expect(
      seatStateIsStale(updated, updated.add(const Duration(seconds: 61))),
      isTrue,
    );
    expect(
      seatStateIsStale(updated, updated.add(const Duration(seconds: 60))),
      isFalse,
    );
    expect(
      seatStateIsHidden(updated, updated.add(const Duration(minutes: 5))),
      isFalse,
    );
    expect(
      seatStateIsHidden(
        updated,
        updated.add(const Duration(minutes: 5, seconds: 1)),
      ),
      isTrue,
    );
    final bytes = seatDeltaPayloadBytes({
      'seat_id': 'fl',
      'status': 'occupied',
      'version': 2,
      'free': 5,
      'updated_at': '2026-10-22T12:00:00Z',
    });
    expect(bytes <= 200, isTrue);
  });

  test('an expired hold is free at claim time', () {
    final now = DateTime.utc(2026, 10, 22, 12);
    const held = SeatOccupancy(status: 'held', holdUntil: null);
    expect(held.isFreeAt(now), isFalse);
    final expired = SeatOccupancy(
      status: 'held',
      holdUntil: now.subtract(const Duration(seconds: 1)),
    );
    expect(expired.isFreeAt(now), isTrue);
  });
}
