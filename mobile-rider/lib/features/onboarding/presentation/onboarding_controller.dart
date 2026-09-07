import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/onboarding/data/onboarding_preferences.dart';
import 'package:mobile_rider/features/onboarding/domain/phone_number_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared onboarding flow state for R-02 through R-04.
class OnboardingState {
  const OnboardingState({
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

  OnboardingState copyWith({
    String? phoneE164,
    bool? isSubmitting,
    String? errorMessage,
    int? resendSecondsRemaining,
    int? rateLimitRetrySeconds,
    bool clearError = false,
  }) {
    return OnboardingState(
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

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);

class OnboardingController extends Notifier<OnboardingState> {
  Timer? _resendTimer;

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  OnboardingPreferences get _prefs => ref.read(onboardingPreferencesProvider);

  @override
  OnboardingState build() {
    ref.onDispose(() => _resendTimer?.cancel());
    return const OnboardingState();
  }

  Future<bool> requestOtp(String localDigits) async {
    final formatter = await ref.read(phoneFormatterProvider.future);
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
      await _auth.requestOtp(e164);
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

  Future<void> completeOnboarding({String? displayName}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _auth.completeRiderOnboarding(displayName: displayName);
      await _prefs.markComplete();
      state = state.copyWith(isSubmitting: false, clearError: true);
    } on AlongException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _errorKey(e),
        rateLimitRetrySeconds: _retryAfterSeconds(e),
      );
      rethrow;
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
      rethrow;
    }
  }

  void clearPhone() {
    _resendTimer?.cancel();
    state = const OnboardingState();
  }

  Future<LaunchDestination> resolveLaunchDestination() async {
    final user = _auth.currentUser;
    if (user == null) return LaunchDestination.phoneEntry;
    if (await _prefs.isComplete()) {
      return LaunchDestination.home;
    }
    return LaunchDestination.nameEntry;
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
    if (details == null) return null;
    if (details is num) return details.round();
    if (details is Map) {
      for (final key in [
        'retry_after_s',
        'retryAfter',
        'retry_after',
        'seconds',
      ]) {
        final value = details[key];
        if (value is num) return value.round();
        if (value is String) return int.tryParse(value);
      }
    }
    return null;
  }
}

enum LaunchDestination {
  phoneEntry,
  nameEntry,
  home,
}

/// Reads auth session for router guards.
final authSessionProvider = Provider<User?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  return ref.watch(onboardingPreferencesProvider).isComplete();
});
