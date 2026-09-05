import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

export 'package:flutter/material.dart' show Size;

/// Pumps a widget wrapped in [MaterialApp] + [alongTheme] for golden tests.
Future<void> pumpAlongGolden(
  WidgetTester tester, {
  required Widget child,
  double textScaleFactor = 1.0,
  Size surfaceSize = const Size(400, 200),
  Color backgroundColor = AlongColors.surface0,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScaleFactor),
        size: surfaceSize,
      ),
      child: MaterialApp(
        theme: alongTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: backgroundColor,
          body: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(AlongSpace.s16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Asserts a golden file at the given [path] relative to `test/`.
Future<void> expectAlongGolden(
  WidgetTester tester,
  String path, {
  bool? skip,
}) {
  return expectLater(
    find.byType(Scaffold),
    matchesGoldenFile(path),
    skip: skip,
  );
}

/// Golden matrix documentation (TS-DS-03):
///
/// | Component     | States captured                          | textScale 1.3 |
/// |---------------|------------------------------------------|---------------|
/// | AlongButton   | 5 variants × 4 visual states             | 1.0 only      |
/// | HoldButton    | sos/naMe × idle/holding/fired            | 1.0 only      |
/// | TierPill      | 4 tiers                                  | 1.0 only      |
/// | ModeChip      | 4 modes × s/m × selected/unselected      | 1.0 only      |
/// | SortChips     | 4 options (one selected each)            | 1.0 only      |
/// | OptionCard    | 4 visual states + recommended/multi-leg  | 1.0 + 1.3     |
/// | BottomSheet   | collapsed/half/full                      | 1.0 only      |
/// | SearchField   | home/full                                | 1.0 only      |
/// | PhoneField    | default/error                            | 1.0 only      |
/// | OtpField      | default/error                            | 1.0 only      |
/// | Skeleton      | line/card/mapOverlay                     | 1.0 only      |
/// | AlongToast    | info/success/undo                        | 1.0 only      |
/// | EmptyState    | coverageGap/noHistory/offline            | 1.0 only      |
/// | StatusToggle  | 4 driver statuses                        | 1.0 only      |
/// | RequestSheet  | default/load/womenOnly                   | 1.0 + 1.3     |
/// | BalanceCard   | good/warned/paused                       | 1.0 + 1.3     |
/// | NaMeChip      | green diamond (representative)           | 1.0 only      |
