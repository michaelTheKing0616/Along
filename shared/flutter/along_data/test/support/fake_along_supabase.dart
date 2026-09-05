import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory Supabase gateway for repository unit tests.
class FakeAlongSupabase implements AlongSupabase {
  FakeAlongSupabase({
    this.rpcHandler,
    this.functionHandler,
    User? user,
  }) : _user = user;

  User? _user;
  Map<String, dynamic> Function(String fn, Map<String, dynamic> params)? rpcHandler;
  Map<String, dynamic> Function(String slug, Map<String, dynamic> body)?
      functionHandler;

  final List<(String fn, Map<String, dynamic> params)> rpcCalls = [];
  final List<(String slug, Map<String, dynamic> body)> functionCalls = [];

  @override
  User? get currentUser => _user;

  @override
  Stream<AuthState> authStateChanges() => const Stream.empty();

  @override
  Future<void> signInWithOtp({required String phone}) async {}

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return AuthResponse(session: null, user: _user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }

  @override
  Future<dynamic> rpc(
    String fn, {
    Map<String, dynamic>? params,
  }) async {
    final p = params ?? {};
    rpcCalls.add((fn, p));
    if (rpcHandler == null) return {};
    return rpcHandler!(fn, p);
  }

  @override
  Future<Map<String, dynamic>> invokeFunction(
    String slug, {
    Map<String, dynamic>? body,
  }) async {
    final b = body ?? {};
    functionCalls.add((slug, b));
    if (functionHandler == null) return {};
    return functionHandler!(slug, b);
  }

  @override
  Future<List<Map<String, dynamic>>> selectRows(
    String table, {
    Map<String, Object?> filters = const {},
    String? inColumn,
    List<Object?>? inValues,
  }) async =>
      const [];

  @override
  Future<void> uploadStorageObject({
    required String bucket,
    required String path,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {}
}
