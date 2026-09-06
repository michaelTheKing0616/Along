import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';

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

enum DriverPricingTerminalKind {
  none,
  lapsedTimeout,
  lapsedOutOfRange,
  declined,
}
