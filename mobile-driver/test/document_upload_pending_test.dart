import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/app.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/documents/presentation/documents_controller.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';
import 'package:mobile_driver/features/verification/presentation/verification_pending_screen.dart';
import 'package:mobile_driver/routing/app_router.dart';
import 'package:mobile_driver/routing/routes.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('document upload navigates to verification pending', (tester) async {
    var didSubmit = false;
    final fakeSupabase = FakeAlongSupabase(
      signedInUser: User(
        id: 'test-driver-id',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
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
    fakeSupabase.onSubmitVerification = (_) => didSubmit = true;

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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlongDriverApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 900));

    container.read(routerProvider).go(AppRoutes.documents);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('doc_row_nin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture_test_image_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ocr_confirm_nin')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('submit_document_button')));
    await tester.tap(find.byKey(const Key('submit_document_button')));
    await tester.pumpAndSettle();

    expect(didSubmit, isTrue);
    expect(fakeSupabase.verifications.length, 1);
    expect(fakePrefs.step, DriverOnboardingStep.pending);
    expect(find.text("We're reviewing your documents"), findsOneWidget);

    fakeSupabase.dispose();
    container.dispose();
  });
}
