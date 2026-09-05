import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/trip_options_fixtures.dart';

void main() {
  group('R-18 coverage gap', () {
    testWidgets('shows honest empty state when planner returns no candidates', (tester) async {
      final fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        planTripResponse: samplePlanTripResponse(includeCoverageGap: true),
      );

      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          ambientChannel: FakeAmbientChannel(),
          recentPlacesStore: FakeRecentPlacesStore(),
          clock: Clock.fixed(DateTime.utc(2026, 9, 5, 14, 0, 0)),
        ),
      );
      container.read(tripPlanSessionProvider.notifier).setSession(
            const TripPlanSession(
              origin: GeoPoint(lat: 9.0765, lng: 7.3986),
              destination: GeoPoint(lat: 9.08, lng: 7.45),
              destinationLabel: 'Remote area',
            ),
          );

      addTearDown(() {
        fakeSupabase.dispose();
        container.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TripOptionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No mapped routes here yet'), findsOneWidget);
      expect(find.textContaining('Dutse Junction'), findsOneWidget);
      expect(find.text('Vehicles nearby: none'), findsOneWidget);
      expect(find.byType(OptionCard), findsNothing);
    });
  });
}
