import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/safety/presentation/safety_kit.dart';
import 'package:mobile_rider/features/safety/presentation/sos_active_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';

import 'support/trip_options_fixtures.dart';

void main() {
  testWidgets('SOS 2G gate: raise_sos within 10 s is ready to call 112', (
    tester,
  ) async {
    final trip = tripSummaryFromFixture(
      sampleAcceptedTripResponse(heading: 90),
    );
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
          builder: (context, state) =>
              SosActiveScreen(args: SosActiveRouteArgs(trip: trip)),
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
    expect(find.byKey(const Key('sos_status_sending')), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 10));
    stopwatch.stop();

    expect(fakeSupabase.raiseSosInvokeCount, 1);
    expect(find.byKey(const Key('sos_team_alerted')), findsOneWidget);
    expect(find.byKey(const Key('sos_call_emergency')), findsOneWidget);
    expect(find.text('Call 112'), findsOneWidget);
    expect(stopwatch.elapsed.inSeconds, lessThanOrEqualTo(10));

    fakeSupabase.dispose();
    container.dispose();
  });

  testWidgets('112 needs a full hold; I\'m safe needs a confirm', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final trip = tripSummaryFromFixture(sampleAcceptedTripResponse());
    final fake = FakeAlongSupabase(
      configRows: defaultTestConfigRows(),
      requestTripResponse: sampleAcceptedTripResponse(),
    );
    final launched = <Uri>[];
    final container = ProviderContainer(
      overrides: [
        ...buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fake,
          ambientChannel: FakeAmbientChannel(),
          database: AlongDatabase.memory(),
          wayfindingTts: FakeWayfindingTts(),
        ),
        safetyLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
      ],
    );
    addTearDown(() {
      fake.dispose();
      container.dispose();
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('trip')),
        ),
        GoRoute(
          path: '/sos',
          builder: (context, state) =>
              SosActiveScreen(args: SosActiveRouteArgs(trip: trip)),
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
    router.push('/sos');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sos_team_alerted')), findsOneWidget);

    final ring = find.byKey(const Key('sos_call_emergency'));
    // A brush is not a call.
    var gesture = await tester.startGesture(tester.getCenter(ring));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(launched, isEmpty);
    // A full hold dials.
    gesture = await tester.startGesture(tester.getCenter(ring));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(launched.single.toString(), 'tel:112');

    // Back out of the alert only through the confirm.
    await tester.tap(find.byKey(const Key('sos_hold_cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sos_keep_alert')));
    await tester.pumpAndSettle();
    expect(fake.updateSosInvokeCount, 0);
    await tester.tap(find.byKey(const Key('sos_hold_cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sos_confirm_safe')));
    await tester.pumpAndSettle();
    expect(fake.updateSosInvokeCount, 1);
    expect(find.text('trip'), findsOneWidget);
  });
}
