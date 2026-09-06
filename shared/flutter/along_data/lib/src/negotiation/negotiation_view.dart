import 'package:along_core/along_core.dart' as core;
import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;

/// Server view from `_negotiation_build_view` / negotiation RPC responses.
class NegotiationView {
  const NegotiationView({
    required this.negotiationId,
    required this.status,
    required this.context,
    required this.anchor,
    this.agreedAmount,
    required this.roundCap,
    required this.roundTimeoutS,
    this.etaBand,
    required this.expiresAt,
    required this.round,
    required this.amount,
    required this.proposedBy,
    required this.chipSteps,
    this.trip,
  });

  final String negotiationId;
  final String status;
  final String context;
  final core.Money anchor;
  final core.Money? agreedAmount;
  final int roundCap;
  final int roundTimeoutS;
  final String? etaBand;
  final DateTime expiresAt;
  final int round;
  final core.Money amount;
  final String proposedBy;
  final List<core.Money> chipSteps;
  final dto.TripView? trip;

  bool get isOpen => status == 'open';
  bool get isAgreed => status == 'agreed';
  bool get isLapsed => status == 'lapsed';
  bool get isDeclined => status == 'declined';
  bool get atCap => round >= roundCap;

  factory NegotiationView.fromJson(Map<String, dynamic> json) {
    return NegotiationView(
      negotiationId: json['negotiation_id'] as String,
      status: json['status'] as String,
      context: json['context'] as String,
      anchor: _money(json['anchor'] as Map<String, dynamic>),
      agreedAmount: json['agreed_amount'] == null
          ? null
          : _money(json['agreed_amount'] as Map<String, dynamic>),
      roundCap: (json['round_cap'] as num).toInt(),
      roundTimeoutS: (json['round_timeout_s'] as num).toInt(),
      etaBand: json['eta_band'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(),
      round: (json['round'] as num).toInt(),
      amount: _money(json['amount'] as Map<String, dynamic>),
      proposedBy: json['proposed_by'] as String,
      chipSteps: (json['chip_steps'] as List<dynamic>)
          .map((e) => _money(e as Map<String, dynamic>))
          .toList(growable: false),
      trip: json['trip'] == null
          ? null
          : dto.TripView.fromJson(json['trip'] as Map<String, dynamic>),
    );
  }

  factory NegotiationView.fromOpenResponse(
    dto.OpenNegotiationResponse open, {
    required String context,
  }) {
    return NegotiationView(
      negotiationId: open.negotiation_id,
      status: 'open',
      context: context,
      anchor: core.Money.parse(open.anchor.amount, currency: open.anchor.currency),
      roundCap: open.round_cap,
      roundTimeoutS: open.round_timeout_s,
      etaBand: open.eta_band,
      expiresAt: DateTime.parse(open.expires_at).toUtc(),
      round: 1,
      amount: core.Money.parse(open.anchor.amount, currency: open.anchor.currency),
      proposedBy: 'rider',
      chipSteps: open.chip_steps
          .map((step) => core.Money.parse(step.amount, currency: step.currency))
          .toList(growable: false),
    );
  }

  static core.Money _money(Map<String, dynamic> json) {
    return core.Money.parse(json['amount'] as String, currency: json['currency'] as String);
  }

  int get anchorNaira => anchor.amount.round().toBigInt().toInt();
  int get amountNaira => amount.amount.round().toBigInt().toInt();
  List<int> get chipStepsNaira =>
      chipSteps.map((step) => step.amount.round().toBigInt().toInt()).toList();
}
