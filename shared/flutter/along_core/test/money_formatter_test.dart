import 'package:along_core/along_core.dart';
import 'package:test/test.dart';

void main() {
  test('MoneyFormatter uses country symbol not hardcoded naira', () {
    const formatter = MoneyFormatter(
      currencyCode: 'GHS',
      currencySymbol: '₵',
    );
    final formatted = formatter.format(Money.parse('450', currency: 'GHS'));
    expect(formatted.contains('₵'), isTrue);
    expect(formatted.contains('₦'), isFalse);
  });
}
