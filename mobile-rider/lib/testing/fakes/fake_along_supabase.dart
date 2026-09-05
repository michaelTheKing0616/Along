import 'dart:async';

import 'package:along_data/along_data.dart';
import 'package:mobile_rider/features/onboarding/data/onboarding_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory auth gateway for widget/integration tests.
class FakeAlongSupabase implements AlongSupabase {
  FakeAlongSupabase({
    this.otpCode = '123456',
    this.configRows = const [],
    this.ambientCells = const [],
    this.placeResults = const [],
    this.snappedStage,
    this.cityId = 'b1000000-0000-4000-8000-000000000001',
    this.citySlug = 'abuja',
    this.planTripResponse,
    this.planTripDelay = Duration.zero,
    this.requestTripResponse,
  });

  final String otpCode;
  void Function(String phone)? onRequestOtp;
  void Function(String phone, String token)? onVerifyOtp;
  void Function(String? displayName)? onCompleteOnboarding;

  List<Map<String, dynamic>> configRows;
  List<Map<String, dynamic>> ambientCells;
  List<Map<String, dynamic>> placeResults;
  Map<String, dynamic>? snappedStage;
  String? cityId;
  String? citySlug;
  Map<String, dynamic>? planTripResponse;
  Duration planTripDelay;
  Map<String, dynamic>? requestTripResponse;

  int planTripInvokeCount = 0;
  int requestTripInvokeCount = 0;

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
  Future<dynamic> rpc(
    String fn, {
    Map<String, dynamic>? params,
  }) async {
    if (fn == 'complete_rider_onboarding') {
      onCompleteOnboarding?.call(params?['display_name'] as String?);
      return {};
    }
    if (fn == 'ambient_vehicles') {
      return {
        'as_of': DateTime.now().toUtc().toIso8601String(),
        'cells': ambientCells,
      };
    }
    if (fn == 'city_for_lat_lng') {
      return {'city_id': cityId};
    }
    if (fn == 'snap_stage') {
      return snappedStage ?? {};
    }
    if (fn == 'request_trip') {
      requestTripInvokeCount++;
      return requestTripResponse ?? {};
    }
    if (fn == 'trip_snapshot') {
      return requestTripResponse ?? {};
    }
    if (fn == 'cancel_trip') {
      return {};
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> invokeFunction(
    String slug, {
    Map<String, dynamic>? body,
  }) async {
    if (slug == 'places-search') {
      return {
        'data': {
          'results': placeResults,
        },
      };
    }
    if (slug == 'plan-trip') {
      planTripInvokeCount++;
      if (planTripDelay > Duration.zero) {
        await Future<void>.delayed(planTripDelay);
      }
      return planTripResponse ?? {'data': {'candidates': []}};
    }
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> selectRows(
    String table, {
    Map<String, Object?> filters = const {},
  }) async {
    if (table == 'cities') {
      final id = filters['id'];
      if (id == cityId) {
        return [
          {'id': cityId, 'slug': citySlug ?? 'abuja'},
        ];
      }
      return [];
    }
    if (table != 'app_config') return [];
    final key = filters['key'];
    return configRows
        .where((row) => key == null || row['key'] == key)
        .toList(growable: false);
  }

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

/// Default app_config rows for tests (doc 02 §2.3 keys only).
List<Map<String, dynamic>> defaultTestConfigRows() => [
      {
        'key': 'presence.stale_after_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '45',
      },
      {
        'key': 'presence.fanout_radius_m',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '3000',
      },
      {
        'key': 'graph.snap_radius_m',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '60',
      },
    ];

/// Sample ambient cell payload (Tier A — no vehicle identity).
Map<String, dynamic> sampleAmbientCell({
  String countBucket = '3-5',
  String modeCode = 'keke',
}) =>
    {
      'cell': 's0k8tz',
      'centroid': {'lat': 9.0765, 'lng': 7.3986},
      'mode': {
        'code': modeCode,
        'label': modeCode,
        'icon_key': 'mode-$modeCode',
        'color_token': 'modeKeke',
      },
      'count_bucket': countBucket,
      'heading_sectors': [0, 1, 0, 0, 0, 0, 0, 0],
      'serves_destination': true,
      'eta_band_s': 180,
    };
