import 'package:along_core/along_core.dart' show Money;
import 'package:along_data/along_data.dart'
    show
        DriverDigitalPayment,
        DriverEarningsContext,
        DriverPayoutStatus,
        TripCashSummary;
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
    required List<TripCashSummary> cashTrips,
    required List<DriverDigitalPayment> digital,
    DriverEarningsContext? context,
    required DateTime now,
  }) {
    final local = now.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);
    final weekStart = midnight.subtract(const Duration(days: 6));

    final earned = <_Earned>[
      for (final trip in cashTrips)
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

    String dayKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final online = context?.onlineSecondsByDay ?? const <String, int>{};
    final todayOnline = online[dayKey(_lagos(now))];
    final weekOnline = online.isEmpty
        ? null
        : online.values.fold<int>(0, (sum, v) => sum + v);

    AlongPayout? payout;
    final record = context?.latestPayout;
    if (record != null) {
      final created = record.createdAt.toLocal();
      final confirmed = record.confirmedAt?.toLocal();
      String day(DateTime t) => '${weekdays[t.weekday - 1]} ${hm(t)}';
      payout = switch (record.status) {
        DriverPayoutStatus.confirmed => AlongPayout(
          state: AlongPayoutState.paid,
          amount: _naira(record.amount),
          when: 'Paid ${day(confirmed ?? created)}',
          account: record.accountLabel,
        ),
        DriverPayoutStatus.pending => AlongPayout(
          state: AlongPayoutState.scheduled,
          amount: _naira(record.amount),
          when: 'sent ${weekdays[created.weekday - 1]}',
          account: record.accountLabel,
        ),
        DriverPayoutStatus.failed => AlongPayout(
          state: AlongPayoutState.failed,
          amount: _naira(record.amount),
          when: day(created),
          account: record.accountLabel,
        ),
      };
    }

    return EarningsSummaryData(
      today: AlongEarningsPeriod(
        total: todayItems.fold(0, (sum, e) => sum + e.amount),
        online: todayOnline == null ? null : formatOnline(todayOnline),
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
        online: weekOnline == null ? null : formatOnline(weekOnline),
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

/// "6h 40m", "45m". Whole minutes, rounded down.
String formatOnline(int seconds) {
  final minutes = seconds ~/ 60;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

DateTime _lagos(DateTime now) => now.toUtc().add(const Duration(hours: 1));

int _naira(Money m) => m.minorUnits ~/ 100;

String _sourceLabel(String source) => source.startsWith('qr')
    ? 'QR payment'
    : source.startsWith('wallet')
    ? 'Wallet payment'
    : 'Digital payment';
