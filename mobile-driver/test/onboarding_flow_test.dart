import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/app.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';
import 'package:mobile_driver/features/onboarding/presentation/auth_controller.dart';
import 'package:mobile_driver/features/onboarding/presentation/phone_entry_screen.dart';
import 'package:mobile_driver/features/profile/presentation/profile_screen.dart';
import 'package:mobile_driver/features/vehicle/presentation/vehicle_screen.dart';
import 'package:mobile_driver/routing/app_router.dart';
import 'package:mobile_driver/routing/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('D-01 through D-07 driver onboarding', () {
    late FakeAlongSupabase fakeSupabase;
    late FakeDriverOnboardingPreferences fakePrefs;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        countryConfig: {
          'code': 'NG',
          'phone_prefix': '+234',
          'currency_code': 'NGN',
          'currency_symbol': '₦',
          'currency_minor_units': 2,
          'verification_schema': [
            {'type': 'nin', 'label': 'NIN', 'pattern': r'^\d{11}$'},
          ],
          'regulatory_flags': {
            'plate_pattern': r'^[A-Za-z]{3}[-\s]?\d{3}[A-Za-z]{2}$',
          },
        },
      );
      fakePrefs = FakeDriverOnboardingPreferences();
      container = ProviderContainer(
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
    });

    tearDown(() {
      container.read(authControllerProvider.notifier).clearPhone();
      fakeSupabase.dispose();
      container.dispose();
    });

    Future<void> pumpDriverApp(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlongDriverApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
    }

    testWidgets('auth → profile → vehicle → documents → pending', (
      tester,
    ) async {
      await pumpDriverApp(tester);
      expect(find.byType(PhoneEntryScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '8012345678');
      await tester.tap(find.byKey(const Key('phone_continue_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('profile_name_field')),
        'Musa',
      );
      await tester.tap(find.byKey(const Key('profile_continue_button')));
      await tester.pumpAndSettle();
      expect(find.byType(VehicleScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('mode_chip_keke')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('vehicle_plate_field')),
        'ABC-123DE',
      );
      await tester.tap(find.byKey(const Key('vehicle_continue_button')));
      await tester.pumpAndSettle();

      expect(find.text('Verify your documents'), findsOneWidget);

      container.read(authControllerProvider.notifier).clearPhone();
      await tester.pump();
    });

    testWidgets('OCR never pre-fills sensitive fields before confirm', (
      tester,
    ) async {
      final ocrFakeSupabase = FakeAlongSupabase(
        signedInUser: User(
          id: 'test-driver-id',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      final ocrFakePrefs = FakeDriverOnboardingPreferences(
        step: DriverOnboardingStep.documents,
        country: 'NG',
        storedVehicleId: 'test-vehicle-id',
      );
      final ocrContainer = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: ocrFakeSupabase,
          onboardingPreferences: ocrFakePrefs,
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ocrContainer,
          child: const AlongDriverApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      ocrContainer.read(routerProvider).go(AppRoutes.documents);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('doc_row_nin')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('capture_test_image_button')));
      await tester.pumpAndSettle();

      final ninField = tester.widget<TextField>(
        find.byKey(const Key('ocr_field_nin')),
      );
      expect(ninField.controller?.text ?? '', isEmpty);
      expect(find.byKey(const Key('ocr_confirm_nin')), findsOneWidget);

      ocrFakeSupabase.dispose();
      ocrContainer.dispose();
    });
  });
}
