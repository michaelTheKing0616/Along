import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('StatusToggle goldens', () {
    for (final status in DriverStatus.values) {
      testWidgets('${status.name}_scale1_0', (tester) async {
        await pumpAlongGolden(
          tester,
          surfaceSize: const Size(400, 120),
          child: StatusToggle(selected: status, onChanged: (_) {}),
        );
        await expectAlongGolden(
          tester,
          'goldens/status_toggle_${status.name}_1_0.png',
        );
      });
    }
  });
}
