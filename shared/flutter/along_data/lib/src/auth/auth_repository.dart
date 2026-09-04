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
}
