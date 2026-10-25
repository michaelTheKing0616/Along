import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Phone OTP auth via Supabase Auth.
class AuthRepository {
  AuthRepository(this._gateway);

  final AlongSupabase _gateway;

  User? get currentUser => _gateway.currentUser;

  Stream<AuthState> authStateChanges() => _gateway.authStateChanges();

  Future<void> requestOtp(String phoneE164) async {
    try {
      await _gateway.signInWithOtp(phone: phoneE164);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// Staging only: asks the guarded `staging-otp` Edge Function for the
  /// log-mode OTP. Returns null on any denial or error (the user types it).
  Future<String?> peekStagingOtp(String phoneE164, {required String key}) async {
    try {
      final result = await _gateway.invokeFunction(
        'staging-otp',
        body: {'phone': phoneE164},
        headers: {'x-staging-otp-key': key},
      );
      final otp = result['otp'];
      if (otp is String && otp.trim().isNotEmpty) return otp.trim();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<User?> verifyOtp({
    required String phoneE164,
    required String token,
  }) async {
    try {
      final response = await _gateway.verifyOtp(phone: phoneE164, token: token);
      return response.user;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _gateway.signOut();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> completeRiderOnboarding({String? displayName}) async {
    try {
      await _gateway.rpc(
        'complete_rider_onboarding',
        params: {
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
        },
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
