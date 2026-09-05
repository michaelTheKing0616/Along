import 'dart:async';

import 'package:along_data/along_data.dart';
import 'package:mobile_rider/features/onboarding/data/onboarding_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory auth gateway for widget/integration tests.
class FakeAlongSupabase implements AlongSupabase {
  FakeAlongSupabase({
    this.otpCode = '123456',
  });

  final String otpCode;
  void Function(String phone)? onRequestOtp;
  void Function(String phone, String token)? onVerifyOtp;
  void Function(String? displayName)? onCompleteOnboarding;

  User? _user;
  final _controller = StreamController<AuthState>.broadcast();

  @override
  User? get currentUser => _user;

  @override
  Stream<AuthState> authStateChanges() => _controller.stream;

  @override
  Future<void> signInWithOtp({required String phone}) async {
    onRequestOtp?.call(phone);
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    onVerifyOtp?.call(phone, token);
    if (token != otpCode) {
      throw const AuthException('Invalid OTP');
    }
    _user = User(
      id: 'test-user-id',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    _controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    return AuthResponse(user: _user, session: null);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Future<Map<String, dynamic>> rpc(
    String fn, {
    Map<String, dynamic>? params,
  }) async {
    if (fn == 'complete_rider_onboarding') {
      onCompleteOnboarding?.call(params?['display_name'] as String?);
      return {};
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> invokeFunction(
    String slug, {
    Map<String, dynamic>? body,
  }) async =>
      {};

  void dispose() => _controller.close();
}

/// Onboarding prefs that never touch secure storage in tests.
class FakeOnboardingPreferences implements OnboardingPreferences {
  FakeOnboardingPreferences({this.complete = false});

  bool complete;

  @override
  Future<bool> isComplete() async => complete;

  @override
  Future<void> markComplete() async {
    complete = true;
  }

  @override
  Future<void> clear() async {
    complete = false;
  }
}
