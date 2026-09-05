import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('FareHero goldens (TS-DS-03)', () {
    const lineItems = [
      FareHeroLineItem(label: 'Lugbe → Area 1', amountNaira: 450),
      FareHeroLineItem(label: 'Along fee', amountNaira: 34),
    ];

    final cases = <({String name, FareHero hero})>[
      (
        name: 'verified_collapsed',
        hero: const FareHero(
          amountNaira: 450,
          tier: FareTier.verified,
          lineItems: lineItems,
        ),
      ),
      (
        name: 'verified_expanded',
        hero: const FareHero(
          amountNaira: 450,
          tier: FareTier.verified,
          lineItems: lineItems,
          expanded: true,
        ),
      ),
      (
        name: 'estimate_with_delta',
        hero: const FareHero(
          amountNaira: 750,
          tier: FareTier.estimate,
          deltaNaira: 150,
          lineItems: lineItems,
          expanded: true,
        ),
      ),
    ];

    for (final scale in [1.0, 1.3]) {
      final scaleTag = scale == 1.0 ? '1_0' : '1_3';
      for (final testCase in cases) {
        testWidgets('${testCase.name}_scale_$scaleTag', (tester) async {
          await pumpAlongGolden(
            tester,
            textScaleFactor: scale,
            surfaceSize: Size(360, scale == 1.0 ? 220 : 320),
            child: testCase.hero,
          );
          await expectAlongGolden(
            tester,
            'goldens/fare_hero_${testCase.name}_$scaleTag.png',
          );
        });
      }
    }
  });
}
