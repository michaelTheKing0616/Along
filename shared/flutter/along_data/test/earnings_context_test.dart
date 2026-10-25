import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses online time and latest payout', () {
    final ctx = DriverEarningsContext.fromJson({
      'from': '2026-10-18T23:00:00Z',
      'online_seconds_by_day': {'2026-10-25': 24000},
      'latest_payout': {
        'status': 'confirmed',
        'amount': 9600,
        'currency': 'NGN',
        'created_at': '2026-10-23T09:00:00Z',
        'confirmed_at': '2026-10-23T09:05:00Z',
        'account_label': 'Paystack ••4821',
      },
    });
    expect(ctx.onlineSecondsByDay['2026-10-25'], 24000);
    expect(ctx.latestPayout?.status, DriverPayoutStatus.confirmed);
    expect(ctx.latestPayout?.amount.minorUnits, 960000);
    expect(ctx.latestPayout?.accountLabel, 'Paystack ••4821');
  });

  test('handoff keeps only a valid PIN and a phone', () {
    expect(TripHandoff.fromJson(null), isNull);
    expect(TripHandoff.fromJson({'pin': null, 'driver_phone': null}), isNull);
    final h = TripHandoff.fromJson({
      'pin': '0482',
      'driver_phone': '+2348031234567',
    });
    expect(h?.pin, '0482');
    expect(h?.driverPhone, '+2348031234567');
    expect(
      TripHandoff.fromJson({'pin': '12', 'driver_phone': '+234'})?.pin,
      isNull,
    );
  });

  test('lagosDayStart is Lagos midnight in UTC', () {
    expect(
      lagosDayStart(DateTime.utc(2026, 10, 25, 9), daysBack: 6),
      DateTime.utc(2026, 10, 18, 23),
    );
  });
}
