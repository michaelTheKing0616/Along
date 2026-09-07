import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/account/presentation/account_screen.dart';
import 'package:mobile_driver/features/safety/presentation/report_incident_screen.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_driver/testing/fakes/fake_driver_channel.dart';

void main() {
  group('D-16 report incident', () {
    testWidgets('submits selected category and description', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeSupabase = FakeAlongSupabase();
      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          driverChannel: FakeDriverChannel(),
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byKey(const Key('incident_category_safety')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(find.byType(TextField), 'Rider was rude');
      await tester.tap(find.byKey(const Key('report_incident_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(fakeSupabase.reportIncidentInvokeCount, 1);
      expect(fakeSupabase.lastReportIncidentParams?['p_type'], 'safety');

      fakeSupabase.dispose();
      container.dispose();
    });
  });

  group('D-24 account', () {
    testWidgets('shows profile, documents, payout, and sign out', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeSupabase = FakeAlongSupabase();
      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          driverChannel: FakeDriverChannel(),
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AccountScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('account_profile_tile')), findsOneWidget);
      expect(find.byKey(const Key('account_my_qr_link')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('account_safety_tile')),
        500,
      );
      expect(find.byKey(const Key('account_safety_tile')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('account_sign_out')),
        500,
      );
      expect(find.byKey(const Key('account_sign_out')), findsOneWidget);

      fakeSupabase.dispose();
      container.dispose();
    });
  });
}
