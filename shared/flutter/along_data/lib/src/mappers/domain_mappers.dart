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
    final extension = raw?['extension'] ?? view.extension;
    int? etaMinutes;
    TripExtensionProposal? pendingExtension;
    if (extension is Map<String, dynamic>) {
      if (extension.containsKey('extension_id')) {
        pendingExtension =
            extensionProposalFromView(extension, view.trip_id);
      } else {
        etaMinutes = (extension['eta_minutes'] as num?)?.toInt();
      }
    }
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
      pendingExtension: pendingExtension,
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

  /// Parses one element from `driver_manifest()` (doc 03 §5).
  static DriverManifestEntry manifestEntryFromJson(Map<String, dynamic> json) {
    final tripId = json['trip_id'] as String;
    final status = TripStatus.tryParse(json['status'] as String?);
    if (status == null) {
      throw AlongException(
        code: AlongErrorCode.validation,
        message: 'Unknown manifest status: ${json['status']}',
      );
    }
    final boardJson = json['board'] as Map<String, dynamic>? ?? {};
    final location = boardJson['location'] as Map<String, dynamic>?;
    return DriverManifestEntry(
      tripId: tripId,
      status: status,
      journeySequence: (json['journey_sequence'] as num?)?.toInt() ?? 1,
      rider: riderFromDto(json['rider'] as Map<String, dynamic>? ?? {}),
      board: TripBoardStop(
        name: boardJson['name'] as String? ?? '',
        location: location == null
            ? null
            : GeoPoint(
                lat: (location['lat'] as num).toDouble(),
                lng: (location['lng'] as num).toDouble(),
              ),
      ),
      naMe: naMeFromDto(
        json['na_me'] as Map<String, dynamic>? ?? {},
        tripId: tripId,
      ),
      expiresAt: json['expires_at'] is String
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  static CompleteTripResult completeTripFromJson(Map<String, dynamic> json) {
    final tripJson = json['trip'];
    if (tripJson is! Map<String, dynamic>) {
      throw AlongException(
        code: AlongErrorCode.validation,
        message: 'Missing trip in complete_trip response',
      );
    }
    final view = dto.TripView.fromJson(tripJson);
    return CompleteTripResult(
      trip: tripFromDto(view, raw: tripJson),
      commission: moneyFromDto(
        dto.Money.fromJson(json['commission'] as Map<String, dynamic>),
      ),
      fare: moneyFromDto(
        dto.Money.fromJson(json['fare'] as Map<String, dynamic>),
      ),
    );
  }

  static TripReceipt receiptFromCompleteTripJson(Map<String, dynamic> json) {
    final currency =
        (json['fare'] as Map<String, dynamic>?)?['currency'] as String? ?? 'NGN';
    final fare = moneyFromDto(
      dto.Money.fromJson(json['fare'] as Map<String, dynamic>),
    );
    Money? surcharge;
    final surchargeJson = json['surcharge'];
    if (surchargeJson is Map<String, dynamic>) {
      surcharge = moneyFromDto(dto.Money.fromJson(surchargeJson));
    }
    Money? commission;
    final commissionJson = json['commission'];
    if (commissionJson is Map<String, dynamic>) {
      commission = moneyFromDto(dto.Money.fromJson(commissionJson));
    }
    final totalJson = json['total'];
    final total = totalJson is Map<String, dynamic>
        ? moneyFromDto(dto.Money.fromJson(totalJson))
        : fare + (surcharge ?? Money.zero(currency: currency));
    return TripReceipt(
      fare: fare,
      surcharge: surcharge,
      commission: commission,
      total: total,
    );
  }

  static ProposeExtensionResult proposeExtensionFromJson(
    Map<String, dynamic> json,
  ) {
    return ProposeExtensionResult(
      extensionId: json['extension_id'] as String,
      fareDelta: moneyFromDto(
        dto.Money.fromJson(json['fare_delta'] as Map<String, dynamic>),
      ),
      newTotal: moneyFromDto(
        dto.Money.fromJson(json['new_total'] as Map<String, dynamic>),
      ),
      tier: FareTier.fromInt((json['tier'] as num).toInt()),
      unconfirmed: json['unconfirmed'] as bool,
    );
  }

  static TripExtensionProposal? extensionProposalFromView(
    Map<String, dynamic> json,
    String tripId,
  ) {
    final extensionId = json['extension_id'] as String?;
    if (extensionId == null) return null;
    if (json['status'] != 'proposed') return null;
    final proposedBy = json['proposed_by'] as String? ?? 'driver';
    if (proposedBy != 'driver') return null;

    final destinationName = json['destination_name'] as String? ??
        json['new_alight_name'] as String? ??
        'New destination';

    final fareDeltaJson = json['fare_delta'];
    if (fareDeltaJson == null) return null;

    Money fareDelta;
    String currency = json['currency'] as String? ?? 'NGN';
    if (fareDeltaJson is Map<String, dynamic>) {
      fareDelta = moneyFromDto(dto.Money.fromJson(fareDeltaJson));
      currency = fareDelta.currency;
    } else {
      fareDelta = Money.parse(fareDeltaJson.toString(), currency: currency);
    }

    return TripExtensionProposal(
      extensionId: extensionId,
      tripId: tripId,
      proposedBy: proposedBy,
      destinationName: destinationName,
      fareDelta: fareDelta,
      currency: currency,
    );
  }

  static TripExtensionProposal? extensionProposalFromRow(
    Map<String, dynamic> row, {
    String destinationName = 'New destination',
  }) {
    if (row['status'] != 'proposed') return null;
    final delta = row['fare_delta'];
    if (delta == null) return null;
    final currency = row['currency'] as String? ?? 'NGN';
    return TripExtensionProposal(
      extensionId: row['id'] as String,
      tripId: row['trip_id'] as String,
      proposedBy: row['proposed_by'] as String,
      destinationName: destinationName,
      fareDelta: Money.parse(delta.toString(), currency: currency),
      currency: currency,
    );
  }

  static TripHistoryEntry historyEntryFromTripRow(Map<String, dynamic> row) {
    final status = TripStatus.tryParse(row['status'] as String?) ??
        TripStatus.completed;
    final currency = row['fare_currency'] as String? ?? 'NGN';
    final fareShown = row['fare_shown'];
    final surcharge = row['load_surcharge_amount'];
    final commission = row['commission_amount'];
    final fare = fareShown != null
        ? Money.parse(fareShown.toString(), currency: currency)
        : Money.zero(currency: currency);
    final surchargeMoney = surcharge != null &&
            num.tryParse(surcharge.toString()) != null &&
            num.parse(surcharge.toString()) > 0
        ? Money.parse(surcharge.toString(), currency: currency)
        : null;
    final commissionMoney = commission != null &&
            num.tryParse(commission.toString()) != null &&
            num.parse(commission.toString()) > 0
        ? Money.parse(commission.toString(), currency: currency)
        : null;
    final total = fare +
        (surchargeMoney ?? Money.zero(currency: currency));
    final endedAt = row['ended_at'] as String?;
    return TripHistoryEntry(
      tripId: row['id'] as String,
      completedAt: endedAt != null
          ? DateTime.parse(endedAt)
          : DateTime.now().toUtc(),
      boardName: row['boarding_name'] as String? ?? 'Pickup',
      alightName: row['alighting_name'] as String? ?? 'Drop-off',
      modeCode: row['mode_code'] as String? ?? 'car',
      modeLabel: row['mode_label'] as String? ?? 'Car',
      status: status,
      totalFare: total,
      driverName: row['driver_name'] as String?,
      plateNumber: row['plate_number'] as String?,
      receipt: TripReceipt(
        fare: fare,
        surcharge: surchargeMoney,
        commission: commissionMoney,
        total: total,
      ),
    );
  }

  static DriverLedgerEntry ledgerEntryFromJson(Map<String, dynamic> json) {
    return DriverLedgerEntry(
      id: json['id'] as String,
      entryType: json['entry_type'] as String,
      amount: moneyFromDto(dto.Money.fromJson(json['amount'] as Map<String, dynamic>)),
      balanceAfter: moneyFromDto(
        dto.Money.fromJson(json['balance_after'] as Map<String, dynamic>),
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      memo: json['memo'] as String?,
      tripId: json['trip_id'] as String?,
      destinationLabel: json['destination_label'] as String?,
    );
  }
}
