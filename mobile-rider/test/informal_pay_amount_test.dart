import 'package:along_core/along_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/features/payments/domain/informal_pay_amount.dart';

Money naira(int major) =>
    Money.fromMinorUnits(major * 100, currency: 'NGN');

void main() {
  test('trip or token lock skips chips', () {
    expect(
      informalPayAmountMode(
        amountLocked: true,
        suggestedAmounts: [naira(400), naira(500)],
      ),
      InformalPayAmountMode.uniqueFare,
    );
  });

  test('single published fare skips chips', () {
    expect(
      informalPayAmountMode(
        amountLocked: false,
        suggestedAmounts: [naira(450), naira(450)],
      ),
      InformalPayAmountMode.uniqueFare,
    );
    expect(uniqueSuggestedAmount([naira(450)])?.minorUnits, 45000);
  });

  test('no published fares shows keypad only', () {
    expect(
      informalPayAmountMode(amountLocked: false, suggestedAmounts: const []),
      InformalPayAmountMode.keypadOnly,
    );
  });

  test('multiple published fares keep chips plus Other', () {
    expect(
      informalPayAmountMode(
        amountLocked: false,
        suggestedAmounts: [naira(400), naira(500)],
      ),
      InformalPayAmountMode.chips,
    );
    expect(uniqueSuggestedAmount([naira(400), naira(500)]), isNull);
  });
}
