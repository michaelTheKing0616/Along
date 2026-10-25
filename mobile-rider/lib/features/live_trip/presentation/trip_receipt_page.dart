import 'package:along_core/along_core.dart' show Money, TripReceipt, TripSummary;
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';

/// R-22 receipt shown once a trip completes. Built from the server receipt
/// when it arrived, otherwise from the trip's own fare.
class TripReceiptPage extends ConsumerWidget {
  const TripReceiptPage({super.key, required this.trip, this.receipt});

  final TripSummary trip;
  final TripReceipt? receipt;

  static Future<void> show(
    BuildContext context, {
    required TripSummary trip,
    TripReceipt? receipt,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripReceiptPage(trip: trip, receipt: receipt),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlongTripReceiptScreen(
      key: const Key('trip_receipt_page'),
      receipt: receiptViewFor(trip, receipt, DateTime.now()),
      onRate: (score) => ref
          .read(tripsRepositoryProvider)
          .rateTrip(tripId: trip.tripId, score: score, tags: const [])
          .catchError((_) {}),
      onDone: () => Navigator.of(context).maybePop(),
    );
  }
}

int _naira(Money m) => m.minorUnits ~/ 100;

/// Maps the trip and its server receipt onto the design receipt view.
AlongReceipt receiptViewFor(
  TripSummary trip,
  TripReceipt? receipt,
  DateTime now,
) {
  final lines = receipt == null
      ? [AlongReceiptLine('Fare', _naira(trip.totalFare))]
      : [
          for (final line in receipt.lines)
            AlongReceiptLine(line.label, _naira(line.amount)),
        ];
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  final from = trip.board.name.trim();
  final to = trip.alight.name.trim();
  final driver = trip.driver.displayName.trim();
  return AlongReceipt(
    route: from.isEmpty || to.isEmpty ? 'Your trip' : '$from to $to',
    when: 'Today, $hh:$mm',
    driverName: driver.isEmpty ? 'your driver' : driver.split(' ').first,
    lines: lines,
    fareTotal: receipt == null ? null : _naira(receipt.total),
  );
}
