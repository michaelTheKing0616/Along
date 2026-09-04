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

  static TripSummary tripFromDto(dto.TripView view) {
    final status = TripStatus.tryParse(view.status);
    if (status == null) {
      throw AlongException(
        code: AlongErrorCode.validation,
        message: 'Unknown trip status: ${view.status}',
      );
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
    );
  }
}
