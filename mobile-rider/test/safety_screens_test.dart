import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/account/presentation/account_settings_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/active_trip_screen.dart';
import 'package:mobile_rider/features/safety/presentation/report_incident_screen.dart';
import 'package:mobile_rider/features/safety/presentation/share_trip_sheet.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';

import 'support/trip_options_fixtures.dart';

void main() {
  group('R-24 report incident', () {
    testWidgets('submits selected category and description', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeSupabase = FakeAlongSupabase(configRows: defaultTestConfigRows());
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

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ReportIncidentScreen(tripId: 'trip-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('incident_category_safety')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Driver was speeding');
      await tester.tap(find.byKey(const Key('report_incident_submit')));
      await tester.pumpAndSettle();

      expect(fakeSupabase.reportIncidentInvokeCount, 1);
      expect(fakeSupabase.lastReportIncidentParams?['p_type'], 'safety');

      fakeSupabase.dispose();
      container.dispose();
    });
  });

  group('R-25 share trip', () {
    testWidgets('creates share link from active trip', (tester) async {
      final trip = tripSummaryFromFixture(sampleAcceptedTripResponse());
      final fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: sampleAcceptedTripResponse(),
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

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => ShareTripSheet.show(
                      context,
                      journeyId: trip.journeyId,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('share_trip_create')));
      await tester.pumpAndSettle();

      expect(fakeSupabase.createTripShareInvokeCount, 1);
      expect(find.textContaining('https://along.ng/s/'), findsOneWidget);

      fakeSupabase.dispose();
      container.dispose();
    });
  });

  group('R-26 account settings', () {
    testWidgets('shows women-only when regulatory flag enabled', (tester) async {
      final fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        cityRegulatoryFlags: const {'women_only_matching': true},
      );
      await fakeSupabase.verifyOtp(phone: '+2348000000001', token: '123456');
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

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AccountSettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('account_women_only')), findsOneWidget);
      expect(find.byKey(const Key('account_payment_cash')), findsOneWidget);

      fakeSupabase.dispose();
      container.dispose();
    });
  });
}
