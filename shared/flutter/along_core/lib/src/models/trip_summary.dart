import 'package:along_core/src/enums/trip_status.dart';
import 'package:along_core/src/models/fare_quote.dart';
import 'package:along_core/src/models/na_me_pairing.dart';
import 'package:along_core/src/models/trip_extension_proposal.dart';
import 'package:along_core/src/models/trip_live.dart';
import 'package:along_core/src/models/trip_load.dart';
import 'package:along_core/src/models/trip_party.dart';
import 'package:along_core/src/models/trip_stop.dart';
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
    this.rider = const RiderPreview(
      displayName: 'Rider',
      rating: 0,
      tripCount: 0,
    ),
    this.board = const TripBoardStop(name: ''),
    this.alight = const TripAlightStop(name: ''),
    this.load = const TripLoadInfo(flagged: false),
    this.womenOnly = false,
    this.dispatchAttempt = 1,
    this.isRoamingHail = false,
    this.driver = const DriverPreview(
      displayName: '',
      rating: 0,
      tripCount: 0,
    ),
    this.vehicle = const VehiclePreview(
      plateNumber: '',
      color: '',
      makeModel: '',
      seatCapacity: 4,
    ),
    this.live,
    this.modeCode = 'car',
    this.modeLabel = 'Car',
    this.etaMinutes,
    this.pendingExtension,
    this.paymentMethod,
  });

  final String tripId;
  final String journeyId;
  final int journeySequence;
  final TripStatus status;
  final FareQuote fare;
  final NaMePairing naMe;
  final String liveChannel;
  final DateTime expiresAt;
  final RiderPreview rider;
  final TripBoardStop board;
  final TripAlightStop alight;
  final TripLoadInfo load;
  final bool womenOnly;
  final int dispatchAttempt;
  final bool isRoamingHail;
  final DriverPreview driver;
  final VehiclePreview vehicle;
  final TripLiveSnapshot? live;
  final String modeCode;
  final String modeLabel;
  final int? etaMinutes;
  final TripExtensionProposal? pendingExtension;
  final String? paymentMethod;

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
