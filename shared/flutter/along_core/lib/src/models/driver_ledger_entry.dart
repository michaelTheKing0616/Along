import 'package:along_core/src/value/money.dart';

/// One row from `driver_ledger` RPC (doc 03 §7).
class DriverLedgerEntry {
  const DriverLedgerEntry({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.memo,
    this.tripId,
    this.destinationLabel,
  });

  final String id;
  final String entryType;
  final Money amount;
  final Money balanceAfter;
  final DateTime createdAt;
  final String? memo;
  final String? tripId;
  final String? destinationLabel;
}

class DriverLedgerPage {
  const DriverLedgerPage({
    required this.entries,
    this.nextCursor,
  });

  final List<DriverLedgerEntry> entries;
  final String? nextCursor;
}
