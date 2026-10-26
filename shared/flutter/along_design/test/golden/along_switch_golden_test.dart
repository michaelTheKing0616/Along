import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  testWidgets('AlongSwitch on, off, disabled', (tester) async {
    await pumpAlongGolden(
      tester,
      surfaceSize: const Size(240, 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          AlongSwitch(value: true, onChanged: (_) {}),
          AlongSwitch(value: false, onChanged: (_) {}),
          const AlongSwitch(value: false, onChanged: null),
        ],
      ),
    );
    await expectAlongGolden(tester, 'goldens/along_switch_1_0.png');
  });

  testWidgets('AlongSwitch toggles on tap', (tester) async {
    bool? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlongSwitch(value: false, onChanged: (v) => got = v),
        ),
      ),
    );
    await tester.tap(find.byType(AlongSwitch));
    expect(got, isTrue);
  });
}
