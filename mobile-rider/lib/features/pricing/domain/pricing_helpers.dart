import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';

/// Roaming hail context from an ambient cell tap (R-05 → R-07 hail intent).
class HailIntent {
  const HailIntent({
    required this.candidateToken,
    required this.modeCode,
    required this.etaBandSeconds,
  });

  final String candidateToken;
  final String modeCode;
  final int etaBandSeconds;
}

/// Maps server negotiation context + ETA band to [NegotiationSheetVariant].
NegotiationSheetVariant negotiationVariantFor({
  required String context,
  String? etaBand,
}) {
  if (context == 'extension') {
    return NegotiationSheetVariant.extension;
  }
  if (context == 'roaming') {
    return switch (etaBand) {
      'none' => NegotiationSheetVariant.roamingNone,
      'single' => NegotiationSheetVariant.roamingSingle,
      _ => NegotiationSheetVariant.roamingFull,
    };
  }
  return NegotiationSheetVariant.park;
}

/// Predict roaming ETA band from ambient cell ETA seconds and config thresholds.
Future<String> roamingEtaBandFor({
  required int etaBandSeconds,
  required Future<double> Function(String key) configNum,
}) async {
  final noneS = (await configNum('negotiation.roaming.eta_none_s')).round();
  final singleS = (await configNum('negotiation.roaming.eta_single_s')).round();
  if (etaBandSeconds <= noneS) return 'none';
  if (etaBandSeconds <= singleS) return 'single';
  return 'full';
}

int moneyToNaira(Money money) => money.amount.round().toBigInt().toInt();

int? splitPreviewNaira({
  required int? lastRiderNaira,
  required int? lastDriverNaira,
  required int anchorNaira,
}) {
  final rider = lastRiderNaira ?? anchorNaira;
  final driver = lastDriverNaira;
  if (driver == null) return null;
  return ((rider + driver) / 2).round();
}
