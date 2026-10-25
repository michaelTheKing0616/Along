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
      cashToday: [
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
      ledger: const [],
    );
    expect(data.today.total, 1450);
    expect(data.today.trips.single.route, 'Nyanya');
    expect(data.today.bars[0].amount, 1450); // 06:00-08:00 block
    expect(data.today.highlight, 1);
    expect(data.week.total, 2370);
    expect(data.week.bars.last.amount, 1450);
    expect(data.week.bars[4].amount, 920); // Friday
    expect(data.payout?.state, AlongPayoutState.scheduled);
    expect(data.payout?.amount, 920);
  });

  test('a payout debit in the ledger reads as paid', () {
    final data = EarningsSummaryData.from(
      now: now,
      cashToday: const [],
      digital: const [],
      ledger: [
        DriverLedgerEntry(
          id: 'l1',
          entryType: 'payout_debit',
          amount: _ngn('-5000'),
          balanceAfter: _ngn('0'),
          createdAt: DateTime(2026, 10, 24, 9, 0),
        ),
      ],
    );
    expect(data.today.trips, isEmpty);
    expect(data.today.total, 0);
    expect(data.payout?.state, AlongPayoutState.paid);
    expect(data.payout?.amount, 5000);
  });
}
