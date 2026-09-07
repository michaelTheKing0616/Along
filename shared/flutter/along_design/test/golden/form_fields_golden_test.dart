import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('SearchField goldens', () {
    for (final variant in SearchFieldVariant.values) {
      testWidgets('${variant.name}_scale1_0', (tester) async {
        await pumpAlongGolden(
          tester,
          surfaceSize: const Size(360, 100),
          child: SearchField(
            variant: variant,
            onRecentsTap: variant == SearchFieldVariant.home ? () {} : null,
          ),
        );
        await expectAlongGolden(
          tester,
          'goldens/search_field_${variant.name}_1_0.png',
        );
      });
    }
  });

  group('PhoneField goldens', () {
    testWidgets('default_scale1_0', (tester) async {
      await pumpAlongGolden(
        tester,
        surfaceSize: const Size(360, 100),
        child: const PhoneField(countryCode: '+234'),
      );
      await expectAlongGolden(tester, 'goldens/phone_field_default_1_0.png');
    });

    testWidgets('error_scale1_0', (tester) async {
      await pumpAlongGolden(
        tester,
        surfaceSize: const Size(360, 120),
        child: const PhoneField(
          countryCode: '+234',
          errorText: 'Enter a valid Nigerian number',
        ),
      );
      await expectAlongGolden(tester, 'goldens/phone_field_error_1_0.png');
    });
  });

  group('OtpField goldens', () {
    testWidgets('default_scale1_0', (tester) async {
      await pumpAlongGolden(
        tester,
        surfaceSize: const Size(360, 100),
        child: const OtpField(),
      );
      await expectAlongGolden(tester, 'goldens/otp_field_default_1_0.png');
    });

    testWidgets('error_scale1_0', (tester) async {
      await pumpAlongGolden(
        tester,
        surfaceSize: const Size(360, 120),
        child: const OtpField(errorText: 'Incorrect code — try again'),
      );
      await expectAlongGolden(tester, 'goldens/otp_field_error_1_0.png');
    });
  });
}
