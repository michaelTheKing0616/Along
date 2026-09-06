import 'package:along_core/src/models/trip_summary.dart';
import 'package:along_core/src/value/money.dart';

/// Result of `complete_trip` including the updated trip view.
class CompleteTripResult {
  const CompleteTripResult({
    required this.trip,
    required this.commission,
    required this.fare,
  });

  final TripSummary trip;
  final Money commission;
  final Money fare;
}
