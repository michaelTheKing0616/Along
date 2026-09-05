import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/features/documents/domain/ocr_confirm_policy.dart';

void main() {
  test('OcrConfirmPolicy blocks auto-apply for ID fields', () {
    expect(OcrConfirmPolicy.mayAutoApply('nin'), isFalse);
    expect(OcrConfirmPolicy.mayAutoApply('drivers_license_number'), isFalse);
  });
}
