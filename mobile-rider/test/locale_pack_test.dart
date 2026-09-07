import 'package:along_design/along_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P10-B-01 locale packs (rider)', () {
    test('ha navHome and city switcher strings', () {
      final l10n = lookupAppLocalizations(const Locale('ha'));
      expect(l10n.navHome, 'Gida');
      expect(l10n.accountCityLabel, 'Birnin gida');
      expect(l10n.sponsoredLabel, 'Tallafi');
    });

    test('yo navHome string', () {
      expect(lookupAppLocalizations(const Locale('yo')).navHome, 'Ilé');
    });

    test('ig navHome string', () {
      expect(lookupAppLocalizations(const Locale('ig')).navHome, 'Ụlọ');
    });

    test('pcm navHome string', () {
      expect(lookupAppLocalizations(const Locale('pcm')).navHome, 'Home');
    });

    testWidgets('ha golden — city switcher label', (tester) async {
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

      final l10n = lookupAppLocalizations(const Locale('ha'));
      await tester.pumpWidget(
        MaterialApp(
          theme: alongTheme(),
          home: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.accountCityLabel, style: AlongText.label),
                Text(l10n.sponsoredLabel, style: AlongText.caption),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/locale_ha_city_switcher_1_0.png'),
      );
    });
  });
}
