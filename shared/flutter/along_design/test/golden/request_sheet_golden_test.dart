import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('RequestSheet goldens (TS-DS-03)', () {
    final cases = <({String name, RequestSheet sheet})>[
      (name: 'default', sheet: const RequestSheet()),
      (
        name: 'with_load',
        sheet: const RequestSheet(
          hasLoad: true,
          loadNote: 'Large suitcase flagged',
        ),
      ),
      (
        name: 'women_only',
        sheet: const RequestSheet(womenOnly: true),
      ),
    ];

    for (final scale in [1.0, 1.3]) {
      final scaleTag = scale == 1.0 ? '1_0' : '1_3';
      for (final testCase in cases) {
        testWidgets('${testCase.name}_scale_$scaleTag', (tester) async {
          await pumpAlongGolden(
            tester,
            textScaleFactor: scale,
            surfaceSize: Size(400, scale == 1.3 ? 480 : 420),
            child: testCase.sheet,
          );
          await expectAlongGolden(
            tester,
            'goldens/request_sheet_${testCase.name}_$scaleTag.png',
          );
        });
      }
    }
  });
}
