import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('StepList goldens', () {
    const steps = [
      WayfindingStep(
        maneuverIcon: Icons.turn_right,
        instruction: 'Turn right onto Airport Road',
        distance: '120 m',
      ),
      WayfindingStep(
        maneuverIcon: Icons.straight,
        instruction: 'Continue straight past the park gate',
        distance: '350 m',
        isActive: true,
      ),
      WayfindingStep(
        maneuverIcon: Icons.turn_left,
        instruction: 'Turn left at the keke stand',
        distance: '80 m',
      ),
    ];

    for (final variant in StepListVariant.values) {
      testWidgets('${variant.name}_scale_1_0', (tester) async {
        await pumpAlongGolden(
          tester,
          surfaceSize: Size(400, variant == StepListVariant.audioPlaying ? 400 : 280),
          child: StepList(variant: variant, steps: steps),
        );
        await expectAlongGolden(
          tester,
          'goldens/step_list_${variant.name}_1_0.png',
        );
      });
    }
  });
}
