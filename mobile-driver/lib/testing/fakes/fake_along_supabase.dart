import 'dart:async';

import 'package:along_data/along_data.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory Supabase gateway for driver widget/integration tests.
class FakeAlongSupabase implements AlongSupabase {
  FakeAlongSupabase({
    this.otpCode = '123456',
    List<Map<String, dynamic>>? cities,
    List<Map<String, dynamic>>? modes,
    Map<String, dynamic>? countryConfig,
    List<Map<String, dynamic>>? verificationSchema,
    List<Map<String, dynamic>>? verifications,
    User? signedInUser,
    Map<String, dynamic>? suggestedRoute,
    List<Map<String, dynamic>>? routeProfiles,
    List<Map<String, dynamic>>? placesSearchResults,
  })  : cities = cities ?? defaultTestCities(),
        modes = modes ?? defaultTestModes(),
        countryConfig = countryConfig ?? defaultTestCountry(),
        verificationSchema = verificationSchema ?? defaultVerificationSchema(),
        verifications = verifications ?? [],
        suggestedRoute = suggestedRoute,
        routeProfiles = routeProfiles ?? [],
        placesSearchResults = placesSearchResults ?? [] {
    if (signedInUser != null) {
      _user = signedInUser;
    }
  }

  final String otpCode;
  List<Map<String, dynamic>> cities;
  List<Map<String, dynamic>> modes;
  Map<String, dynamic> countryConfig;
  List<Map<String, dynamic>> verificationSchema;
  List<Map<String, dynamic>> verifications;

  void Function(String phone)? onRequestOtp;
  void Function(String phone, String token)? onVerifyOtp;
  void Function(Map<String, dynamic> params)? onStartDriverOnboarding;
  void Function(RegisterVehicleRequest request)? onRegisterVehicle;
  void Function(SubmitVerificationRequest request)? onSubmitVerification;
  void Function(String bucket, String path, List<int> bytes)? onUpload;
  void Function(Map<String, dynamic> params)? onSetPresence;
  void Function(Map<String, dynamic> params)? onPresencePing;
  void Function(Map<String, dynamic> profile)? onUpsertRouteProfile;

  List<Map<String, dynamic>> routeProfiles;
  Map<String, dynamic>? suggestedRoute;
  List<Map<String, dynamic>> placesSearchResults;

