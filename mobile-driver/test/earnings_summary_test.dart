import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/features/ledger/domain/earnings_summary.dart';

Money _ngn(String v) => Money.parse(v, currency: 'NGN');

void main() {
  final now = DateTime(2026, 10, 25, 9, 30);

  test('today and week come from cash trips and digital payments', () {
    final data = EarningsSummaryData.from(
      now: now,
      cashTrips: [
        TripCashSummary(
          tripId: 't1',
          fare: _ngn('1450'),
          completedAt: DateTime(2026, 10, 25, 7, 52),
          destinationLabel: 'Nyanya',
        ),
      ],
      digital: [
        DriverDigitalPayment(
          id: 'p1',
          amount: _ngn('1000'),
          driverAmount: _ngn('920'),
          commissionAmount: _ngn('80'),
          source: 'qr_dynamic',
          createdAt: DateTime(2026, 10, 23, 18, 0),
        ),
      ],
    );
    expect(data.today.total, 1450);
    expect(data.today.trips.single.route, 'Nyanya');
    expect(data.today.bars[0].amount, 1450); // 06:00-08:00 block
    expect(data.today.highlight, 1);
    expect(data.week.total, 2370);
    expect(data.week.bars.last.amount, 1450);
    expect(data.week.bars[4].amount, 920); // Friday
    expect(data.payout, isNull, reason: 'no payout record, no guess');
    expect(data.today.online, isNull);
  });

  test('earlier-day cash trips count toward the week only', () {
    final data = EarningsSummaryData.from(
      now: now,
      cashTrips: [
        TripCashSummary(
          tripId: 't0',
          fare: _ngn('800'),
          completedAt: DateTime(2026, 10, 21, 17, 10),
          destinationLabel: 'Wuse',
        ),
      ],
      digital: const [],
    );
    expect(data.today.total, 0);
    expect(data.week.total, 800);
    expect(data.week.bars[2].amount, 800); // Wednesday
  });

  test('online time and payout come from the earnings context', () {
    final data = EarningsSummaryData.from(
      now: DateTime.utc(2026, 10, 25, 8, 30),
      cashTrips: const [],
      digital: const [],
      context: DriverEarningsContext.fromJson({
        'online_seconds_by_day': {'2026-10-25': 9000, '2026-10-24': 24000},
        'latest_payout': {
          'status': 'confirmed',
          'amount': 5000,
          'currency': 'NGN',
          'created_at': '2026-10-24T08:00:00Z',
          'confirmed_at': '2026-10-24T08:05:00Z',
          'bank_name': 'GTBank',
          'account_last4': '4821',
        },
      }),
    );
    expect(data.today.online, '2h 30m');
    expect(data.week.online, '9h 10m');
    expect(data.payout?.state, AlongPayoutState.paid);
    expect(data.payout?.amount, 5000);
    expect(data.payout?.account, 'GTBank ••4821');
    expect(data.payout?.when, startsWith('Paid Sat'));
  });

  test('formatOnline', () {
    expect(formatOnline(2700), '45m');
    expect(formatOnline(7200), '2h');
  });
}
