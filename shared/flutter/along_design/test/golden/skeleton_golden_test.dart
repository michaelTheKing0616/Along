import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('Skeleton goldens', () {
    for (final variant in SkeletonVariant.values) {
      testWidgets('${variant.name}_scale1_0', (tester) async {
        await pumpAlongGolden(
          tester,
          surfaceSize: const Size(360, 160),
          child: AlongSkeleton(variant: variant),
        );
        await expectAlongGolden(
          tester,
          'goldens/skeleton_${variant.name}_1_0.png',
        );
      });
    }
  });
}
