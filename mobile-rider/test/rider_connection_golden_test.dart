import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/connection/connection_banner_host.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/search/presentation/search_screens.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

/// Offline cycle over the real search screen: banner, failure and empty
/// states, light/dark/1.3x.
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
            // A phone's status bar and home indicator, to prove safe areas.
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: child!,
        ),
        home: home,
      ),
    );
  }

  AppConfig config() => const AppConfig(
    flavor: 'dev',
    supabaseUrl: 'https://test.supabase.co',
    supabaseAnonKey: 'test-key',
  );

  // (phase, query, search fails): offline shows the cached-only empty state,
  // reconnecting a paused search, restored the fresh results.
  const scenes = [
    (ConnectionPhase.offline, 'Jabi Lake', false),
    (ConnectionPhase.reconnecting, 'Wuse Market', true),
    (ConnectionPhase.restored, 'Wuse', false),
  ];

  for (final (name, brightness, scale) in variants) {
    for (final (phase, query, fails) in scenes) {
      testWidgets('rider connection ${phase.name} $name', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        Map<String, dynamic> place(String kind, String n, String area, int m) =>
            {
              'kind': kind,
              'id': n,
              'name': n,
              'area': area,
              'location': {'lat': 9.07, 'lng': 7.48},
              'distance_m': m,
            };
        final fake = FakeAlongSupabase(
          configRows: defaultTestConfigRows(),
          placeResults: phase == ConnectionPhase.offline
              ? const []
              : [
                  place('market', 'Wuse Market', 'Wuse', 1800),
                  place('stage', 'Wuse II stage', 'Wuse II', 2400),
                  place('park', 'Wuye Motor Park', 'Wuye', 3100),
                ],
        )..failPlaceSearch = fails;
        final controller = connectionControllerIn(phase);
        final container = ProviderContainer(
          overrides: [
            connectionControllerProvider.overrideWith((ref) {
              controller.start();
              ref.onDispose(controller.dispose);
              return controller;
            }),
            ...buildProviderOverrides(
              config: config(),
              supabase: fake,
              ambientChannel: FakeAmbientChannel(),
              database: AlongDatabase.memory(),
              locationStreamSource: FakeLocationStreamSource(
                fixedSamples: [
                  LocationSample(
                    point: const GeoPoint(lat: 9.072, lng: 7.481),
                    accuracyM: 10,
                    recordedAt: DateTime.utc(2026, 1, 1),
                  ),
                ],
              ),
              clock: Clock.fixed(DateTime.utc(2026, 1, 1, 0, 1, 0)),
              recentPlacesStore: FakeRecentPlacesStore(
                places: [
                  const RecentPlace(
                    label: 'Wuse Market',
                    location: GeoPoint(lat: 9.06, lng: 7.47),
                  ),
                ],
              ),
            ),
          ],
        );
        addTearDown(() {
          fake.dispose();
          container.dispose();
        });
        container.read(homeControllerProvider);
        await tester.pumpWidget(
          app(
            container,
            const ConnectionBannerHost(child: DestinationSearchScreen()),
            brightness,
            scale,
          ),
        );
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(
          find.byKey(const Key('destination_search_field')),
          query,
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(Key('connection_banner_${phase.name}')),
          findsOneWidget,
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(milliseconds: 100));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/rider_connection_${phase.name}_$name.png'),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      });
    }
  }

  testWidgets('offline banner never blocks search; retry stays offline', (
    tester,
  ) async {
    final fake = FakeAlongSupabase(configRows: defaultTestConfigRows());
    final controller = connectionControllerIn(ConnectionPhase.offline);
    final container = ProviderContainer(
      overrides: [
        connectionControllerProvider.overrideWith((ref) {
          controller.start();
          ref.onDispose(controller.dispose);
          return controller;
        }),
        ...buildProviderOverrides(
          config: config(),
          supabase: fake,
          ambientChannel: FakeAmbientChannel(),
          database: AlongDatabase.memory(),
          recentPlacesStore: FakeRecentPlacesStore(places: const []),
        ),
      ],
    );
    addTearDown(() {
      fake.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      app(
        container,
        const ConnectionBannerHost(child: DestinationSearchScreen()),
        Brightness.light,
        1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('connection_banner_offline')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('destination_search_field')),
      'Jabi',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Jabi'), findsWidgets);
    await tester.tap(find.byKey(const Key('connection_banner_action')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('connection_banner_offline')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
