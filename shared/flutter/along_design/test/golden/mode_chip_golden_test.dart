import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('ModeChip goldens', () {
    for (final mode in TransportMode.values) {
      for (final size in ModeChipSize.values) {
        for (final selected in [false, true]) {
          testWidgets(
            '${mode.name}_${size.name}_sel_${selected ? 1 : 0}_scale1_0',
            (tester) async {
              await pumpAlongGolden(
                tester,
                surfaceSize: const Size(200, 80),
                child: ModeChip(mode: mode, size: size, selected: selected),
              );
              await expectAlongGolden(
                tester,
                'goldens/mode_chip_${mode.name}_${size.name}_sel_${selected ? 1 : 0}_1_0.png',
              );
            },
          );
        }
      }
    }
  });
}
