import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/features/documents/domain/ocr_confirm_policy.dart';

void main() {
  group('OcrConfirmPolicy', () {
    test('marks NIN and license keys as sensitive', () {
      expect(OcrConfirmPolicy.isSensitiveField('nin'), isTrue);
      expect(OcrConfirmPolicy.isSensitiveField('id_number'), isTrue);
      expect(OcrConfirmPolicy.isSensitiveField('license_number'), isTrue);
      expect(OcrConfirmPolicy.isSensitiveField('full_name'), isFalse);
    });

    test('mayAutoApply is false for sensitive keys', () {
      expect(OcrConfirmPolicy.mayAutoApply('nin'), isFalse);
      expect(OcrConfirmPolicy.mayAutoApply('full_name'), isTrue);
    });

    test('redactForSubmit strips sensitive confirmed fields', () {
      final redacted = OcrConfirmPolicy.redactForSubmit({
        'nin': '12345678901',
        'full_name': 'Ada',
      });
      expect(redacted.containsKey('nin'), isFalse);
      expect(redacted['full_name'], 'Ada');
    });

    test('applyConfirmed only updates after explicit call', () {
      var fields = <String, String>{};
      expect(fields.containsKey('nin'), isFalse);

      fields = OcrConfirmPolicy.applyConfirmed(
        current: fields,
        key: 'nin',
        value: '12345678901',
      );
      expect(fields['nin'], '12345678901');
    });
  });
}
