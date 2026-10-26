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
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/search/presentation/search_screens.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/trip_options_fixtures.dart';

/// Real rider search and trip options screens on fakes, light/dark/1.3x.
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

  for (final (name, brightness, scale) in variants) {
    testWidgets('rider search $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Map<String, dynamic> place(
        String kind,
        String name,
        String area,
        int m,
      ) => {
        'kind': kind,
        'id': name,
        'name': name,
        'area': area,
        'location': {'lat': 9.07, 'lng': 7.48},
        'distance_m': m,
      };
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        placeResults: [
          place('market', 'Wuse Market', 'Wuse', 1800),
          place('stage', 'Wuse II stage', 'Wuse II', 2400),
          place('park', 'Wuye Motor Park', 'Wuye', 3100),
          place('place', 'Wuse Zone 4', 'Wuse', 2900),
        ],
      );
      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: config(),
          supabase: fake,
          ambientChannel: FakeAmbientChannel(),
          database: AlongDatabase.memory(),
          locationStreamSource: FakeLocationStreamSource(
            fixedSamples: [
              LocationSample(
                point: const GeoPoint(lat: 9.0765, lng: 7.3986),
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
              const RecentPlace(
                label: 'Garki Area 11',
                location: GeoPoint(lat: 9.03, lng: 7.49),
              ),
            ],
          ),
        ),
      );
      addTearDown(() {
        fake.dispose();
        container.dispose();
      });
      container.read(homeControllerProvider);
      await tester.pumpWidget(
        app(container, const DestinationSearchScreen(), brightness, scale),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('search_choose_on_map')), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/rider_search_$name.png'),
      );
      // Keyboard up (the field autofocuses): shortcuts stay above it and
      // the list scrolls instead of overflowing.
      expect(
        tester.testTextInput.isVisible || tester.testTextInput.hasAnyClients,
        isTrue,
      );
      tester.view.viewInsets = FakeViewPadding(
        bottom: 300 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      final pin = tester.getRect(find.byKey(const Key('search_choose_on_map')));
      expect(pin.bottom, lessThan(800 - 300));
      tester.view.resetViewInsets();
      await tester.pump(const Duration(milliseconds: 300));
      // Typing swaps suggestions for typed results with place-type icons.
      await tester.enterText(find.byType(TextField).first, 'Wu');
      final first = find.byKey(const Key('result_Wuse Market'));
      for (var i = 0; i < 30 && first.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(first, findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/rider_search_results_$name.png'),
      );
    });

    testWidgets('rider trip options $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        planTripResponse: samplePlanTripResponse(),
      );
      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: config(),
          supabase: fake,
          ambientChannel: FakeAmbientChannel(),
          database: AlongDatabase.memory(),
          recentPlacesStore: FakeRecentPlacesStore(),
        ),
      );
      container
          .read(tripPlanSessionProvider.notifier)
          .setSession(
            const TripPlanSession(
              origin: GeoPoint(lat: 9.0765, lng: 7.3986),
              destination: GeoPoint(lat: 9.08, lng: 7.45),
              destinationLabel: 'Area 1 Park',
            ),
          );
      addTearDown(() {
        fake.dispose();
        container.dispose();
      });
      await tester.pumpWidget(
        app(container, const TripOptionsScreen(), brightness, scale),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      final card = find.byKey(const Key('option_card_cand-direct-1'));
      for (var i = 0; i < 40 && card.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(card, findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/rider_trip_options_$name.png'),
      );
    });

    testWidgets('rider trip options three $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        planTripResponse: sampleThreeOptionPlanTripResponse(),
      );
      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: config(),
          supabase: fake,
          ambientChannel: FakeAmbientChannel(),
          database: AlongDatabase.memory(),
          recentPlacesStore: FakeRecentPlacesStore(),
        ),
      );
      container
          .read(tripPlanSessionProvider.notifier)
          .setSession(
            const TripPlanSession(
              origin: GeoPoint(lat: 9.0765, lng: 7.3986),
              destination: GeoPoint(lat: 9.08, lng: 7.45),
              destinationLabel: 'Area 1 Park',
            ),
          );
      addTearDown(() {
        fake.dispose();
        container.dispose();
      });
      await tester.pumpWidget(
        app(container, const TripOptionsScreen(), brightness, scale),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      final card = find.byKey(const Key('option_card_cand-keke'));
      for (var i = 0; i < 40 && card.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(card, findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/rider_trip_options_three_$name.png'),
      );
    });
  }
}
