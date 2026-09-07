import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('P10-B-01 white-label branding goldens', () {
    testWidgets('default yellow (#F7D117)', (tester) async {
      await pumpAlongGolden(
        tester,
        surfaceSize: const Size(360, 120),
        child: const AlongButton(
          label: 'Go online',
          variant: AlongButtonVariant.yellow,
        ),
      );
      await expectAlongGolden(
        tester,
        'goldens/branding_yellow_default_1_0.png',
      );
    });

    testWidgets('tenant override yellow (#FFB800)', (tester) async {
      await pumpAlongGolden(
        tester,
        surfaceSize: const Size(360, 120),
        branding: BrandingOverrides.fromConfig(const {
          'brand.yellow': '#FFB800',
          'brand.yellow-pressed': '#E6A600',
        }),
        child: const AlongButton(
          label: 'Go online',
          variant: AlongButtonVariant.yellow,
        ),
      );
      await expectAlongGolden(
        tester,
        'goldens/branding_yellow_tenant_b_1_0.png',
      );
    });
  });

  test('BrandingOverrides.empty keeps default yellow', () {
    final overrides = BrandingOverrides.fromConfig(const {});
    expect(overrides.brandYellow, AlongColors.brandYellow);
    expect(overrides.brandYellow, const Color(0xFFF7D117));
  });
}
