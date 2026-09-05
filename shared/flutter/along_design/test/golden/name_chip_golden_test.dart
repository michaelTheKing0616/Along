import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('NaMeChip goldens', () {
    for (final colour in NaMeColour.values) {
      testWidgets('${colour.name}_scale1_0', (tester) async {
        await pumpAlongGolden(
          tester,
          surfaceSize: const Size(320, 80),
          child: NaMeChip(colour: colour, shape: NaMeShape.diamond),
        );
        await expectAlongGolden(
          tester,
          'goldens/name_chip_${colour.name}_1_0.png',
        );
      });
    }
  });
}
