import 'package:along_data/along_data.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/routes/presentation/fast_route_setup_controller.dart';
import 'package:mobile_driver/features/routes/presentation/fast_route_setup_screen.dart';
import 'package:mobile_driver/features/routes/presentation/widgets/route_widgets.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SuggestedKnownRoute testSuggestedRoute() => SuggestedKnownRoute.fromJson({
      'route': {
        'id': 'route-id',
        'mode_code': 'keke',
      },
      'stages': [
        {
          'stage': {
            'id': 'stage-1',
            'sequence': 1,
            'name': 'Lugbe Park',
          },
          'default_price_to_end': 400,
        },
        {
          'stage': {
            'id': 'stage-2',
            'sequence': 2,
            'name': 'Area 1',
          },
          'default_price_to_end': 0,
        },
      ],
    });

Map<String, dynamic> testSuggestedRouteJson() {
  final suggestion = testSuggestedRoute();
  return {
    'route': {
      'id': suggestion.routeId,
      'mode_code': suggestion.modeCode,
    },
    'stages': [
      for (final stage in suggestion.stages)
        {
          'stage': {
            'id': stage.stageId,
            'sequence': stage.sequence,
            'name': stage.name,
          },
          'default_price_to_end': stage.defaultPriceToEnd,
        },
    ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('D-11 fast route publish', () {
    late FakeAlongSupabase fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeAlongSupabase(
        signedInUser: User(
          id: 'test-driver-id',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
        suggestedRoute: testSuggestedRouteJson(),
      );

      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fake,
          database: AlongDatabase.memory(),
        ),
      );
    });

    tearDown(() {
      fake.dispose();
      container.dispose();
    });

    testWidgets('pre-matched route publishes in one tap', (tester) async {
      var publishCalls = 0;
      fake.onUpsertRouteProfile = (_) => publishCalls++;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                FastRouteSetupScreen(suggestion: testSuggestedRoute()),
          ),
        ],
      );

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
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fast_route_publish_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('fast_route_publish_button')));
      await tester.pumpAndSettle();

      expect(publishCalls, 1);
    });

    test('non-monotone prices disable publish', () {
      final suggestion = testSuggestedRoute();
      final keepAlive = container.listen(
        fastRouteSetupControllerProvider(suggestion),
        (_, __) {},
      );
      final controller = container.read(
        fastRouteSetupControllerProvider(suggestion).notifier,
      );
      controller.updateStopPrice(1, Decimal.fromInt(200));
      controller.updateStopPrice(2, Decimal.fromInt(400));

      final state = container.read(fastRouteSetupControllerProvider(suggestion));

      expect(state.priceValidation.isValid, isFalse);
      expect(state.canPublish, isFalse);
      keepAlive.close();
    });
  });

  group('manual snap chip', () {
    testWidgets('shows Matched chip for nearby existing stage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SnapStatusChip(
              matchedName: 'Berger Junction',
              isNewStop: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('Matched: Berger Junction'), findsOneWidget);
      expect(find.byKey(const Key('snap_matched_Berger Junction')), findsOneWidget);
    });
  });
}
