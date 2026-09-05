import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('OptionCard goldens (TS-DS-03)', () {
    final cases = <({
      String name,
      OptionCard card,
    })>[
      (
        name: 'direct_normal',
        card: const OptionCard(),
      ),
      (
        name: 'direct_pressed',
        card: const OptionCard(visualState: OptionCardVisualState.pressed),
      ),
      (
        name: 'direct_unavailable',
        card: const OptionCard(
          visualState: OptionCardVisualState.unavailable,
          unavailableReason: 'No drivers available',
        ),
      ),
      (
        name: 'direct_warning',
        card: const OptionCard(
          visualState: OptionCardVisualState.warning,
          loadWarning: 'Large load — keke may not fit',
        ),
      ),
      (
        name: 'recommended',
        card: const OptionCard(recommended: true),
      ),
      (
        name: 'multi_leg',
        card: const OptionCard(
          variant: OptionCardVariant.multiLeg,
          secondaryMode: TransportMode.keke,
          meta: '6 min walk · 1 transfer at Berger',
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
            surfaceSize: Size(400, scale == 1.0 ? 360 : 560),
            child: testCase.card,
          );
          await expectAlongGolden(
            tester,
            'goldens/option_card_${testCase.name}_$scaleTag.png',
          );
        });
      }
    }
  });
}
