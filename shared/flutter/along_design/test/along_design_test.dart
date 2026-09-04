import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alongDesignVersion is pinned', () {
    expect(alongDesignVersion, '0.0.1');
  });

  test('alongTheme uses ink primary, not fromSeed olive', () {
    final theme = alongTheme();
    expect(theme.colorScheme.primary, AlongColors.ink900);
    expect(theme.useMaterial3, isTrue);
    expect(theme.splashFactory, NoSplash.splashFactory);
  });

  group('TS-DS-02', () {
    testWidgets('₦ glyph renders in Inter subset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: alongTheme(),
          home: Scaffold(
            body: Center(
              child: Text(
                '₦450',
                style: AlongText.displayXl,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/ts_ds_02_naira_glyph.png'),
      );
    });
  });
}
