import 'package:along_core/src/value/money.dart';

/// Pending trip extension awaiting rider/driver response.
class TripExtensionProposal {
  const TripExtensionProposal({
    required this.extensionId,
    required this.tripId,
    required this.proposedBy,
    required this.destinationName,
    required this.fareDelta,
    required this.currency,
  });

  final String extensionId;
  final String tripId;
  final String proposedBy;
  final String destinationName;
  final Money fareDelta;
  final String currency;

  bool get isFromDriver => proposedBy == 'driver';
}
