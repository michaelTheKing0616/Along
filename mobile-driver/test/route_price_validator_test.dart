import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/features/routes/domain/route_price_validator.dart';

void main() {
  group('validateRoutePrices', () {
    test('accepts non-increasing prices with last zero', () {
      final result = validateRoutePrices([
        Decimal.fromInt(400),
        Decimal.fromInt(200),
        Decimal.zero,
      ]);
      expect(result.isValid, isTrue);
    });

    test('rejects increasing price toward destination', () {
      final result = validateRoutePrices([
        Decimal.fromInt(200),
        Decimal.fromInt(300),
        Decimal.zero,
      ]);
      expect(result.isValid, isFalse);
      expect(result.errorKey, 'routePriceErrorNonMonotone');
    });

    test('rejects last stop not zero', () {
      final result = validateRoutePrices([
        Decimal.fromInt(400),
        Decimal.fromInt(50),
      ]);
      expect(result.isValid, isFalse);
      expect(result.errorKey, 'routePriceErrorLastNotZero');
    });
  });
}
