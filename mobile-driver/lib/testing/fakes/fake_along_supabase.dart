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
  void Function(Map<String, dynamic> params)? onRespondToTrip;
  void Function(Map<String, dynamic> profile)? onUpsertRouteProfile;
  void Function(String tripId)? onStartTrip;
  void Function(String tripId)? onCompleteTrip;
  void Function(Map<String, dynamic> params)? onTripLocationSample;
  void Function(String tripId)? onMarkBoarded;

  List<Map<String, dynamic>> manifestEntries = [];
  final Map<String, String> tripStatuses = {};
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
    if (fn == 'respond_to_trip') {
      onRespondToTrip?.call(params ?? {});
      return _sampleTripView(
        tripId: params?['p_trip_id'] as String? ?? 'trip-1',
        status: params?['p_action'] == 'accept' ? 'accepted' : 'declined',
      );
    }
    if (fn == 'trip_snapshot') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      final status = tripStatuses[tripId] ?? 'accepted';
      return _sampleTripView(tripId: tripId, status: status);
    }
    if (fn == 'driver_manifest') {
      if (manifestEntries.isNotEmpty) return manifestEntries;
      return [
        _manifestEntry(tripId: 'trip-accepted-1', status: 'accepted'),
        _manifestEntry(tripId: 'trip-boarded-1', status: 'boarded'),
      ];
    }
    if (fn == 'mark_boarded') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      onMarkBoarded?.call(tripId);
      tripStatuses[tripId] = 'boarded';
      return _sampleTripView(tripId: tripId, status: 'boarded');
    }
    if (fn == 'start_trip') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      onStartTrip?.call(tripId);
      tripStatuses[tripId] = 'in_transit';
      return _sampleTripView(tripId: tripId, status: 'in_transit');
    }
    if (fn == 'complete_trip') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      onCompleteTrip?.call(tripId);
      tripStatuses[tripId] = 'completed';
      return {
        'trip': _sampleTripView(tripId: tripId, status: 'completed'),
        'commission': {'amount': '34.00', 'currency': 'NGN'},
        'fare': {'amount': '450.00', 'currency': 'NGN'},
      };
    }
    if (fn == 'trip_location_sample') {
      onTripLocationSample?.call(params ?? {});
      return {'boarded_auto': false};
    }
    return {};
  }

  static Map<String, dynamic> _manifestEntry({
    required String tripId,
    required String status,
  }) {
    return {
      'trip_id': tripId,
      'status': status,
      'journey_sequence': 1,
      'rider': {
        'display_name': 'Ada',
        'rating': 4.8,
        'trip_count': 12,
      },
      'board': {
        'stage_id': 's1',
        'name': 'Lugbe Park',
        'location': {'lat': 9.0, 'lng': 7.0},
      },
      'na_me': {
        'color_token': 'green',
        'shape': 'diamond',
        'label': 'Green Diamond',
      },
      'expires_at': '2026-09-05T14:00:00Z',
    };
  }

  static Map<String, dynamic> _sampleTripView({
    required String tripId,
    required String status,
    bool loadFlagged = false,
  }) {
    return {
      'trip_id': tripId,
      'journey_id': 'j1',
      'journey_sequence': 1,
      'status': status,
      'mode': {
        'code': 'car',
        'label': 'Car',
        'icon_key': 'car',
        'color_token': 'mode.car',
      },
      'rider': {
        'display_name': 'Ada',
        'rating': 4.8,
        'trip_count': 12,
      },
      'driver': {},
      'vehicle': {},
      'board': {
        'stage_id': 's1',
        'name': 'Lugbe Park',
        'location': {'lat': 9.0, 'lng': 7.0},
        'walk_m': 400,
        'walk_s': 300,
        'wayfinding_available': true,
      },
      'alight': {
        'stage_id': 's2',
        'name': 'Area 1 Park',
        'location': {'lat': 9.1, 'lng': 7.1},
      },
      'route_leg_ids': [],
      'fare': {
        'total': {'amount': '450.00', 'currency': 'NGN'},
        'tier': 1,
        'confidence': 1,
        'unconfirmed': false,
        'components': [],
        'quote_id': 'q1',
        'expires_at': '2026-09-05T13:00:00Z',
      },
      'load': {
        'flagged': loadFlagged,
        'size': loadFlagged ? 'Medium' : 'none',
        'note': loadFlagged ? '1 bag, needs boot' : null,
      },
      'women_only': false,
      'na_me': {
        'color_token': 'green',
        'shape': 'diamond',
        'label': 'Green Diamond',
      },
      'live_channel': 'trip:$tripId',
      'expires_at': '2026-09-05T14:00:00Z',
      'timestamps': {},
    };
  }

  Map<String, dynamic> sampleTripRequestEnvelope({
    String tripId = 'trip-1',
    bool loadFlagged = true,
  }) {
    return {
      'type': 'trip_request',
      'expires_at': '2026-09-05T14:00:00Z',
      'trip': _sampleTripView(
        tripId: tripId,
        status: 'requested',
        loadFlagged: loadFlagged,
      ),
    };
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
      if (key == 'commission.rate') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '0.075',
          },
        ];
      }
      if (key == 'dispatch.request_ttl_s') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '25',
          },
        ];
      }
      if (key == 'dispatch.max_cascade') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '3',
          },
        ];
      }
      if (key == 'driver.negotiation_poll_s') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '2',
          },
        ];
      }
      if (key == 'negotiation.chip_steps') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '[-100,-50,50,100]',
          },
        ];
      }
      if (key == 'driver.manifest_poll_s') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '3',
          },
        ];
      }
      if (key == 'client.trip_location_sample_interval_s') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '5',
          },
        ];
      }
      if (key == 'motion.naMe.strobe_ms') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '250',
          },
        ];
      }
      if (key == 'motion.naMe.cycle_duration_s') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '8',
          },
        ];
      }
      if (key == 'sos.hold_duration_ms') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '600',
          },
        ];
      }
      if (key == 'dispatch.no_show_after_s') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '300',
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
