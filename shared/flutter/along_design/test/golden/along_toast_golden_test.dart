import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('AlongToast goldens', () {
    for (final variant in AlongToastVariant.values) {
      testWidgets('${variant.name}_scale1_0', (tester) async {
        await pumpAlongGolden(
          tester,
          surfaceSize: const Size(400, 100),
          child: AlongToast(
            message: variant == AlongToastVariant.undo
                ? 'Request sent'
                : variant == AlongToastVariant.success
                    ? 'Route saved'
                    : 'Searching nearby parks',
            variant: variant,
            onUndo: variant == AlongToastVariant.undo ? () {} : null,
          ),
        );
        await expectAlongGolden(
          tester,
          'goldens/along_toast_${variant.name}_1_0.png',
        );
      });
    }
  });
}
