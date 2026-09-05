import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

/// Default chip steps mirror `negotiation.chip_steps` config — passed by caller, not hardcoded in widget.
const _chipSteps = [-100, -50, 50, 100];

void main() {
  group('NegotiationSheet goldens (TS-DS-03)', () {
    final cases = <({String name, NegotiationSheet sheet})>[
      (
        name: 'park_round2',
        sheet: const NegotiationSheet(
          variant: NegotiationSheetVariant.park,
          anchorNaira: 600,
          proposedNaira: 550,
          chipSteps: _chipSteps,
          roundNumber: 2,
          roundCap: 4,
          countdownSeconds: 38,
          countdownTotal: 60,
        ),
      ),
      (
        name: 'park_at_cap_split',
        sheet: const NegotiationSheet(
          variant: NegotiationSheetVariant.park,
          anchorNaira: 600,
          proposedNaira: 550,
          splitNaira: 575,
          chipSteps: _chipSteps,
          roundNumber: 4,
          roundCap: 4,
          countdownSeconds: 12,
          countdownTotal: 60,
        ),
      ),
      (
        name: 'roaming_none',
        sheet: const NegotiationSheet(
          variant: NegotiationSheetVariant.roamingNone,
          anchorNaira: 600,
          chipSteps: _chipSteps,
          countdownSeconds: 25,
          countdownTotal: 30,
        ),
      ),
      (
        name: 'roaming_single',
        sheet: const NegotiationSheet(
          variant: NegotiationSheetVariant.roamingSingle,
          anchorNaira: 600,
          proposedNaira: 550,
          chipSteps: _chipSteps,
          roundNumber: 1,
          roundCap: 1,
        ),
      ),
      (
        name: 'roaming_full',
        sheet: const NegotiationSheet(
          variant: NegotiationSheetVariant.roamingFull,
          anchorNaira: 600,
          proposedNaira: 650,
          chipSteps: _chipSteps,
          roundNumber: 3,
          roundCap: 4,
        ),
      ),
      (
        name: 'extension',
        sheet: const NegotiationSheet(
          variant: NegotiationSheetVariant.extension,
          anchorNaira: 750,
          chipSteps: _chipSteps,
          extensionDeltaNaira: 150,
          roundNumber: 1,
          roundCap: 4,
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
            surfaceSize: Size(400, scale == 1.3 ? 520 : 460),
            child: testCase.sheet,
          );
          await expectAlongGolden(
            tester,
            'goldens/negotiation_sheet_${testCase.name}_$scaleTag.png',
          );
        });
      }
    }
  });
}
