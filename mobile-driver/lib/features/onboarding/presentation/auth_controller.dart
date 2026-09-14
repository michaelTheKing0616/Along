import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';
import 'package:mobile_driver/features/onboarding/domain/phone_number_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  const AuthState({
    this.phoneE164,
    this.isSubmitting = false,
    this.errorMessage,
    this.resendSecondsRemaining = 0,
    this.rateLimitRetrySeconds,
  });

  final String? phoneE164;
  final bool isSubmitting;
  final String? errorMessage;
  final int resendSecondsRemaining;
  final int? rateLimitRetrySeconds;

  String? displayPhoneFor(PhoneNumberFormatter formatter) =>
      phoneE164 == null ? null : formatter.formatDisplay(phoneE164!);

  AuthState copyWith({
    String? phoneE164,
    bool? isSubmitting,
    String? errorMessage,
    int? resendSecondsRemaining,
    int? rateLimitRetrySeconds,
    bool clearError = false,
  }) {
    return AuthState(
      phoneE164: phoneE164 ?? this.phoneE164,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resendSecondsRemaining:
          resendSecondsRemaining ?? this.resendSecondsRemaining,
      rateLimitRetrySeconds: clearError
          ? null
          : (rateLimitRetrySeconds ?? this.rateLimitRetrySeconds),
    );
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  Timer? _resendTimer;

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  DriverOnboardingPreferences get _prefs =>
      ref.read(driverOnboardingPreferencesProvider);

  @override
  AuthState build() {
    ref.onDispose(() => _resendTimer?.cancel());
    return const AuthState();
  }

  Future<bool> requestOtp(String localDigits) async {
    final config = ref.read(appConfigProvider);
    if (!config.hasBackend) {
      state = state.copyWith(errorMessage: 'not_configured');
      return false;
    }

    final formatter = ref.read(phoneFormatterProvider).valueOrNull ??
        const PhoneNumberFormatter(phonePrefix: '+234');

    if (!formatter.isValidLocal(localDigits)) {
      state = state.copyWith(errorMessage: 'invalid_phone');
      return false;
    }

    final e164 = formatter.toE164(localDigits);
    state = state.copyWith(
      phoneE164: e164,
      isSubmitting: true,
      clearError: true,
    );

    try {
      await _auth.requestOtp(e164).timeout(const Duration(seconds: 20));
      _startResendCountdown();
      state = state.copyWith(isSubmitting: false, clearError: true);
      return true;
    } on AlongException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _errorKey(e),
        rateLimitRetrySeconds: _retryAfterSeconds(e),
      );
      return false;
    } on TimeoutException {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
      return false;
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
      return false;
    }
  }

  Future<bool> verifyOtp(String token) async {
    final phone = state.phoneE164;
    if (phone == null || token.length != 6) {
      state = state.copyWith(errorMessage: 'wrong_otp');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _auth.verifyOtp(phoneE164: phone, token: token);
      await _prefs.setStep(DriverOnboardingStep.profile);
      state = state.copyWith(isSubmitting: false, clearError: true);
      return true;
    } on AlongException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _errorKey(e),
        rateLimitRetrySeconds: _retryAfterSeconds(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
      return false;
    }
  }

  Future<void> resendOtp() async {
    final phone = state.phoneE164;
    if (phone == null || state.resendSecondsRemaining > 0) return;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _auth.requestOtp(phone);
      _startResendCountdown();
      state = state.copyWith(isSubmitting: false, clearError: true);
    } on AlongException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _errorKey(e),
        rateLimitRetrySeconds: _retryAfterSeconds(e),
      );
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
    }
  }

  void clearPhone() {
    _resendTimer?.cancel();
    state = const AuthState();
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(clearError: true);
  }

  Future<String?> peekStagingOtp() {
    final phone = state.phoneE164;
    if (phone == null) return Future.value(null);
    if (ref.read(appConfigProvider).flavor == 'prod') {
      return Future.value(null);
    }
    return _auth.peekLogOtp(phone);
  }

  Future<DriverOnboardingStep> resolveLaunchStep() async {
    final user = _auth.currentUser;
    if (user == null) return DriverOnboardingStep.auth;
    return _prefs.currentStep();
  }

  void _startResendCountdown() {
    final cooldown = ref.read(appConfigProvider).otpResendCooldownS;
    _resendTimer?.cancel();
    state = state.copyWith(resendSecondsRemaining: cooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendSecondsRemaining - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(resendSecondsRemaining: 0);
      } else {
        state = state.copyWith(resendSecondsRemaining: next);
      }
    });
  }

  String _errorKey(AlongException e) {
    return switch (e.code) {
      AlongErrorCode.rateLimited => 'rate_limited',
      AlongErrorCode.validation => 'wrong_otp',
      AlongErrorCode.unauthenticated => 'expired_otp',
      _ => 'generic',
    };
  }

  int? _retryAfterSeconds(AlongException e) {
    if (e.code != AlongErrorCode.rateLimited) return null;
    final details = e.details;
    if (details is num) return details.round();
    if (details is Map) {
      for (final key in ['retry_after_s', 'retryAfter', 'seconds']) {
        final value = details[key];
        if (value is num) return value.round();
      }
    }
    return null;
  }
}

final authSessionProvider = Provider<User?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});
