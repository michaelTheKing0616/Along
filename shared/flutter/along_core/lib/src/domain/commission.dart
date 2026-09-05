import 'package:along_core/src/value/money.dart';
import 'package:decimal/decimal.dart';

/// Computes Along commission from fare and configured rate (doc 04 §4.4).
///
/// [rate] is the decimal fraction from `commission.rate` (e.g. 0.075).
Money computeAlongCommission(Money fare, num rate) {
  final product = fare.amount * Decimal.parse(rate.toString());
  return Money(product, currency: fare.currency).roundToMinorUnits();
}

/// Formats [rate] as a human percent (e.g. 0.075 → "7.5").
String formatCommissionPercent(num rate) {
  final percent = (rate * 100).toDouble();
  if (percent == percent.roundToDouble()) {
    return percent.round().toString();
  }
  return percent.toStringAsFixed(1);
}
