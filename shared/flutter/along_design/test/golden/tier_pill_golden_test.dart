import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('TierPill goldens', () {
    for (final tier in FareTier.values) {
      testWidgets('${tier.name}_scale1_0', (tester) async {
        await pumpAlongGolden(
          tester,
          surfaceSize: const Size(320, 80),
          child: TierPill(tier: tier),
        );
        await expectAlongGolden(
          tester,
          'goldens/tier_pill_${tier.name}_1_0.png',
        );
      });
    }
  });
}
