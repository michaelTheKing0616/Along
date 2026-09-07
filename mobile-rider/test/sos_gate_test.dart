import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/safety/presentation/sos_active_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';

import 'support/trip_options_fixtures.dart';

void main() {
  testWidgets('SOS 2G gate: raise_sos within 10 s shows team alerted', (tester) async {
    final trip = tripSummaryFromFixture(sampleAcceptedTripResponse(heading: 90));
    final fakeSupabase = FakeAlongSupabase(
      configRows: defaultTestConfigRows(),
      requestTripResponse: sampleAcceptedTripResponse(heading: 90),
      raiseSosDelay: const Duration(seconds: 2),
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
        database: AlongDatabase.memory(),
        wayfindingTts: FakeWayfindingTts(),
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => SosActiveScreen(
            args: SosActiveRouteArgs(trip: trip),
          ),
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

    final stopwatch = Stopwatch()..start();
    await tester.pump();
    expect(find.text('Alerting safety team…'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 10));
    stopwatch.stop();

    expect(fakeSupabase.raiseSosInvokeCount, 1);
    expect(find.byKey(const Key('sos_team_alerted')), findsOneWidget);
    expect(find.text('Along safety team alerted'), findsOneWidget);
    expect(stopwatch.elapsed.inSeconds, lessThanOrEqualTo(10));

    fakeSupabase.dispose();
    container.dispose();
  });
}
