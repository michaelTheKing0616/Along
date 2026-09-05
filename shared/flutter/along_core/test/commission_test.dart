import 'package:along_core/along_core.dart';
import 'package:test/test.dart';

void main() {
  group('computeAlongCommission', () {
    test('rounds to minor units using configured rate', () {
      final fare = Money.parse('450.00', currency: 'NGN');
      final fee = computeAlongCommission(fare, 0.075);
      expect(fee.toApiString(), '33.75');
    });

    test('formatCommissionPercent renders fractional rates', () {
      expect(formatCommissionPercent(0.075), '7.5');
      expect(formatCommissionPercent(0.05), '5');
    });
  });
}
