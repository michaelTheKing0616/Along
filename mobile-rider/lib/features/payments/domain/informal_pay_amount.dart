import 'package:along_core/along_core.dart';

/// Informal QR amount UX: skip chips when a unique stage fare exists.
enum InformalPayAmountMode {
  uniqueFare,
  chips,
  keypadOnly,
}

InformalPayAmountMode informalPayAmountMode({
  required bool amountLocked,
  required List<Money> suggestedAmounts,
}) {
  if (amountLocked) return InformalPayAmountMode.uniqueFare;
  final unique = uniqueSuggestedAmount(suggestedAmounts);
  if (unique != null) return InformalPayAmountMode.uniqueFare;
  if (suggestedAmounts.every((m) => m.minorUnits <= 0)) {
    return InformalPayAmountMode.keypadOnly;
  }
  return InformalPayAmountMode.chips;
}

/// Single published stage fare, or null when the rider must pick.
Money? uniqueSuggestedAmount(List<Money> suggestedAmounts) {
  final positive = suggestedAmounts.where((m) => m.minorUnits > 0).toList();
  if (positive.isEmpty) return null;
  final first = positive.first.minorUnits;
  if (positive.every((m) => m.minorUnits == first)) return positive.first;
  return null;
}
