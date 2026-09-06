import 'package:along_core/along_core.dart';
import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;

/// Maps generated contract DTOs to [along_core] domain types.
class DomainMappers {
  const DomainMappers._();

  static Money moneyFromDto(dto.Money value) =>
      Money.parse(value.amount, currency: value.currency);

  static dto.Money moneyToDto(Money value) => dto.Money(
        amount: value.toApiString(),
        currency: value.currency,
      );

  static NaMePairing naMeFromDto(Map<String, dynamic> json, {String? tripId}) =>
      NaMePairing(
        colorToken: json['color_token'] as String,
        shape: json['shape'] as String,
        label: json['label'] as String,
        tripId: tripId,
      );

  static FareQuote fareFromDto(dto.Fare fare) => FareQuote(
        total: moneyFromDto(fare.total),
        tier: FareTier.fromInt(fare.tier),
        confidence: fare.confidence,
        unconfirmed: fare.unconfirmed,
        quoteId: fare.quote_id,
        expiresAt: DateTime.parse(fare.expires_at),
      );

  static RiderPreview riderFromDto(Map<String, dynamic> json) => RiderPreview(
        displayName: json['display_name'] as String? ?? 'Rider',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        tripCount: (json['trip_count'] as num?)?.toInt() ?? 0,
      );

  static DriverPreview driverFromDto(Map<String, dynamic> json) => DriverPreview(
        displayName: json['display_name'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        tripCount: (json['trips_completed'] as num?)?.toInt() ?? 0,
        photoUrl: json['photo_url'] as String?,
      );

  static VehiclePreview vehicleFromDto(Map<String, dynamic> json) =>
      VehiclePreview(
        plateNumber: json['plate_number'] as String? ?? '',
        color: json['color'] as String? ?? '',
        makeModel: json['make_model'] as String? ?? '',
        seatCapacity: (json['seat_capacity'] as num?)?.toInt() ?? 4,
      );

  static TripLiveSnapshot? liveFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return TripLiveSnapshot.fromJson(json);
  }

  static TripBoardStop boardFromDto(dto.BoardStop board) => TripBoardStop(
        name: board.name,
        location: GeoPoint(lat: board.location.lat, lng: board.location.lng),
        walkM: board.walk_m,
        walkS: board.walk_s,
      );

  static TripAlightStop alightFromDto(dto.StageLocation alight) =>
      TripAlightStop(name: alight.name);

  static TripLoadInfo loadFromDto(dto.LoadFlag load) => TripLoadInfo(
        flagged: load.flagged,
        size: load.size,
        note: load.note,
      );

  static TripSummary tripFromDto(
    dto.TripView view, {
    Map<String, dynamic>? raw,
  }) {
    final status = TripStatus.tryParse(view.status);
    if (status == null) {
      throw AlongException(
        code: AlongErrorCode.validation,
        message: 'Unknown trip status: ${view.status}',
      );
    }
    final extension = raw?['extension'];
    final etaMinutes = extension is Map<String, dynamic>
        ? (extension['eta_minutes'] as num?)?.toInt()
        : null;
    return TripSummary(
      tripId: view.trip_id,
      journeyId: view.journey_id,
      journeySequence: view.journey_sequence,
      status: status,
      fare: fareFromDto(view.fare),
      naMe: naMeFromDto(view.na_me, tripId: view.trip_id),
      liveChannel: view.live_channel,
      expiresAt: DateTime.parse(view.expires_at),
      rider: riderFromDto(view.rider),
      driver: driverFromDto(view.driver),
      vehicle: vehicleFromDto(view.vehicle),
      board: boardFromDto(view.board),
      alight: alightFromDto(view.alight),
      load: loadFromDto(view.load),
      womenOnly: view.women_only,
      live: liveFromJson(raw?['live']),
      modeCode: view.mode.code,
      modeLabel: view.mode.label,
      etaMinutes: etaMinutes,
      dispatchAttempt: _dispatchAttemptFromTripJson(view),
      isRoamingHail: _isRoamingHailFromTripJson(view),
    );
  }

  /// Parses Broadcast / FCM `trip_request` envelope (doc 03 §5).
  static TripSummary incomingTripFromEnvelope(Map<String, dynamic> envelope) {
    final tripJson = envelope['trip'];
    if (tripJson is! Map<String, dynamic>) {
      throw AlongException(
        code: AlongErrorCode.validation,
        message: 'Missing trip in trip_request payload',
      );
    }
    final view = dto.TripView.fromJson(tripJson);
    final summary = tripFromDto(view);
    final dispatchAttempt = _readDispatchAttempt(envelope, tripJson);
    final isRoamingHail = _readRoamingHail(tripJson, summary);
    final envelopeExpires = envelope['expires_at'];
    final expiresAt = envelopeExpires is String
        ? DateTime.parse(envelopeExpires)
        : summary.expiresAt;

    return TripSummary(
      tripId: summary.tripId,
      journeyId: summary.journeyId,
      journeySequence: summary.journeySequence,
      status: summary.status,
      fare: summary.fare,
      naMe: summary.naMe,
      liveChannel: summary.liveChannel,
      expiresAt: expiresAt,
      rider: summary.rider,
      board: summary.board,
      alight: summary.alight,
      load: summary.load,
      womenOnly: summary.womenOnly,
      dispatchAttempt: dispatchAttempt,
      isRoamingHail: isRoamingHail,
    );
  }

  static int _readDispatchAttempt(
    Map<String, dynamic> envelope,
    Map<String, dynamic> tripJson,
  ) {
    final envelopeAttempt = envelope['dispatch_attempt'];
    if (envelopeAttempt is num) return envelopeAttempt.toInt();
    final tripAttempt = tripJson['dispatch_attempt'];
    if (tripAttempt is num) return tripAttempt.toInt();
    return 1;
  }

  static bool _readRoamingHail(
    Map<String, dynamic> tripJson,
    TripSummary summary,
  ) {
    final explicit = tripJson['is_roaming_hail'];
    if (explicit is bool) return explicit;
    return summary.isRoamingHail;
  }

  static int _dispatchAttemptFromTripJson(dto.TripView view) => 1;

  static bool _isRoamingHailFromTripJson(dto.TripView view) {
    final board = view.board;
    final noStage = board.stage_id.isEmpty;
    return noStage && board.name == 'Pickup' && !board.wayfinding_available;
  }
}
