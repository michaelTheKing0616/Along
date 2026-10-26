import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/features/payments/data/payments_providers.dart';
import 'package:mobile_rider/features/payments/domain/qr_scanner_port.dart';
import 'package:mobile_rider/features/payments/presentation/payment_methods_screen.dart';
import 'package:mobile_rider/features/payments/presentation/scan_to_pay_screen.dart';
import 'package:mobile_rider/features/wayfinding/presentation/wayfinding_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

/// Real rider scan-to-pay, payment methods and wayfinding on fakes, light/dark/1.3x.
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

  Widget app(
    ProviderContainer container,
    Widget home,
    Brightness brightness,
    double scale,
  ) {
    return UncontrolledProviderScope(
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
        home: home,
      ),
    );
  }

  ProviderContainer containerFor(
    FakeAlongSupabase fake, {
    AlongDatabase? database,
  }) => ProviderContainer(
    overrides: [
      ...buildProviderOverrides(
        config: const AppConfig(
          flavor: 'dev',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        supabase: fake,
        ambientChannel: FakeAmbientChannel(),
        database: database ?? AlongDatabase.memory(),
        wayfindingTts: FakeWayfindingTts(),
        recentPlacesStore: FakeRecentPlacesStore(),
        clock: Clock.fixed(DateTime.utc(2026, 9, 5, 16, 4, 12)),
        locationStreamSource: FakeLocationStreamSource(
          fixedSamples: [
            LocationSample(
              point: const GeoPoint(lat: 9.072, lng: 7.481),
              accuracyM: 10,
              recordedAt: DateTime.utc(2026, 9, 5, 16),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shoot(WidgetTester tester, String file) async {
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$file.png'),
    );
  }

  Future<void> textMode(ProviderContainer c, WayfindingMode m) =>
      c.read(riderPrefsStoreProvider).setWayfindingMode(m);

  const wayArgs = WayfindingRouteArgs(
    from: GeoPoint(lat: 9.0765, lng: 7.3986),
    to: GeoPoint(lat: 9.08, lng: 7.45),
    destinationLabel: 'Area 1 Park',
  );

  final cards = [
    {'id': 'pm-1', 'brand': 'Visa', 'last4': '4242', 'is_default': true},
    {'id': 'pm-2', 'brand': 'Mastercard', 'last4': '1881', 'is_default': false},
  ];

  for (final (name, brightness, scale) in variants) {
    testWidgets('payment methods $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        paymentMethods: cards,
      );
      final c = containerFor(fake);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        app(c, const PaymentMethodsScreen(), brightness, scale),
      );
      await settle(tester);
      expect(find.text('Visa ···4242'), findsOneWidget);
      await shoot(tester, 'rider_pay_methods_$name');
    });

    testWidgets('payment methods empty $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = containerFor(
        FakeAlongSupabase(configRows: defaultTestConfigRows()),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        app(c, const PaymentMethodsScreen(), brightness, scale),
      );
      await settle(tester);
      expect(find.text('No saved cards yet'), findsOneWidget);
      await shoot(tester, 'rider_pay_methods_empty_$name');
    });

    for (final state in ['camera', 'reject', 'typed']) {
      testWidgets('scan to pay $state $name', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final scanner = FakeQrScanner();
        addTearDown(scanner.dispose);
        final c = ProviderContainer(
          parent: containerFor(
            FakeAlongSupabase(configRows: defaultTestConfigRows()),
          ),
          overrides: [qrScannerProvider.overrideWithValue(scanner)],
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          app(c, const ScanToPayScreen(), brightness, scale),
        );
        await settle(tester);
        if (state == 'reject') {
          scanner.emit('https://notalong.ng/p/TEST0301');
          await settle(tester);
          expect(find.byKey(const Key('scan_reject_message')), findsOneWidget);
        }
        if (state == 'typed') {
          await tester.tap(find.byKey(const Key('scan_enter_code')));
          await settle(tester);
          await tester.enterText(find.byKey(const Key('scan_code_field')), 'X');
          await tester.tap(find.byKey(const Key('scan_code_submit')));
          await settle(tester);
          expect(find.byKey(const Key('scan_reject_message')), findsOneWidget);
        }
        await shoot(tester, 'rider_scan_${state}_$name');
      });
    }

    for (final mode in [WayfindingMode.text, WayfindingMode.audio]) {
      testWidgets('wayfinding ${mode.name} $name', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final c = containerFor(
          FakeAlongSupabase(configRows: defaultTestConfigRows()),
        );
        addTearDown(c.dispose);
        await textMode(c, mode);
        await tester.pumpWidget(
          app(c, const WayfindingScreen(args: wayArgs), brightness, scale),
        );
        await settle(tester);
        expect(find.byKey(const Key('wayfinding_mode_text')), findsOneWidget);
        await shoot(tester, 'rider_wayfinding_${mode.name}_$name');
      });
    }
  }

  testWidgets('tapping a card makes it the default for paying drivers', (
    tester,
  ) async {
    final fake = FakeAlongSupabase(
      configRows: defaultTestConfigRows(),
      paymentMethods: cards,
    );
    final c = containerFor(fake);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      app(c, const PaymentMethodsScreen(), Brightness.light, 1),
    );
    await settle(tester);
    expect(
      await c.read(paymentMethodPrefProvider.future),
      PaymentMethodPref.bankTransfer,
    );
    await tester.tap(find.byKey(const Key('pay_method_pm-2')));
    await settle(tester);
    expect(
      fake.paymentMethods.firstWhere((m) => m['id'] == 'pm-2')['is_default'],
      isTrue,
    );
    expect(
      await c.read(paymentMethodPrefProvider.future),
      PaymentMethodPref.savedCard,
    );
    await tester.tap(find.byKey(const Key('pay_method_remove_pm-1')));
    await settle(tester);
    expect(find.text('Visa ···4242'), findsNothing);
  });

  testWidgets('wayfinding mode switch persists the choice', (tester) async {
    final c = containerFor(
      FakeAlongSupabase(configRows: defaultTestConfigRows()),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      app(c, const WayfindingScreen(args: wayArgs), Brightness.light, 1),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('wayfinding_mode_audio')));
    await settle(tester);
    expect(find.byKey(const Key('wayfinding_audio_play')), findsOneWidget);
    expect(
      await c.read(riderPrefsStoreProvider).wayfindingMode(),
      WayfindingMode.audio,
    );
  });
}
