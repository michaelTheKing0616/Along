import 'package:along_core/src/enums/fare_tier.dart';
import 'package:along_core/src/value/money.dart';

/// Resolved fare quote attached to a trip or planner leg.
class FareQuote {
  const FareQuote({
    required this.total,
    required this.tier,
    required this.confidence,
    required this.unconfirmed,
    required this.quoteId,
    required this.expiresAt,
  });

  final Money total;
  final FareTier tier;
  final double confidence;
  final bool unconfirmed;
  final String quoteId;
  final DateTime expiresAt;

  factory FareQuote.fromJson(Map<String, dynamic> json) => FareQuote(
        total: Money.parse(
          json['total']['amount'] as String,
          currency: json['total']['currency'] as String,
        ),
        tier: FareTier.fromInt((json['tier'] as num).toInt()),
        confidence: (json['confidence'] as num).toDouble(),
        unconfirmed: json['unconfirmed'] as bool,
        quoteId: json['quote_id'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}
