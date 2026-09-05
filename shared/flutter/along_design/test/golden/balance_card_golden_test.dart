import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('BalanceCard goldens (TS-DS-03 stub)', () {
    final cases = <({String name, BalanceCard card})>[
      (
        name: 'good',
        card: const BalanceCard(state: BalanceCardState.good, balanceNaira: 1250),
      ),
      (
        name: 'warned',
        card: const BalanceCard(
          state: BalanceCardState.warned,
          balanceNaira: -200,
          thresholdNaira: -500,
        ),
      ),
      (
        name: 'paused',
        card: const BalanceCard(
          state: BalanceCardState.paused,
          balanceNaira: -750,
          thresholdNaira: -500,
        ),
      ),
    ];

    for (final scale in [1.0, 1.3]) {
      final scaleTag = scale == 1.0 ? '1_0' : '1_3';
      for (final testCase in cases) {
        testWidgets('${testCase.name}_scale_$scaleTag', (tester) async {
          await pumpAlongGolden(
            tester,
            textScaleFactor: scale,
            surfaceSize: Size(360, scale == 1.0 ? 300 : 440),
            child: testCase.card,
          );
          await expectAlongGolden(
            tester,
            'goldens/balance_card_${testCase.name}_$scaleTag.png',
          );
        });
      }
    }
  });
}
