import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('booking phrases keep the rider words', () {
    final english = parseBookingPhrase('Wuse to Berger');
    expect(english?.origin, 'Wuse');
    expect(english?.destination, 'Berger');

    final pidgin = parseBookingPhrase('abeg from Nyanya go CBD');
    expect(pidgin?.origin, 'Nyanya');
    expect(pidgin?.destination, 'CBD');

    final hausa = parseBookingPhrase('daga Wuse zuwa Berger');
    expect(hausa?.origin, 'Wuse');
    expect(hausa?.destination, 'Berger');

    final yoruba = parseBookingPhrase('lati Ikeja si Yaba');
    expect(yoruba?.origin, 'Ikeja');
    expect(yoruba?.destination, 'Yaba');

    expect(parseBookingPhrase('Berger')?.destination, 'Berger');
    expect(parseBookingPhrase('Berger')?.origin, isNull);
    expect(parseBookingPhrase('to'), isNull);
    expect(parseBookingPhrase('   '), isNull);
  });

  test('driver commands cover accept, seats, and Pidgin', () {
    expect(parseDriverVoice('gree')?.intent, DriverVoiceIntent.accept);
    expect(parseDriverVoice('i dey')?.intent, DriverVoiceIntent.online);
    expect(parseDriverVoice('e full')?.intent, DriverVoiceIntent.full);
    final seat = parseDriverVoice('seat back left free');
    expect(seat?.intent, DriverVoiceIntent.seat);
    expect(seat?.seatRef, 'back left');
    expect(seat?.seatStatus, 'free');
    expect(parseDriverVoice('seat full'), isNull);
    expect(parseDriverVoice('maybe later'), isNull);
  });

  test('cargo stays off the passenger count and bundle lists seats', () {
    final layout = SeatLayout.fromJson(alongCarPreset).markCargo('b4');
    expect(layout.seatById('b4')!.isCargo, isTrue);
    expect(layout.passengerCount, 5);
    expect(layout.markCargo('b4').passengerCount, 6);

    final kept = layout.markDriver('fr');
    expect(kept.seatById('b4')!.isCargo, isTrue);
    expect(kept.seatById('fr')!.role, 'driver');

    final rule = RideRule(
      id: 'r1',
      effect: 'bundle',
      targetScope: 'row',
      targetRef: 'back',
      title: 'Back row together',
      enabled: true,
    );
    expect(const SeatRuleEngine().bundleSeatIds(rule: rule, layout: layout), [
      'b1',
      'b2',
      'b3',
    ]);
    expect(
      const SeatRuleEngine().walkExtensionMinutes(
        rules: [
          RideRule(
            id: 'h',
            effect: 'hold_minutes',
            targetScope: 'vehicle',
            title: 'Hold',
            enabled: true,
            params: const {'duration_minutes': 3, 'walk_extension_minutes': 8},
          ),
        ],
        seatId: 'b1',
        rowId: 'back',
      ),
      8,
    );
  });

  test('ghost seats are the ones still occupied', () {
    final layout = SeatLayout.fromJson(alongCarPreset);
    final ids = ghostSeatIds(
      layout: layout,
      states: const {
        'b1': SeatOccupancy(status: 'occupied'),
        'b2': SeatOccupancy(status: 'free'),
      },
    );
    expect(ids, ['b1']);
  });
}
