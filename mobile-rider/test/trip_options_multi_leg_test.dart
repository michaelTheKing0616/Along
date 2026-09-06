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
  group('P2-B-01 multi-leg trip options', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        planTripResponse: sampleMultiLegPlanTripResponse(),
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

    testWidgets('expands multi-leg card and requests leg 1 in one tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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

      await _waitForCandidate(tester, 'cand-multi-1');

      await tester.tap(find.byKey(const Key('multi_leg_toggle_cand-multi-1')));
      await tester.pumpAndSettle();

      expect(find.byType(LegTimeline), findsOneWidget);

      await tester.tap(find.byKey(const Key('leg_request_cand-multi-1_1')));
      await tester.pump();

      expect(
        container.read(tripOptionsControllerProvider).pendingRequestCandidateId,
        'cand-multi-1',
      );
      expect(
        container.read(tripOptionsControllerProvider).pendingRequestLegIndex,
        1,
      );
    });

    testWidgets('per-leg decline keeps leg 0 unrequested when leg 1 cancelled', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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

      await _waitForCandidate(tester, 'cand-multi-1');
      await tester.tap(find.byKey(const Key('multi_leg_toggle_cand-multi-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('leg_request_cand-multi-1_1')));
      await tester.pump();
      container.read(tripOptionsControllerProvider.notifier).cancelPendingRequest();
      await tester.pump();

      expect(
        container.read(tripOptionsControllerProvider).pendingRequestCandidateId,
        isNull,
      );
      expect(fakeSupabase.requestTripInvokeCount, 0);
    });

    testWidgets('shows explain popover for recommended multi-leg option', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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

      await _waitForCandidate(tester, 'cand-multi-1');
      await tester.tap(find.byKey(const Key('why_cand-multi-1')));
      await tester.pumpAndSettle();

      expect(find.text('Why recommended'), findsOneWidget);
      expect(find.text('Fare'), findsOneWidget);
    });

    testWidgets('four sort chips reorder candidates', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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

      await _waitForCandidate(tester, 'cand-multi-1');

      await tester.tap(find.text('Fastest'));
      await tester.pumpAndSettle();

      final fastestFirst = container
          .read(tripOptionsControllerProvider)
          .sortedCandidates
          .first
          .candidateId;
      expect(fastestFirst, 'cand-direct-slow');
    });
  });
}

Future<void> _waitForCandidate(WidgetTester tester, String id) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byKey(Key('option_card_$id')).evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for candidate $id');
}
