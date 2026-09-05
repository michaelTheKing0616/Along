import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/app.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:patrol/patrol.dart';

/// Patrol OTP flow (R-02 → R-03) — requires emulator + dev env file.
///
/// SKIP on this worker: no Android/iOS emulator connected (only macOS/Chrome).
/// Widget coverage: `test/onboarding_flow_test.dart`.
void main() {
  const skipPatrol = bool.fromEnvironment(
    'PATROL_HAS_EMULATOR',
    defaultValue: false,
  );

  patrolTest(
    'R-02 phone entry sends OTP and R-03 verifies code',
    ($) async {
      final fakeSupabase = FakeAlongSupabase();
      final fakePrefs = FakeOnboardingPreferences();
      var otpRequested = false;

      fakeSupabase.onRequestOtp = (_) => otpRequested = true;

      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          ambientChannel: FakeAmbientChannel(),
          onboardingPreferences: fakePrefs,
        ),
      );

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: container,
          child: const AlongRiderApp(),
        ),
        timeout: const Duration(seconds: 5),
      );

      await $.pumpAndSettle(timeout: const Duration(seconds: 2));

      await $(TextField).enterText('8012345678');
      await $(#phone_continue_button).tap();
      await $.pumpAndSettle();

      expect(otpRequested, isTrue);

      await $(TextField).at(1).enterText('123456');
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));

      expect(find.textContaining('What should drivers call you?'), findsOneWidget);

      fakeSupabase.dispose();
      container.dispose();
    },
    skip: skipPatrol ? null : true,
  );
}
