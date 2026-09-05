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
  group('TS-UI-01 one-tap request (doc 06 Part C)', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        planTripResponse: samplePlanTripResponse(),
        requestTripResponse: sampleRequestTripResponse(),
      );
      container = ProviderContainer(
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
              destinationLabel: 'Area 1 Park',
            ),
          );
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('request on option card footer is exactly one tap', (tester) async {
      var requestTapCount = 0;

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

      await _waitForCandidates(tester);

      final requestButton = find.descendant(
        of: find.byKey(const Key('option_card_cand-direct-1')),
        matching: find.byType(AlongButton),
      );
      expect(requestButton, findsOneWidget);

      await tester.tap(
        requestButton,
        warnIfMissed: false,
      );
      requestTapCount++;

      await tester.pump();

      expect(requestTapCount, 1);
      expect(
        container.read(tripOptionsControllerProvider).pendingRequestCandidateId,
        'cand-direct-1',
      );
      expect(find.text('Requesting…'), findsOneWidget);
    });
  });
}

Future<void> _waitForCandidates(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byKey(const Key('option_card_cand-direct-1')).evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for trip option cards');
}
