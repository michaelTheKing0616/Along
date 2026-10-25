import 'package:along_core/along_core.dart'
    show Money, TripReceipt, TripSummary;
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/payments_config.dart';

/// R-22 receipt shown once a trip completes. Built from the server receipt
/// when it arrived, otherwise from the trip's own fare. This is the only
/// place the rider rates a trip; the rating is sent once, when they leave.
class TripReceiptPage extends ConsumerStatefulWidget {
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
  ConsumerState<TripReceiptPage> createState() => _TripReceiptPageState();
}

class _TripReceiptPageState extends ConsumerState<TripReceiptPage> {
  int _score = 0;
  Set<String> _tags = const {};
  bool _sent = false;
  late final _trips = ref.read(tripsRepositoryProvider);

  void _submitOnce() {
    if (_sent || _score == 0) return;
    _sent = true;
    _trips
        .rateTrip(
          tripId: widget.trip.tripId,
          score: _score,
          tags: _tags.toList(),
        )
        .catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    _trips; // resolve while ref is usable.
  }

  @override
  void dispose() {
    _submitOnce();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(ratingTagsProvider).value ?? const <String>[];
    return AlongTripReceiptScreen(
      key: const Key('trip_receipt_page'),
      receipt: receiptViewFor(widget.trip, widget.receipt, DateTime.now()),
      onRate: (score) => _score = score,
      ratingTags: {for (final t in tags) t: ratingTagLabel(t)},
      onTagsChanged: (selected) => _tags = selected,
      onDone: () {
        _submitOnce();
        Navigator.of(context).maybePop();
      },
    );
  }
}

/// 'clean_vehicle' -> 'Clean car'. Known ids get short copy; unknown ones
/// are humanised from the id so a new config tag still reads well.
String ratingTagLabel(String id) {
  const known = {
    'safe_driving': 'Safe driving',
    'fair_fare': 'Fair fare',
    'clean_vehicle': 'Clean car',
    'polite': 'Polite',
    'on_time': 'On time',
  };
  final hit = known[id];
  if (hit != null) return hit;
  final words = id.replaceAll('_', ' ').trim();
  if (words.isEmpty) return id;
  return words[0].toUpperCase() + words.substring(1);
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
