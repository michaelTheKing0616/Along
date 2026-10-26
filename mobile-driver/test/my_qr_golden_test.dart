import 'dart:convert';

import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/payments/domain/qr_scanner_port.dart';
import 'package:mobile_driver/features/payments/domain/share_image_port.dart';
import 'package:mobile_driver/features/payments/presentation/my_qr_screen.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_driver/testing/fakes/fake_driver_channel.dart';

/// D-25 My QR on fakes, light/dark/1.3x.
void main() {
  setUpAll(() async {
    final manifest = await rootBundle.loadStructuredData<List<dynamic>>(
      'FontManifest.json',
      (s) async => json.decode(s) as List<dynamic>,
    );
    for (final entry in manifest) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in entry['fonts'] as List<dynamic>) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
    await AlongFonts.ensureLoaded();
  });

  const variants = [
    ('light', Brightness.light, 1.0),
    ('dark', Brightness.dark, 1.0),
    ('light_1_3x', Brightness.light, 1.3),
  ];

  for (final (name, brightness, scale) in variants) {
    for (final enabled in [true, false]) {
      final state = enabled ? 'live' : 'setup';
      testWidgets('my qr $state $name', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final container = ProviderContainer(
          overrides: buildProviderOverrides(
            config: const AppConfig(
              flavor: 'dev',
              supabaseUrl: 'https://test.supabase.co',
              supabaseAnonKey: 'test-key',
            ),
            supabase: FakeAlongSupabase(
              digitalPaymentsEnabled: enabled,
              driverCode: 'ABC12345',
              driverPlate: 'ABC-123-KJ',
            ),
            database: AlongDatabase.memory(),
            driverChannel: FakeDriverChannel(),
            shareImagePort: FakeShareImagePort(),
            qrScanner: FakeQrScanner(),
          ),
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: alongTheme(brightness: brightness),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
                ),
                child: child!,
              ),
              home: const MyQrScreen(renderQrPixels: true),
            ),
          ),
        );
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        expect(find.text('ABC12345'), findsOneWidget);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/driver_my_qr_${state}_$name.png'),
        );
      });
    }
  }
}
