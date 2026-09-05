import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/app.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';
import 'package:mobile_driver/features/verification/presentation/verification_pending_screen.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:patrol/patrol.dart';

/// Patrol document upload → pending flow on iOS — skipped unless PATROL_IOS=true.
///
/// Android counterpart: `document_upload_patrol_test.dart` (PATROL_HAS_EMULATOR).
/// Widget coverage: `test/onboarding_flow_test.dart`.
void main() {
  const skipPatrol = bool.fromEnvironment(
    'PATROL_IOS',
    defaultValue: false,
  );

  patrolTest(
    'iOS document upload advances to verification pending',
    ($) async {
      final fakeSupabase = FakeAlongSupabase(
        countryConfig: {
          'code': 'NG',
          'verification_schema': [
            {
              'type': 'nin',
              'label': 'NIN',
              'pattern': r'^\d{11}$',
            },
          ],
          'regulatory_flags': {
            'plate_pattern': r'^[A-Za-z]{3}[-\s]?\d{3}[A-Za-z]{2}$',
          },
        },
      );
      final fakePrefs = FakeDriverOnboardingPreferences(
        step: DriverOnboardingStep.documents,
        country: 'NG',
        storedVehicleId: 'test-vehicle-id',
      );

      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          onboardingPreferences: fakePrefs,
        ),
      );

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: container,
          child: const AlongDriverApp(),
        ),
        timeout: const Duration(seconds: 5),
      );

      await $(#doc_row_nin).tap();
      await $.pumpAndSettle();
      await $(#capture_test_image_button).tap();
      await $.pumpAndSettle();
      await $(#ocr_confirm_nin).tap();
      await $.pumpAndSettle();
      await $(#submit_document_button).tap();
      await $.pumpAndSettle();

      expect(find.byType(VerificationPendingScreen), findsOneWidget);

      fakeSupabase.dispose();
      container.dispose();
    },
    skip: skipPatrol ? null : true,
  );
}
