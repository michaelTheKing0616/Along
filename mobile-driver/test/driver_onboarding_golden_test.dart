import 'dart:convert';
import 'dart:io';

import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/onboarding/presentation/auth_controller.dart';
import 'package:mobile_driver/features/onboarding/presentation/launch_screen.dart';
import 'package:mobile_driver/features/onboarding/presentation/otp_screen.dart';
import 'package:mobile_driver/features/onboarding/presentation/permissions_screen.dart';
import 'package:mobile_driver/features/onboarding/presentation/phone_entry_screen.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/features/connection/connection_banner_host.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';

class _Seeded extends AuthController {
  _Seeded(this.seed);

  final AuthState seed;

  @override
  AuthState build() => seed;

  void reseed() => state = seed;
}

/// Phone, code and permission priming: every state,
/// light/dark/1.3x.
void main() {
  setUpAll(() async {
    final manifest = await rootBundle.loadStructuredData<List<dynamic>>(
      'FontManifest.json',
      (s) async => json.decode(s) as List<dynamic>,
    );
    for (final entry in manifest) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in entry['fonts'] as List<dynamic>) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
    await AlongFonts.ensureLoaded();
  });

  const phone = '+2348012345678';
  const sent = AuthState(phoneE164: phone, resendSecondsRemaining: 24);

  final cases = <(String, Widget, AuthState, bool, String?)>[
    ('phone_empty', const PhoneEntryScreen(), const AuthState(), true, null),
    (
      'phone_filled',
      const PhoneEntryScreen(),
      const AuthState(),
      true,
      '8012345678',
    ),
    (
      'phone_invalid',
      const PhoneEntryScreen(),
      const AuthState(errorMessage: 'invalid_phone'),
      true,
      '1112223333',
    ),
    (
      'phone_sending',
      const PhoneEntryScreen(),
      const AuthState(isSubmitting: true),
      true,
      '8012345678',
    ),
    (
      'phone_rate_limited',
      const PhoneEntryScreen(),
      const AuthState(errorMessage: 'rate_limited', rateLimitRetrySeconds: 45),
      true,
      '8012345678',
    ),
    (
      'phone_error',
      const PhoneEntryScreen(),
      const AuthState(errorMessage: 'generic'),
      true,
      '8012345678',
    ),
    (
      'phone_offline',
      const PhoneEntryScreen(),
      const AuthState(),
      false,
      '8012345678',
    ),
    ('otp_sent', const OtpScreen(), sent, true, null),
    ('otp_partial', const OtpScreen(), sent, true, '123'),
    (
      'otp_checking',
      const OtpScreen(),
      const AuthState(
        phoneE164: phone,
        isSubmitting: true,
        resendSecondsRemaining: 20,
      ),
      true,
      '123456',
    ),
    (
      'otp_wrong',
      const OtpScreen(),
      const AuthState(
        phoneE164: phone,
        errorMessage: 'wrong_otp',
        resendSecondsRemaining: 12,
      ),
      true,
      null,
    ),
    (
      'otp_expired',
      const OtpScreen(),
      const AuthState(phoneE164: phone, errorMessage: 'expired_otp'),
      true,
      null,
    ),
    (
      'otp_resend_ready',
      const OtpScreen(),
      const AuthState(phoneE164: phone),
      true,
      null,
    ),
    (
      'otp_rate_limited',
      const OtpScreen(),
      const AuthState(
        phoneE164: phone,
        errorMessage: 'rate_limited',
        rateLimitRetrySeconds: 60,
      ),
      true,
      null,
    ),
    ('otp_offline', const OtpScreen(), sent, false, null),
    ('launch', const LaunchScreen(), const AuthState(), true, null),
    ('permissions', const PermissionsScreen(), const AuthState(), true, null),
  ];

  for (final (name, brightness, scale) in [
    ('light', Brightness.light, 1.0),
    ('dark', Brightness.dark, 1.0),
    ('light_1_3x', Brightness.light, 1.3),
  ]) {
    for (final (state, screen, seed, online, typed) in cases) {
      testWidgets('driver onboarding $state $name', (tester) async {
        if (state.startsWith('phone_')) {
          // The decoded hero photo resamples a few pixels differently on
          // CI's Skia; allow 0.1% on the photo shots only.
          final strict = goldenFileComparator;
          goldenFileComparator = _Tolerant(
            Uri.parse(
              '${Directory.current.path}/test/driver_onboarding_golden_test.dart',
            ),
          );
          addTearDown(() => goldenFileComparator = strict);
        }
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final supabase = FakeAlongSupabase();
        addTearDown(supabase.dispose);
        final container = ProviderContainer(
          overrides: [
            ...buildProviderOverrides(
              config: const AppConfig(
                flavor: 'dev',
                supabaseUrl: 'https://test.supabase.co',
                supabaseAnonKey: 'test-key',
              ),
              supabase: supabase,
              onboardingPreferences: FakeDriverOnboardingPreferences(),
            ),
            connectionSourceProvider.overrideWithValue(
              FakeConnectionSource(online: online),
            ),
            authControllerProvider.overrideWith(() => _Seeded(seed)),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: alongTheme(brightness: brightness),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
                ),
                child: child!,
              ),
              home: screen,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(
              'assets/photos/onboarding-fleet.jpg',
              package: 'along_design',
            ),
            tester.element(find.byType(Scaffold).first),
          ),
        );
        if (typed != null) {
          final field = find.byType(TextField).first;
          final ctrl = tester.widget<TextField>(field).controller!;
          // Seed without the change callback so seeded errors survive.
          ctrl.value = TextEditingValue(
            text: screen is PhoneEntryScreen
                ? AlongPhoneGroupFormatter.group(typed)
                : typed,
          );
          (container.read(authControllerProvider.notifier) as _Seeded).reseed();
          await tester.pump();
        }
        // The splash routes away after 300 ms; shoot it before that.
        if (screen is! LaunchScreen) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/driver_onboarding_${state}_$name.png'),
        );
        // Let the splash timer and any countdown finish before teardown.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}

class _Tolerant extends LocalFileComparator {
  _Tolerant(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= 0.001) return true;
    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}
