import 'dart:math';

import 'package:decimal/decimal.dart';

/// Monetary amount in major currency units (matches API `Money.amount` string).
class Money implements Comparable<Money> {
  const Money(this.amount, {required this.currency});

  final Decimal amount;
  final String currency;

  factory Money.parse(String amount, {required String currency}) {
    return Money(Decimal.parse(amount), currency: currency);
  }

  factory Money.fromMinorUnits(
    int minorUnits, {
    required String currency,
    int minorUnitsExponent = 2,
  }) {
    final scale = Decimal.fromInt(pow(10, minorUnitsExponent).toInt());
    return Money(
      (Decimal.fromInt(minorUnits) / scale).toDecimal(),
      currency: currency,
    );
  }

  factory Money.zero({String currency = 'NGN'}) =>
      Money(Decimal.zero, currency: currency);

  int get minorUnits => (amount * Decimal.fromInt(100)).round().toBigInt().toInt();

  String toApiString() => amount.toStringAsFixed(2);

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(amount - other.amount, currency: currency);
  }

  Money roundToMinorUnits() {
    final rounded =
        (Decimal.fromInt(minorUnits) / Decimal.fromInt(100)).toDecimal();
    return Money(rounded, currency: currency);
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return amount.compareTo(other.amount);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => '$currency $toApiString()';

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Currency mismatch: $currency vs ${other.currency}');
    }
  }
}
