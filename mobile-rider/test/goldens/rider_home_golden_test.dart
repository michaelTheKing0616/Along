import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/home/presentation/widgets/home_chrome.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Real rider home sheet + tab bar over the map land colour, the way
/// HomeScreen composes them. The native map is out of scope for goldens.
void main() {
  setUpAll(() async {
    // Icon fonts (Phosphor) from the manifest, then Geist/Inter by bare name.
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

  const state = HomeState(
    cityName: 'Abuja',
    userLocation: GeoPoint(lat: 9.072, lng: 7.481),
    recents: [
      RecentPlace(
        label: 'Wuse Market',
        location: GeoPoint(lat: 9.06, lng: 7.47),
      ),
      RecentPlace(
        label: 'Garki Area 11',
        location: GeoPoint(lat: 9.03, lng: 7.49),
      ),
    ],
    nearbyRows: [
      NearbyAmbientRow(
        modeLabel: 'Keke',
        countBucket: '3-5',
        headingLabel: 'NE',
        etaMinutes: 3,
        modeCode: 'keke',
      ),
      NearbyAmbientRow(
        modeLabel: 'Danfo',
        countBucket: '1-2',
        headingLabel: 'S',
        etaMinutes: 6,
        modeCode: 'danfo',
      ),
    ],
  );

  Widget home(Brightness brightness, double scale) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: alongTheme(brightness: brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          // A phone's status bar and home indicator, to prove safe areas.
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          final palette = AlongPalette.of(context);
          return Scaffold(
            backgroundColor: palette.mapLand,
            bottomNavigationBar: ColoredBox(
              color: palette.surface,
              child: AlongTabBar(
                tabs: const [
                  (AlongIcons.home, 'Home'),
                  (AlongIcons.path, 'Trips'),
                  (AlongIcons.user, 'Account'),
                ],
                onSelect: (_) {},
              ),
            ),
            body: Stack(
              children: [
                // Stand-in for the native map, which goldens cannot draw.
                const Positioned.fill(child: AlongRoutePreview(route: false)),
                Positioned.fill(
                  child: HomeChrome(
                    state: state,
                    now: DateTime(2026, 10, 26, 15),
                    onMenu: () {},
                    onVehicles: () {},
                    onRecenter: () {},
                    onSearch: () {},
                    onRecent: (_) {},
                    onNearby: (_) {},
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  for (final (name, brightness, scale) in [
    ('light', Brightness.light, 1.0),
    ('dark', Brightness.dark, 1.0),
    ('light_1_3x', Brightness.light, 1.3),
  ]) {
    testWidgets('rider home $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(home(brightness, scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('home_where_to')), findsOneWidget);
      expect(find.byKey(const Key('nearby_row_keke')), findsOneWidget);
      expect(find.text('Good afternoon'), findsOneWidget);
      expect(find.text('~3 min'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('rider_home_$name.png'),
      );
    });
  }
}
