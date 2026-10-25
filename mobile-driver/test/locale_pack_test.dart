import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P10-B-01 locale packs (driver)', () {
    test('ha navHome string', () {
      expect(lookupAppLocalizations(const Locale('ha')).navHome, 'Gida');
    });

    test('yo navHome and settle CTA strings', () {
      final l10n = lookupAppLocalizations(const Locale('yo'));
      expect(l10n.navHome, 'Ilé');
      expect(l10n.settleCta, 'Sanwó');
    });

    test('ig navHome string', () {
      expect(lookupAppLocalizations(const Locale('ig')).navHome, 'Ụlọ');
    });

    test('pcm navHome string', () {
      expect(lookupAppLocalizations(const Locale('pcm')).navHome, 'Home');
    });

    testWidgets('yo golden — settle CTA', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('localization delegates')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.binding.setSurfaceSize(const Size(320, 80));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final l10n = lookupAppLocalizations(const Locale('yo'));
      await tester.pumpWidget(
        MaterialApp(
          theme: alongTheme(),
          home: Scaffold(
            body: AlongButton(
              label: l10n.settleCta,
              variant: AlongButtonVariant.yellow,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/locale_yo_settle_cta_1_0.png'),
      );
    });
  });
}
