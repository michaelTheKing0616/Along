import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('AmbientCluster goldens', () {
    final cases = <({String name, AmbientCluster cluster})>[
      (
        name: 'bucket1_2_fresh',
        cluster: const AmbientCluster(
          bucket: AmbientClusterBucket.oneToTwo,
          count: 2,
          headingDegrees: [45],
        ),
      ),
      (
        name: 'bucket3_5_fresh',
        cluster: const AmbientCluster(
          bucket: AmbientClusterBucket.threeToFive,
          count: 4,
          headingDegrees: [30, 120, 210],
        ),
      ),
      (
        name: 'bucket6_plus_stale',
        cluster: const AmbientCluster(
          bucket: AmbientClusterBucket.sixPlus,
          count: 8,
          headingDegrees: [0, 90, 180],
          isStale: true,
        ),
      ),
    ];

    for (final testCase in cases) {
      testWidgets('${testCase.name}_scale_1_0', (tester) async {
        await pumpAlongGolden(
          tester,
          surfaceSize: const Size(120, 120),
          backgroundColor: AlongColors.surface100,
          child: testCase.cluster,
        );
        await expectAlongGolden(
          tester,
          'goldens/ambient_cluster_${testCase.name}_1_0.png',
        );
      });
    }
  });
}
