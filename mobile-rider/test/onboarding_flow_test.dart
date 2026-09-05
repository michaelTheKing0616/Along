import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/app.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/features/onboarding/presentation/name_screen.dart';
import 'package:mobile_rider/features/onboarding/presentation/phone_entry_screen.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R-01 through R-04 onboarding flow', () {
    late FakeAlongSupabase fakeSupabase;
    late FakeOnboardingPreferences fakePrefs;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase();
      fakePrefs = FakeOnboardingPreferences();
      container = ProviderContainer(
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
    });

    tearDown(() {
      container.read(onboardingControllerProvider.notifier).clearPhone();
      fakeSupabase.dispose();
      container.dispose();
    });

    Future<void> pumpOnboardingApp(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlongRiderApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
    }

    testWidgets('navigates launch → phone → otp → name → complete with mocked auth',
        (tester) async {
      String? requestedPhone;
      String? verifiedToken;
      String? savedName;

      fakeSupabase.onRequestOtp = (phone) => requestedPhone = phone;
      fakeSupabase.onVerifyOtp = (phone, token) => verifiedToken = token;
      fakeSupabase.onCompleteOnboarding = (name) => savedName = name;

      await pumpOnboardingApp(tester);

      expect(find.byType(PhoneEntryScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '8012345678');
      await tester.tap(find.byKey(const Key('phone_continue_button')));
      await tester.pumpAndSettle();

      expect(requestedPhone, '+2348012345678');
      expect(find.textContaining('Enter the 6-digit code'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      expect(verifiedToken, '123456');
      expect(find.byType(NameScreen), findsOneWidget);

      await tester.enterText(find.byKey(const Key('name_field')), 'Ada');
      await tester.tap(find.byKey(const Key('name_continue_button')));
      await tester.pumpAndSettle();

      expect(savedName, 'Ada');
      expect(fakePrefs.complete, isTrue);
      expect(find.text('Where to?'), findsWidgets);

      container.read(onboardingControllerProvider.notifier).clearPhone();
      await tester.pump();
    });

    testWidgets('skip on name screen completes without display name', (tester) async {
      fakeSupabase.onCompleteOnboarding = (_) {};

      await pumpOnboardingApp(tester);

      await tester.enterText(find.byType(TextField).first, '9012345678');
      await tester.tap(find.byKey(const Key('phone_continue_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('name_skip_button')));
      await tester.pumpAndSettle();

      expect(fakePrefs.complete, isTrue);
      expect(find.byKey(const Key('name_field')), findsNothing);

      container.read(onboardingControllerProvider.notifier).clearPhone();
      await tester.pump();
    });
  });
}
