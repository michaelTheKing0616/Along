import 'package:along_core/along_core.dart' show DriverLedgerEntry, Money;
import 'package:along_data/along_data.dart'
    show DriverDigitalPayment, TripCashSummary;
import 'package:along_design/along_design.dart';

/// Builds the earnings summary view models from the driver's real ledger,
/// cash-trip and digital-payment feeds. No sample data.
class EarningsSummaryData {
  const EarningsSummaryData({
    required this.today,
    required this.week,
    required this.payout,
  });

  final AlongEarningsPeriod today;
  final AlongEarningsPeriod week;
  final AlongPayout? payout;

  factory EarningsSummaryData.from({
    required List<TripCashSummary> cashToday,
    required List<DriverDigitalPayment> digital,
    required List<DriverLedgerEntry> ledger,
    required DateTime now,
  }) {
    final local = now.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);
    final weekStart = midnight.subtract(const Duration(days: 6));

    final earned = <_Earned>[
      for (final trip in cashToday)
        _Earned(
          trip.destinationLabel,
          trip.completedAt.toLocal(),
          _naira(trip.fare),
          'Cash',
        ),
      for (final pay in digital)
        _Earned(
          _sourceLabel(pay.source),
          pay.createdAt.toLocal(),
          _naira(pay.driverAmount),
          'Wallet',
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    final todayItems = earned.where((e) => !e.at.isBefore(midnight)).toList();
    final weekItems = earned.where((e) => !e.at.isBefore(weekStart)).toList();

    // Two-hour blocks from 06:00 to 22:00.
    const blockLabels = ['6a', '8a', '10a', '12p', '2p', '4p', '6p', '8p'];
    int block(DateTime t) => ((t.hour - 6) ~/ 2).clamp(0, 7);
    final hourly = List<int>.filled(8, 0);
    for (final e in todayItems) {
      hourly[block(e.at)] += e.amount;
    }

    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final daily = List<int>.filled(7, 0);
    for (final e in weekItems) {
      final day = DateTime(e.at.year, e.at.month, e.at.day);
      final index = 6 - midnight.difference(day).inDays;
      if (index >= 0 && index < 7) daily[index] += e.amount;
    }

    String hm(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    AlongPayout? payout;
    final paid = ledger.where((e) => e.entryType == 'payout_debit').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final pendingDigital = weekItems
        .where((e) => e.method == 'Wallet')
        .fold<int>(0, (sum, e) => sum + e.amount);
    if (paid.isNotEmpty) {
      final last = paid.first;
      final at = last.createdAt.toLocal();
      payout = AlongPayout(
        state: AlongPayoutState.paid,
        amount: _naira(last.amount).abs(),
        when: 'Paid ${weekdays[at.weekday - 1]} ${hm(at)}',
      );
    } else if (pendingDigital > 0) {
      payout = AlongPayout(
        state: AlongPayoutState.scheduled,
        amount: pendingDigital,
        when: 'pending',
      );
    }

    return EarningsSummaryData(
      today: AlongEarningsPeriod(
        total: todayItems.fold(0, (sum, e) => sum + e.amount),
        trips: [
          for (final e in todayItems)
            AlongEarnedTrip(
              route: e.route,
              when: hm(e.at),
              amount: e.amount,
              method: e.method,
            ),
        ],
        bars: [
          for (var i = 0; i < 8; i++)
            AlongEarningsBar(blockLabels[i], hourly[i]),
        ],
        highlight: local.hour < 6 || local.hour >= 22 ? null : block(local),
      ),
      week: AlongEarningsPeriod(
        total: weekItems.fold(0, (sum, e) => sum + e.amount),
        trips: [
          for (final e in weekItems)
            AlongEarnedTrip(
              route: e.route,
              when: '${weekdays[e.at.weekday - 1]} ${hm(e.at)}',
              amount: e.amount,
              method: e.method,
            ),
        ],
        bars: [
          for (var i = 0; i < 7; i++)
            AlongEarningsBar(
              dayLetters[midnight.subtract(Duration(days: 6 - i)).weekday - 1],
              daily[i],
            ),
        ],
        highlight: 6,
      ),
      payout: payout,
    );
  }
}

class _Earned {
  const _Earned(this.route, this.at, this.amount, this.method);

  final String route;
  final DateTime at;
  final int amount;
  final String method;
}

int _naira(Money m) => m.minorUnits ~/ 100;

String _sourceLabel(String source) => source.startsWith('qr')
    ? 'QR payment'
    : source.startsWith('wallet')
    ? 'Wallet payment'
    : 'Digital payment';
