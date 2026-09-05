import 'package:decimal/decimal.dart';

/// Result of validating a driver's `price_to_end` schedule (§4.7, doc 04 §2).
class RoutePriceValidation {
  const RoutePriceValidation.valid() : isValid = true, errorKey = null;

  const RoutePriceValidation.invalid(this.errorKey) : isValid = false;

  final bool isValid;
  final String? errorKey;
}

/// Validates non-increasing prices toward destination; last stop must be ₦0.
RoutePriceValidation validateRoutePrices(List<Decimal> pricesInSequence) {
  if (pricesInSequence.isEmpty) {
    return const RoutePriceValidation.invalid('routePriceErrorEmpty');
  }

  for (var i = 0; i < pricesInSequence.length - 1; i++) {
    if (pricesInSequence[i] < pricesInSequence[i + 1]) {
      return const RoutePriceValidation.invalid('routePriceErrorNonMonotone');
    }
  }

  if (pricesInSequence.last != Decimal.zero) {
    return const RoutePriceValidation.invalid('routePriceErrorLastNotZero');
  }

  return const RoutePriceValidation.valid();
}
