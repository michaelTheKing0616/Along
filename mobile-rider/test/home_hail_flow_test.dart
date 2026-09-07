import 'package:along_core/along_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/home/presentation/widgets/home_bottom_sheet.dart';
import 'package:mobile_rider/features/pricing/domain/hail_intent_provider.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_helpers.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';
import 'package:along_map/along_map.dart' show AbujaMapConstants;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R-05 hail-from-cell routing (P2-B-02)', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        ambientCells: [sampleAmbientCell(candidateToken: 'tok-hail-1')],
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
          clock: Clock.fixed(DateTime.utc(2026, 1, 1, 0, 1, 0)),
        ),
      );

      router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const _NearbyRowHarness(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const _HailSearchHarness(),
          ),
          GoRoute(
            path: AppRoutes.tripOptions,
            builder: (context, state) =>
                const Scaffold(body: Text('trip_options_stub')),
          ),
          GoRoute(
            path: AppRoutes.pricing,
            builder: (context, state) =>
                const Scaffold(body: Text('pricing_stub')),
          ),
        ],
      );
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('nearby row tap lands on R-07 with hail intent not pricing',
        (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('nearby_row_keke')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(router.state.matchedLocation, AppRoutes.search);
      expect(router.state.matchedLocation, isNot(AppRoutes.pricing));
      expect(
        container.read(hailIntentProvider)?.candidateToken,
        'tok-hail-1',
      );

      await tester.tap(find.byKey(const Key('hail_pick_destination')));
      await tester.pump();

      expect(router.state.matchedLocation, AppRoutes.tripOptions);
      expect(router.state.matchedLocation, isNot(AppRoutes.pricing));

      final session = container.read(tripPlanSessionProvider);
      expect(session, isNotNull);
      expect(session!.isHail, isTrue);
      expect(session.hailIntent?.candidateToken, 'tok-hail-1');
      expect(container.read(hailIntentProvider), isNull);
    });
  });
}

/// Minimal R-05 nearby list harness — mirrors [HomeScreen._onNearbyRowTap].
class _NearbyRowHarness extends ConsumerWidget {
  const _NearbyRowHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const row = NearbyAmbientRow(
      modeLabel: 'Keke',
      countBucket: '3-5',
      headingLabel: 'NE',
      etaMinutes: 3,
      modeCode: 'keke',
      candidateToken: 'tok-hail-1',
      etaBandSeconds: 180,
    );

    return Scaffold(
      body: HomeNearbySheet(
        rows: const [row],
        onRowTap: (nearby) {
          final token = nearby.candidateToken;
          if (token == null) {
            context.push(AppRoutes.search);
            return;
          }
          ref.read(hailIntentProvider.notifier).state = HailIntent(
            candidateToken: token,
            modeCode: nearby.modeCode,
            etaBandSeconds: nearby.etaBandSeconds ?? nearby.etaMinutes * 60,
          );
          context.push(AppRoutes.search);
        },
      ),
    );
  }
}

/// Stub R-06 hail destination pick — uses production [_startTripPlan] helpers.
class _HailSearchHarness extends ConsumerWidget {
  const _HailSearchHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('hail_pick_destination'),
          onPressed: () {
            _startTripPlan(
              ref,
              'Area 1 Park',
              const GeoPoint(lat: 9.08, lng: 7.45),
            );
            _afterDestinationSelected(context, ref);
          },
          child: const Text('Pick destination'),
        ),
      ),
    );
  }
}

void _startTripPlan(WidgetRef ref, String label, GeoPoint destination) {
  final hail = ref.read(hailIntentProvider);
  ref.read(tripPlanSessionProvider.notifier).setSession(
        TripPlanSession(
          origin: const GeoPoint(
            lat: AbujaMapConstants.centerLat,
            lng: AbujaMapConstants.centerLng,
          ),
          destination: destination,
          destinationLabel: label,
          hailIntent: hail,
        ),
      );
}

void _afterDestinationSelected(BuildContext context, WidgetRef ref) {
  ref.read(hailIntentProvider.notifier).state = null;
  context.push(AppRoutes.tripOptions);
}
