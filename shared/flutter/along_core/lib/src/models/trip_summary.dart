import 'package:along_core/src/enums/trip_status.dart';
import 'package:along_core/src/models/fare_quote.dart';
import 'package:along_core/src/models/na_me_pairing.dart';
import 'package:along_core/src/value/money.dart';

/// Lightweight trip view for client state and offline cache.
class TripSummary {
  const TripSummary({
    required this.tripId,
    required this.journeyId,
    required this.journeySequence,
    required this.status,
    required this.fare,
    required this.naMe,
    required this.liveChannel,
    required this.expiresAt,
  });

  final String tripId;
  final String journeyId;
  final int journeySequence;
  final TripStatus status;
  final FareQuote fare;
  final NaMePairing naMe;
  final String liveChannel;
  final DateTime expiresAt;

  bool get isActive => switch (status) {
        TripStatus.requested ||
        TripStatus.accepted ||
        TripStatus.boarded ||
        TripStatus.inTransit ||
        TripStatus.transfer =>
          true,
        _ => false,
      };

  Money get totalFare => fare.total;
}
