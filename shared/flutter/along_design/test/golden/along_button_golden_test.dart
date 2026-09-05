import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('AlongButton goldens', () {
    for (final variant in AlongButtonVariant.values) {
      for (final state in AlongButtonVisualState.values) {
        testWidgets('${variant.name}_${state.name}_scale1_0', (tester) async {
          await pumpAlongGolden(
            tester,
            surfaceSize: const Size(360, 120),
            child: AlongButton(
              label: 'Continue',
              variant: variant,
              visualState: state,
              onPressed: state == AlongButtonVisualState.disabled ? null : () {},
            ),
          );
          await expectAlongGolden(
            tester,
            'goldens/along_button_${variant.name}_${state.name}_1_0.png',
          );
        });
      }
    }
  });
}
