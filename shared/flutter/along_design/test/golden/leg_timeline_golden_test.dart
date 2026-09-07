import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('LegTimeline goldens', () {
    const sampleLegs = [
      LegTimelineLeg(
        mode: TransportMode.car,
        boardLabel: 'Lugbe Park',
        alightLabel: 'Berger',
        fareNaira: 300,
        etaAtTransfer: 'ETA 4 min',
        state: LegTimelineLegState.done,
      ),
      LegTimelineLeg(
        mode: TransportMode.keke,
        boardLabel: 'Berger',
        alightLabel: 'Area 1',
        fareNaira: 150,
        etaAtTransfer: 'ETA 2 min',
        state: LegTimelineLegState.current,
      ),
      LegTimelineLeg(
        isWalk: true,
        mode: TransportMode.car,
        boardLabel: 'Area 1 gate',
        alightLabel: 'Office',
        state: LegTimelineLegState.next,
      ),
      LegTimelineLeg(
        mode: TransportMode.okada,
        boardLabel: 'Office',
        alightLabel: 'Wuse',
        fareNaira: 200,
        state: LegTimelineLegState.pending,
      ),
    ];

    testWidgets('full_itinerary_scale_1_0', (tester) async {
      await pumpAlongGolden(
        tester,
        surfaceSize: const Size(400, 480),
        child: const LegTimeline(legs: sampleLegs),
      );
      await expectAlongGolden(tester, 'goldens/leg_timeline_full_1_0.png');
    });

    testWidgets('compact_active_scale_1_0', (tester) async {
      await pumpAlongGolden(
        tester,
        surfaceSize: const Size(400, 80),
        child: const LegTimeline(
          variant: LegTimelineVariant.compact,
          legs: sampleLegs,
        ),
      );
      await expectAlongGolden(tester, 'goldens/leg_timeline_compact_1_0.png');
    });
  });
}
