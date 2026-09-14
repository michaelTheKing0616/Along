import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/features/onboarding/domain/phone_number_formatter.dart';

void main() {
  const formatter = PhoneNumberFormatter(phonePrefix: '+234');

  test('accepts 10-digit local numbers starting 7/8/9', () {
    expect(formatter.isValidLocal('8012345678'), isTrue);
    expect(formatter.toE164('8012345678'), '+2348012345678');
  });

  test('accepts trunk-prefixed 11-digit numbers', () {
    expect(formatter.isValidLocal('08012345678'), isTrue);
    expect(formatter.toE164('08012345678'), '+2348012345678');
  });

  test('accepts 9-prefix 10-digit numbers used in device smokes', () {
    expect(formatter.isValidLocal('9065843184'), isTrue);
    expect(formatter.toE164('9065843184'), '+2349065843184');
    expect(formatter.isValidLocal('09065843184'), isTrue);
  });

  test('rejects too-short input', () {
    expect(formatter.isValidLocal('801234567'), isFalse);
  });
}
