import 'package:along_core/along_core.dart' show TripReceipt, TripSummary;
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/payments_config.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final tags = ref.watch(ratingTagsProvider).value ?? const <String>[];
    final now = ref.watch(clockProvider).now();
    return RiderTripStrings(
      child: AlongTripReceiptScreen(
        key: const Key('trip_receipt_page'),
        receipt: receiptViewFor(l10n, widget.trip, widget.receipt, now),
        onRate: (score) => _score = score,
        ratingTags: {for (final t in tags) t: ratingTagLabel(l10n, t)},
        onTagsChanged: (selected) => _tags = selected,
        onDone: () {
          _submitOnce();
          Navigator.of(context).maybePop();
        },
      ),
    );
  }
}

/// 'clean_vehicle' -> 'Clean car' in the app language. Known ids get short
/// copy; unknown ones are humanised from the id so a new config tag still
/// reads well.
String ratingTagLabel(AppLocalizations l10n, String id) {
  final hit = switch (id) {
    'safe_driving' => l10n.ratingTagSafeDriving,
    'fair_fare' => l10n.ratingTagFairFare,
    'clean_vehicle' => l10n.ratingTagCleanVehicle,
    'polite' => l10n.ratingTagPolite,
    'on_time' => l10n.ratingTagOnTime,
    _ => null,
  };
  if (hit != null) return hit;
  final words = id.replaceAll('_', ' ').trim();
  if (words.isEmpty) return id;
  return words[0].toUpperCase() + words.substring(1);
}

/// Maps the trip and its server receipt onto the design receipt view.
AlongReceipt receiptViewFor(
  AppLocalizations l10n,
  TripSummary trip,
  TripReceipt? receipt,
  DateTime now,
) {
  final lines = receipt == null
      ? [AlongReceiptLine(l10n.receiptFare, majorUnits(trip.totalFare))]
      : [
          AlongReceiptLine(l10n.receiptFare, majorUnits(receipt.fare)),
          if (receipt.surcharge case final s? when s.minorUnits > 0)
            AlongReceiptLine(l10n.receiptLoadSurcharge, majorUnits(s)),
          if (receipt.commission case final c? when c.minorUnits > 0)
            AlongReceiptLine(l10n.receiptAlongFee, majorUnits(c)),
        ];
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  final from = trip.board.name.trim();
  final to = trip.alight.name.trim();
  final driver = trip.driver.displayName.trim();
  return AlongReceipt(
    route: from.isEmpty || to.isEmpty
        ? l10n.receiptYourTrip
        : l10n.receiptRoute(from, to),
    when: l10n.receiptToday('$hh:$mm'),
    driverName: driver.isEmpty
        ? l10n.receiptYourDriver
        : driver.split(' ').first,
    lines: lines,
    fareTotal: receipt == null ? null : majorUnits(receipt.total),
  );
}
