import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('EmptyState goldens', () {
    for (final variant in EmptyStateVariant.values) {
      testWidgets('${variant.name}_scale1_0', (tester) async {
        await pumpAlongGolden(
          tester,
          surfaceSize: const Size(360, 400),
          child: EmptyState(variant: variant),
        );
        await expectAlongGolden(
          tester,
          'goldens/empty_state_${variant.name}_1_0.png',
        );
      });
    }
  });
}
