import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('SortChips goldens', () {
    for (final selected in SortOption.values) {
      testWidgets('selected_${selected.name}_scale1_0', (tester) async {
        await pumpAlongGolden(
          tester,
          surfaceSize: const Size(400, 120),
          child: SortChips(selected: selected, onSelected: (_) {}),
        );
        await expectAlongGolden(
          tester,
          'goldens/sort_chips_${selected.name}_1_0.png',
        );
      });
    }
  });
}
