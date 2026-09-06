import 'package:along_core/src/enums/trip_status.dart';
import 'package:along_core/src/models/trip_receipt.dart';
import 'package:along_core/src/value/money.dart';

/// Completed trip row for R-22 history list.
class TripHistoryEntry {
  const TripHistoryEntry({
    required this.tripId,
    required this.completedAt,
    required this.boardName,
    required this.alightName,
    required this.modeCode,
    required this.modeLabel,
    required this.status,
    required this.totalFare,
    this.receipt,
    this.driverName,
    this.plateNumber,
  });

  final String tripId;
  final DateTime completedAt;
  final String boardName;
  final String alightName;
  final String modeCode;
  final String modeLabel;
  final TripStatus status;
  final Money totalFare;
  final TripReceipt? receipt;
  final String? driverName;
  final String? plateNumber;

  String get routeLabel => '$boardName → $alightName';
}
