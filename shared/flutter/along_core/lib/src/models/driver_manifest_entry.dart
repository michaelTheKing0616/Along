import 'package:along_core/src/enums/trip_status.dart';
import 'package:along_core/src/models/na_me_pairing.dart';
import 'package:along_core/src/models/trip_party.dart';
import 'package:along_core/src/models/trip_stop.dart';

/// One row from `driver_manifest()` (doc 06 D-15).
class DriverManifestEntry {
  const DriverManifestEntry({
    required this.tripId,
    required this.status,
    required this.journeySequence,
    required this.rider,
    required this.board,
    required this.naMe,
    this.expiresAt,
  });

  final String tripId;
  final TripStatus status;
  final int journeySequence;
  final RiderPreview rider;
  final TripBoardStop board;
  final NaMePairing naMe;
  final DateTime? expiresAt;

  bool get canMarkBoarded =>
      status == TripStatus.accepted || status == TripStatus.transfer;

  bool get canStartTrip => status == TripStatus.boarded;

  bool get canCompleteTrip => status == TripStatus.inTransit;

  bool get showNaMe =>
      status == TripStatus.accepted ||
      status == TripStatus.boarded ||
      status == TripStatus.transfer;
}