  User? _user;
  String? _storedVehicleId;
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
      id: 'test-driver-id',
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
    if (fn == 'start_driver_onboarding') {
      onStartDriverOnboarding?.call(params ?? {});
      return {};
    }
    if (fn == 'register_vehicle') {
      final request = RegisterVehicleRequest.fromJson(params ?? {});
      onRegisterVehicle?.call(request);
      _storedVehicleId ??= 'test-vehicle-id';
      return RegisterVehicleResponse(vehicle_id: _storedVehicleId!).toJson();
    }
    if (fn == 'submit_verification') {
      final request = SubmitVerificationRequest.fromJson(params ?? {});
      onSubmitVerification?.call(request);
      verifications.add({
        'document_type': request.document_type,
        'status': 'pending',
        'rejection_reason': null,
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
      });
      return {'verification_id': 'test-verification-id'};
    }
    if (fn == 'my_verifications') {
      return verifications;
    }
    if (fn == 'set_presence') {
      onSetPresence?.call(params ?? {});
      return {
        'session_id': 'test-session',
        'status': params?['p_status'],
      };
    }
    if (fn == 'presence_ping') {
      onPresencePing?.call(params ?? {});
      return {'accepted': true};
    }
    if (fn == 'ambient_demand') {
      return {'cells': <Map<String, dynamic>>[]};
    }
    if (fn == 'my_route_profiles') {
      return routeProfiles;
    }
    if (fn == 'suggest_known_route') {
      return suggestedRoute;
    }
    if (fn == 'upsert_route_profile') {
      final profile = params?['p_profile'] as Map<String, dynamic>? ?? {};
      onUpsertRouteProfile?.call(profile);
      final id = profile['id'] as String? ?? 'published-profile-id';
      routeProfiles = [
        {
          'id': id,
          'route_id': 'route-id',
          'mode_code': profile['mode_code'],
          'name': profile['name'],
          'active': true,
          'load_surcharge_amount': profile['load_surcharge']?['amount'],
          'load_surcharge_currency': profile['load_surcharge']?['currency'],
          'stops': profile['stops'],
        },
      ];
      return {'id': id, 'active': true, 'route_id': 'route-id'};
    }
    if (fn == 'deactivate_route_profile') {
      final id = params?['p_id'] as String?;
      routeProfiles = routeProfiles
          .map((row) => row['id'] == id ? {...row, 'active': false} : row)
          .toList(growable: false);
      return null;
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> invokeFunction(
    String slug, {
    Map<String, dynamic>? body,
  }) async {
    if (slug == 'verification-ocr') {
      return {
        'data': {
          'hints': {'full_name': 'Test Driver'},
        },
      };
    }
    if (slug == 'places-search') {
      return {
        'data': {
          'results': placesSearchResults,
        },
      };
    }
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> selectRows(
    String table, {
    Map<String, Object?> filters = const {},
    String? inColumn,
    List<Object?>? inValues,
  }) async {
    if (table == 'cities') {
      if (inColumn == 'status' && inValues != null) {
        return cities
            .where((row) => inValues.contains(row['status']))
            .toList(growable: false);
      }
      return cities;
    }
    if (table == 'mode_config') return modes;
    if (table == 'countries') {
      final code = filters['code'];
      if (code == countryConfig['code']) {
        return [countryConfig];
      }
    }
    if (table == 'app_config') {
      final key = filters['key'];
      if (key == 'verification.expected_review_hours') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '48',
          },
        ];
      }
      if (key == 'presence.ping_interval_moving_s') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '4',
          },
        ];
      }
      if (key == 'presence.ping_interval_still_s') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '15',
          },
        ];
      }
      if (key == 'presence.fanout_radius_m') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '3000',
          },
        ];
      }
      if (key == 'presence.at_park_radius_m') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '150',
          },
        ];
      }
      if (key == 'graph.snap_radius_m') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '60',
          },
        ];
      }
    }
    if (table == 'drivers') {
      return [
        {
          'id': _user?.id ?? 'test-driver-id',
          'verified_status': 'verified',
          'city_id': 'b1000000-0000-4000-8000-000000000001',
          'standing': 'good_standing',
        },
      ];
    }
    return [];
  }

  @override
  Future<void> uploadStorageObject({
    required String bucket,
    required String path,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    onUpload?.call(bucket, path, bytes);
  }

  void dispose() => _controller.close();
}

class FakeDriverOnboardingPreferences implements DriverOnboardingPreferences {
  FakeDriverOnboardingPreferences({
    this.step = DriverOnboardingStep.auth,
    this.storedVehicleId,
    this.country = 'NG',
  });

  DriverOnboardingStep step;
  String? storedVehicleId;
  String country;

  @override
  Future<DriverOnboardingStep> currentStep() async => step;

  @override
  Future<void> setStep(DriverOnboardingStep value) async {
    step = value;
  }

  @override
  Future<String?> vehicleId() async => storedVehicleId;

  @override
  Future<void> setVehicleId(String id) async {
    storedVehicleId = id;
  }

  @override
  Future<String?> countryCode() async => country;

  @override
  Future<void> setCountryCode(String code) async {
    country = code;
  }

  @override
  Future<void> clear() async {
    step = DriverOnboardingStep.auth;
    storedVehicleId = null;
    country = 'NG';
  }
}

List<Map<String, dynamic>> defaultTestCities() => [
      {
        'id': 'b1000000-0000-4000-8000-000000000001',
        'name': 'Abuja',
        'slug': 'abuja',
        'country_code': 'NG',
        'status': 'live',
      },
    ];

List<Map<String, dynamic>> defaultTestModes() => [
      {
        'code': 'keke',
        'label': 'Keke',
        'icon_key': 'mode.keke',
        'color_token': 'mode.keke',
        'default_seat_capacity': 3,
        'sort_order': 20,
      },
      {
        'code': 'car',
        'label': 'Along taxi',
        'icon_key': 'mode.car',
        'color_token': 'mode.car',
        'default_seat_capacity': 4,
        'sort_order': 10,
      },
    ];

Map<String, dynamic> defaultTestCountry() => {
      'code': 'NG',
      'verification_schema': defaultVerificationSchema(),
      'regulatory_flags': {
        'plate_pattern': r'^[A-Za-z]{3}[-\s]?\d{3}[A-Za-z]{2}$',
      },
    };

List<Map<String, dynamic>> defaultVerificationSchema() => [
      {
        'type': 'nin',
        'label': 'NIN',
        'pattern': r'^\d{11}$',
      },
      {
        'type': 'drivers_license',
        'label': "Driver's License",
        'pattern': r'^.{5,}$',
      },
    ];
