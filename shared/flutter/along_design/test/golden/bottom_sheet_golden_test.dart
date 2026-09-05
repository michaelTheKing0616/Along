import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('BottomSheet goldens', () {
    for (final size in AlongBottomSheetSize.values) {
      testWidgets('${size.name}_scale1_0', (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            theme: alongTheme(),
            home: Scaffold(
              body: Stack(
                children: [
                  AlongBottomSheet(
                    size: size,
                    title: size == AlongBottomSheetSize.collapsed
                        ? null
                        : 'Choose how to go',
                    child: Text(
                      'Sheet content',
                      style: AlongText.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await expectAlongGolden(
          tester,
          'goldens/bottom_sheet_${size.name}_1_0.png',
        );
      });
    }
  });
}
