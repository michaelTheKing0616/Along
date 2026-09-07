import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('HoldButton goldens', () {
    for (final type in HoldButtonType.values) {
      for (final state in HoldButtonVisualState.values) {
        testWidgets('${type.name}_${state.name}_scale1_0', (tester) async {
          await pumpAlongGolden(
            tester,
            surfaceSize: const Size(200, 180),
            child: HoldButton(type: type, visualState: state),
          );
          await expectAlongGolden(
            tester,
            'goldens/hold_button_${type.name}_${state.name}_1_0.png',
          );
        });
      }
    }
  });
}
