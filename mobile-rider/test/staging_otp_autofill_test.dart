import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
const _key = 'staging-smoke-key-0123456789abcdef';

AppConfig _config(String flavor, String? key) => AppConfig(
      flavor: flavor,
      supabaseUrl: 'https://test.supabase.co',
      supabaseAnonKey: 'test-key',
      stagingOtpKey: key,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STAGING_OTP_KEY flavor gate', () {
    test('a prod or dev build carrying the key refuses to start', () {
      for (final flavor in ['prod', 'dev']) {
        expect(
          () => AppConfig.assertStagingOtpKeyAllowed(flavor, _key),
          throwsStateError,
        );
      }
    });

    test('builds without the key, and staging with it, start', () {
      AppConfig.assertStagingOtpKeyAllowed('prod', null);
      AppConfig.assertStagingOtpKeyAllowed('prod', '');
      AppConfig.assertStagingOtpKeyAllowed('staging', _key);
    });

    test('this test build defines no key', () {
      expect(AppConfig.fromEnvironment().stagingOtpKey, isNull);
    });

    test('auto-fill only for staging with a key', () {
      expect(_config('staging', _key).stagingOtpAutofillEnabled, isTrue);
      expect(_config('staging', null).stagingOtpAutofillEnabled, isFalse);
      expect(_config('staging', '').stagingOtpAutofillEnabled, isFalse);
      expect(_config('prod', _key).stagingOtpAutofillEnabled, isFalse);
      expect(_config('dev', _key).stagingOtpAutofillEnabled, isFalse);
    });
  });

  group('peekStagingOtp', () {
    Future<(String?, FakeAlongSupabase)> peek(String flavor, String? key) async {
      final fake = FakeAlongSupabase()..stagingOtpCode = '482913';
      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: _config(flavor, key),
          supabase: fake,
          ambientChannel: FakeAmbientChannel(),
        ),
      );
      addTearDown(container.dispose);
      final notifier = container.read(onboardingControllerProvider.notifier);
      expect(await notifier.requestOtp('8012345678'), isTrue);
      return (await notifier.peekStagingOtp(), fake);
    }

    test('staging + key calls staging-otp with the key header', () async {
      final (code, fake) = await peek('staging', _key);
      expect(code, '482913');
      expect(fake.stagingOtpCalls, hasLength(1));
      expect(fake.stagingOtpCalls.single.$1['phone'], startsWith('+234'));
      expect(fake.stagingOtpCalls.single.$2['x-staging-otp-key'], _key);
    });

    for (final (flavor, key) in [
      ('prod', _key),
      ('dev', _key),
      ('staging', null),
      ('prod', null),
    ]) {
      test('$flavor build (key: ${key != null}) never calls staging-otp', () async {
        final (code, fake) = await peek(flavor, key);
        expect(code, isNull);
        expect(fake.stagingOtpCalls, isEmpty);
      });
    }
  });
}
