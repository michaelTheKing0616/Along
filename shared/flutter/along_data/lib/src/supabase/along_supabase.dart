import 'dart:typed_data';

import 'package:along_core/along_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// HTTP verb for Edge function calls.
enum AlongHttpMethod { get, post }

/// Testable gateway over Supabase RPC and Edge HTTP calls.
abstract class AlongSupabase {
  Future<dynamic> rpc(
    String fn, {
    Map<String, dynamic>? params,
  });

  Future<Map<String, dynamic>> invokeFunction(
    String slug, {
    Map<String, dynamic>? body,
    AlongHttpMethod method = AlongHttpMethod.post,
    Map<String, String>? queryParameters,
  });

  /// Reads rows from a Supabase table (e.g. `app_config`).
  Future<List<Map<String, dynamic>>> selectRows(
    String table, {
    Map<String, Object?> filters = const {},
    String? inColumn,
    List<Object?>? inValues,
  });

  /// Uploads bytes to a Supabase Storage bucket (e.g. verification captures).
  Future<void> uploadStorageObject({
    required String bucket,
    required String path,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  });

  User? get currentUser;
  Stream<AuthState> authStateChanges();
  Future<void> signInWithOtp({required String phone});
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  });
  Future<void> signOut();
}

class SupabaseAlongGateway implements AlongSupabase {
  SupabaseAlongGateway(this._client);

  final SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  @override
  Future<void> signInWithOtp({required String phone}) =>
      _client.auth.signInWithOtp(phone: phone);

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) =>
      _client.auth.verifyOTP(type: OtpType.sms, phone: phone, token: token);

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<dynamic> rpc(
    String fn, {
    Map<String, dynamic>? params,
  }) async {
    final result = await _client.rpc<dynamic>(fn, params: params ?? {});
    return result;
  }

  @override
  Future<Map<String, dynamic>> invokeFunction(
    String slug, {
    Map<String, dynamic>? body,
    AlongHttpMethod method = AlongHttpMethod.post,
    Map<String, String>? queryParameters,
  }) async {
    final result = await _client.functions.invoke(
      slug,
      body: method == AlongHttpMethod.post ? (body ?? {}) : null,
      method: method == AlongHttpMethod.get ? HttpMethod.get : HttpMethod.post,
      queryParameters: queryParameters,
    );
    final data = result.data;
    if (data is Map<String, dynamic>) return data;
    if (data == null) return {};
    throw AlongException(
      code: AlongErrorCode.validation,
      message: 'Unexpected Edge response type for $slug',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> selectRows(
    String table, {
    Map<String, Object?> filters = const {},
    String? inColumn,
    List<Object?>? inValues,
  }) async {
    var query = _client.from(table).select();
    for (final entry in filters.entries) {
      final value = entry.value;
      if (value != null) {
        query = query.eq(entry.key, value);
      }
    }
    if (inColumn != null && inValues != null && inValues.isNotEmpty) {
      query = query.filter(inColumn, 'in', '(${inValues.join(',')})');
    }
    final result = await query;
    return (result as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  Future<void> uploadStorageObject({
    required String bucket,
    required String path,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
  }
}

/// Initializes Supabase for app startup.
Future<AlongSupabase> createAlongSupabase({
  required String url,
  required String anonKey,
}) async {
  await Supabase.initialize(url: url, anonKey: anonKey);
  return SupabaseAlongGateway(Supabase.instance.client);
}
