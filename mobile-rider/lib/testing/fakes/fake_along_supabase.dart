import 'dart:async';

import 'package:along_data/along_data.dart';
import 'package:mobile_rider/features/onboarding/data/onboarding_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory auth gateway for widget/integration tests.
class FakeAlongSupabase implements AlongSupabase {
  FakeAlongSupabase({
    this.otpCode = '123456',
    this.configRows = const [],
    this.modeConfigRows = const [],
    this.ambientCells = const [],
    this.placeResults = const [],
    this.snappedStage,
    this.cityId = 'b1000000-0000-4000-8000-000000000001',
    this.citySlug = 'abuja',
    this.planTripResponse,
    this.planTripDelay = Duration.zero,
    this.requestTripResponse,
    this.walkingDirectionsResponse,
    this.journeyRows = const [],
    this.journeyTransferWalkRows = const [],
  });

  final String otpCode;
  void Function(String phone)? onRequestOtp;
  void Function(String phone, String token)? onVerifyOtp;
  void Function(String? displayName)? onCompleteOnboarding;

  List<Map<String, dynamic>> configRows;
  List<Map<String, dynamic>> modeConfigRows;
  List<Map<String, dynamic>> ambientCells;
  List<Map<String, dynamic>> placeResults;
  Map<String, dynamic>? snappedStage;
  String? cityId;
  String? citySlug;
  Map<String, dynamic>? planTripResponse;
  Duration planTripDelay;
  Map<String, dynamic>? requestTripResponse;
  Map<String, dynamic>? walkingDirectionsResponse;
  List<Map<String, dynamic>> journeyRows;
  List<Map<String, dynamic>> journeyTransferWalkRows;

  int planTripInvokeCount = 0;
  int requestTripInvokeCount = 0;
  Map<String, dynamic>? lastRequestTripParams;

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
      lastRequestTripParams = params;
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
    if (slug == 'walking-directions') {
      return walkingDirectionsResponse ??
          {
            'data': sampleWalkingDirectionsPayload(),
          };
    }
    return {};
  }

  @override
  Future<void> uploadStorageObject({
    required String bucket,
    required String path,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> selectRows(
    String table, {
    Map<String, Object?> filters = const {},
    String? inColumn,
    List<Object?>? inValues,
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
    if (table == 'mode_config') {
      return modeConfigRows;
    }
    if (table == 'journeys') {
      return journeyRows
          .where((row) {
            for (final entry in filters.entries) {
              if (row[entry.key] != entry.value) return false;
            }
            return true;
          })
          .toList(growable: false);
    }
    if (table == 'journey_transfer_walks') {
      return journeyTransferWalkRows
          .where((row) {
            for (final entry in filters.entries) {
              if (row[entry.key] != entry.value) return false;
            }
            return true;
          })
          .toList(growable: false);
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
      {
        'key': 'wayfinding.arrived_radius_m',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '25',
      },
    ];

/// Default `load.warn_capacities` + `mode_config` rows for FM36 tests.
List<Map<String, dynamic>> defaultLoadWarningConfigRows() => [
      {
        'key': 'load.warn_capacities',
        'scope_type': 'global',
        'scope_id': '*',
        'value': {
          'small': ['none'],
          'medium': ['none', 'small'],
          'large': ['none', 'small', 'medium'],
        },
      },
    ];

List<Map<String, dynamic>> defaultModeConfigRows() => [
      {
        'code': 'car',
        'label': 'Along taxi',
        'icon_key': 'mode.car',
        'color_token': 'mode.car',
        'load_capacity': 'large',
        'default_seat_capacity': 4,
        'sort_order': 10,
      },
      {
        'code': 'keke',
        'label': 'Keke',
        'icon_key': 'mode.keke',
        'color_token': 'mode.keke',
        'load_capacity': 'small',
        'default_seat_capacity': 3,
        'sort_order': 20,
      },
      {
        'code': 'okada',
        'label': 'Okada',
        'icon_key': 'mode.okada',
        'color_token': 'mode.okada',
        'load_capacity': 'none',
        'default_seat_capacity': 1,
        'sort_order': 30,
      },
      {
        'code': 'minibus',
        'label': 'Minibus',
        'icon_key': 'mode.minibus',
        'color_token': 'mode.minibus',
        'load_capacity': 'medium',
        'default_seat_capacity': 14,
        'sort_order': 40,
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

/// Sample walking-directions payload for R-19 widget tests.
Map<String, dynamic> sampleWalkingDirectionsPayload() => {
      'distance_m': 240,
      'duration_s': 180,
      'steps': [
        {
          'instruction': 'Walk north on Airport Road',
          'distance_m': 120,
          'maneuver': 'continue',
        },
        {
          'instruction': 'Turn right toward Berger Park',
          'distance_m': 120,
          'maneuver': 'turn-right',
        },
      ],
      'polyline': [
        {'lat': 9.0765, 'lng': 7.3986},
        {'lat': 9.0770, 'lng': 7.3990},
      ],
      'tts_script': [
        'Walk north on Airport Road for 120 metres',
        'Turn right toward Berger Park for 120 metres',
      ],
    };
