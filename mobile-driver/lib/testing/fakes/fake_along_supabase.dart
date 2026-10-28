import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory Supabase gateway for driver widget/integration tests.
class FakeAlongSupabase implements AlongSupabase {
  /// Time source for generated timestamps; goldens pin it.
  DateTime Function() clock = DateTime.now;

  FakeAlongSupabase({
    this.otpCode = '123456',
    List<Map<String, dynamic>>? cities,
    List<Map<String, dynamic>>? modes,
    Map<String, dynamic>? countryConfig,
    List<Map<String, dynamic>>? verificationSchema,
    List<Map<String, dynamic>>? verifications,
    User? signedInUser,
    this.suggestedRoute,
    List<Map<String, dynamic>>? routeProfiles,
    List<Map<String, dynamic>>? placesSearchResults,
    this.driverBalanceResponse,
    this.earningsContextResponse,
    List<Map<String, dynamic>>? driverLedgerEntries,
    List<Map<String, dynamic>>? tripExtensionRows,
    List<Map<String, dynamic>>? settlementRows,
    List<Map<String, dynamic>>? nearbySettlementAgents,
    this.digitalPaymentsEnabled = false,
    this.driverCode = 'ABC12345',
    this.driverPlate = 'ABC-123-KJ',
    this.acceptsDigital = true,
    this.hasPayoutSubaccount = true,
    this.publicOrigin,
    List<Map<String, dynamic>>? qrStickerRequests,
    List<Map<String, dynamic>>? digitalPayments,
    this.raiseSosDelay = Duration.zero,
    this.raiseSosResponse,
    Map<String, GeoPoint>? cityCentroids,
    String? driverCityId,
  }) : cities = cities ?? defaultTestCities(),
       modes = modes ?? defaultTestModes(),
       countryConfig = countryConfig ?? defaultTestCountry(),
       verificationSchema = verificationSchema ?? defaultVerificationSchema(),
       verifications = verifications ?? [],
       routeProfiles = routeProfiles ?? [],
       placesSearchResults = placesSearchResults ?? [],
       driverLedgerEntries = driverLedgerEntries ?? [],
       tripExtensionRows = tripExtensionRows ?? [],
       settlementRows = settlementRows ?? [],
       nearbySettlementAgents =
           nearbySettlementAgents ?? defaultNearbySettlementAgents(),
       qrStickerRequests = qrStickerRequests ?? [],
       digitalPayments = digitalPayments ?? [],
       cityCentroids = cityCentroids ?? defaultCityCentroids(),
       driverCityId = driverCityId ?? 'b1000000-0000-4000-8000-000000000001' {
    if (signedInUser != null) {
      _user = signedInUser;
    } else {
      _user = User(
        id: 'test-driver-id',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: clock().toIso8601String(),
      );
    }
  }

  final Map<String, dynamic>? earningsContextResponse;
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
  void Function(Map<String, dynamic> params)? onConfirmFare;
  void Function(Map<String, dynamic> params)? onRateTrip;
  void Function(Map<String, dynamic> params)? onProposeExtension;
  void Function(Map<String, dynamic> params)? onRespondExtension;
  void Function(String tripId)? onMarkBoarded;

  /// Pickup PIN the fake accepts, and the attempts the server allows.
  String tripPin = '4827';
  int pinAttemptsLeft = 5;
  final List<String> pinAttempts = [];
  void Function(String tripId)? onReleaseMatch;
  void Function(String tripId)? onCancelTrip;

  static Map<String, dynamic> defaultDriverBalanceResponse() => {
    'balance': {'amount': '0.00', 'currency': 'NGN'},
    'block_threshold': {'amount': '-5000.00', 'currency': 'NGN'},
    'standing': 'good_standing',
    'grace_deadline': null,
    'deposit_held': {'amount': '0.00', 'currency': 'NGN'},
  };

  static Map<String, dynamic> ledgerBlockedDriverBalanceResponse() => {
    'balance': {'amount': '-5200.00', 'currency': 'NGN'},
    'block_threshold': {'amount': '-5000.00', 'currency': 'NGN'},
    'standing': 'matching_paused',
    'grace_deadline': null,
    'deposit_held': {'amount': '0.00', 'currency': 'NGN'},
  };

  /// A sedan cabin: driver + front right, three in the back.
  /// One danfo, two corridors, a saved layout, one rule and two presets.
  static Map<String, dynamic> sampleDaySetup() => {
    'vehicles': [
      {
        'id': 'veh-1',
        'mode_code': 'danfo',
        'plate_number': 'LND 482 KJ',
        'seat_capacity': 4,
        'review_seat_max': 4,
        'make_model': 'Toyota HiAce',
      },
    ],
    'layouts': [
      {
        'id': 'layout-1',
        'vehicle_id': 'veh-1',
        'name': 'Morning run',
        'layout': sampleSeatBoard()['layout'],
        'passenger_seats': 4,
        'is_active': true,
      },
    ],
    'corridors': [
      {'id': 'cor-1', 'name': 'Ikorodu – CMS', 'slug': 'ikorodu-cms'},
      {'id': 'cor-2', 'name': 'Oshodi – Ikeja', 'slug': 'oshodi-ikeja'},
    ],
    'routes': <Object>[],
    'rules': [
      {
        'id': 'rule-1',
        'title': 'Window stays open',
        'body': 'Fresh air for everyone on the run.',
        'effect': 'badge',
      },
    ],
    'presets': [
      {'id': 'hold', 'title': 'Hold a seat', 'effect': 'hold'},
      {'id': 'walk', 'title': 'Walk-up stop', 'effect': 'walk'},
    ],
  };

  static Map<String, dynamic> sampleSeatBoard() => {
    'layout_id': 'layout-1',
    'vehicle_id': 'vehicle-1',
    'free': 2,
    'layout': {
      'version': 1,
      'body': 'cabin',
      'rows': [
        {
          'id': 'front',
          'seats': [
            {'id': 'drv', 'role': 'driver', 'label': 'Driver'},
            {'id': 'fr', 'role': 'passenger', 'label': 'FR'},
          ],
        },
        {
          'id': 'back',
          'seats': [
            {'id': 'bl', 'role': 'passenger', 'label': 'BL'},
            {'id': 'bm', 'role': 'passenger', 'label': 'BM'},
            {'id': 'br', 'role': 'passenger', 'label': 'BR'},
          ],
        },
      ],
    },
    'seats': [
      {'seat_id': 'fr', 'status': 'occupied', 'version': 2},
      {'seat_id': 'bl', 'status': 'free', 'version': 1},
      {'seat_id': 'bm', 'status': 'held', 'version': 1},
      {'seat_id': 'br', 'status': 'free', 'version': 1},
    ],
    'rules': [
      {
        'id': 'r1',
        'effect': 'badge',
        'target_scope': 'vehicle',
        'title': 'Window stays open',
        'body': 'No AC on short hops.',
        'enabled': true,
      },
    ],
  };

  int confirmFareInvokeCount = 0;
  final List<Map<String, dynamic>> postedTripMessages = [];
  int respondExtensionInvokeCount = 0;
  int raiseSosInvokeCount = 0;
  int updateSosInvokeCount = 0;
  int reportIncidentInvokeCount = 0;
  Duration raiseSosDelay;
  Map<String, dynamic>? raiseSosResponse;
  Map<String, dynamic>? lastRaiseSosParams;
  Map<String, dynamic>? lastReportIncidentParams;

  List<Map<String, dynamic>> manifestEntries = [];
  final Map<String, String> tripStatuses = {};
  final Map<String, Map<String, dynamic>> tripWaitById = {};
  List<Map<String, dynamic>> routeProfiles;
  Map<String, dynamic>? suggestedRoute;
  List<Map<String, dynamic>> placesSearchResults;
  Map<String, dynamic>? driverBalanceResponse;

  /// `seat_board` RPC payload; null keeps the driver without a layout.
  Map<String, dynamic>? seatBoardResponse;

  /// Served for rpc 'my_day_setup' when set.
  Map<String, dynamic>? myDaySetupResponse;

  /// Rows served for `trips` selects (earnings, home today line).
  final List<Map<String, dynamic>> tripRows = [];
  List<Map<String, dynamic>> driverLedgerEntries;
  List<Map<String, dynamic>> tripExtensionRows;
  List<Map<String, dynamic>> settlementRows;
  List<Map<String, dynamic>> nearbySettlementAgents;
  bool digitalPaymentsEnabled;
  String driverCode;
  String driverPlate;
  bool acceptsDigital;
  bool hasPayoutSubaccount;
  String? publicOrigin;
  List<Map<String, dynamic>> qrStickerRequests;
  List<Map<String, dynamic>> digitalPayments;
  Map<String, GeoPoint> cityCentroids;
  String driverCityId;
  final List<(String fn, Map<String, dynamic> params)> rpcCalls = [];
  final Map<String, Map<String, dynamic>> paymentRequestsByTrip = {};

  static List<Map<String, dynamic>> defaultNearbySettlementAgents() => [
    {'id': 'agent-zaria-near', 'business_name': 'Zaria POS', 'distance_m': 120},
    {
      'id': 'agent-zaria-far',
      'business_name': 'Zaria Far POS',
      'distance_m': 8500,
    },
  ];

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
      createdAt: clock().toIso8601String(),
    );
    _controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    return AuthResponse(user: _user, session: null);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  /// Na Me tap options; the first is the real pairing.
  List<Map<String, dynamic>> naMeOptions = [
    {'color_token': 'green', 'shape': 'diamond', 'label': 'Green Diamond'},
    {'color_token': 'red', 'shape': 'square', 'label': 'Red Square'},
    {'color_token': 'cyan', 'shape': 'triangle', 'label': 'Cyan Triangle'},
    {'color_token': 'yellow', 'shape': 'circle', 'label': 'Yellow Circle'},
  ];
  bool naMeTapLocked = false;
  final List<Map<String, dynamic>> naMeProofs = [];

  @override
  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) async {
    final p = params ?? {};
    rpcCalls.add((fn, Map<String, dynamic>.from(p)));
    if (fn == 'na_me_tap_options') {
      return {
        'options': naMeOptions,
        'tap_locked': naMeTapLocked,
        'attempts_left': 3 - naMeProofs.length,
      };
    }
    if (fn == 'confirm_na_me_match') {
      final proof = Map<String, dynamic>.from(p['p_proof'] as Map? ?? {});
      naMeProofs.add(proof);
      final real = naMeOptions.first;
      final ok =
          proof['color_token'] == real['color_token'] &&
          proof['shape'] == real['shape'];
      if (ok) tripStatuses[p['p_trip_id'] as String] = 'boarded';
      if (!ok) naMeTapLocked = true;
      return {
        'matched': ok,
        'attempts_left': 3 - naMeProofs.length,
        'tap_locked': naMeTapLocked,
      };
    }
    if (fn == 'set_driver_city') {
      final nextCityId = p['p_city_id'] as String?;
      if (nextCityId != null) {
        driverCityId = nextCityId;
      }
      return {};
    }
    if (fn == 'city_centroid') {
      final id = p['p_city_id'] as String? ?? driverCityId;
      final centroid = cityCentroids[id];
      if (centroid == null) return {};
      return {'lat': centroid.lat, 'lng': centroid.lng};
    }
    if (fn == 'start_driver_onboarding') {
      onStartDriverOnboarding?.call(params ?? {});
      return {};
    }
    if (fn == 'save_vehicle_layout') {
      return {
        'id': 'test-layout-id',
        'passenger_seats': 3,
        'over_capacity': false,
      };
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
        'submitted_at': clock().toUtc().toIso8601String(),
      });
      return {'verification_id': 'test-verification-id'};
    }
    if (fn == 'my_verifications') {
      return verifications;
    }
    if (fn == 'set_presence') {
      onSetPresence?.call(params ?? {});
      return {'session_id': 'test-session', 'status': params?['p_status']};
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
      return sampleTripView(
        tripId: params?['p_trip_id'] as String? ?? 'trip-1',
        status: params?['p_action'] == 'accept' ? 'accepted' : 'declined',
      );
    }
    if (fn == 'trip_snapshot') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      final status = tripStatuses[tripId] ?? 'accepted';
      return sampleTripView(
        tripId: tripId,
        status: status,
        wait: tripWaitById[tripId],
      );
    }
    if (fn == 'release_match') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      onReleaseMatch?.call(tripId);
      tripStatuses[tripId] = 'released_before_arrival';
      return sampleTripView(tripId: tripId, status: 'released_before_arrival');
    }
    if (fn == 'cancel_trip') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      onCancelTrip?.call(tripId);
      tripStatuses[tripId] = 'cancelled';
      return sampleTripView(tripId: tripId, status: 'cancelled');
    }
    if (fn == 'driver_manifest') {
      if (manifestEntries.isNotEmpty) return manifestEntries;
      return [
        _manifestEntry(tripId: 'trip-accepted-1', status: 'accepted'),
        _manifestEntry(tripId: 'trip-boarded-1', status: 'boarded'),
      ];
    }
    if (fn == 'post_trip_message') {
      final row = <String, dynamic>{
        'id': 'msg-${postedTripMessages.length}',
        'author_role': 'driver',
        'body': params?['p_body'],
        'client_ref': params?['p_client_ref'],
        'created_at': '2026-10-25T18:00:00Z',
        'read_at': null,
      };
      postedTripMessages.add(row);
      return row;
    }
    if (fn == 'list_trip_messages') {
      return List<Map<String, dynamic>>.of(postedTripMessages);
    }
    if (fn == 'mark_trip_messages_read') return 0;
    if (fn == 'verify_trip_pin') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      final pin = params?['p_pin'] as String? ?? '';
      pinAttempts.add(pin);
      if (pinAttemptsLeft <= 0) {
        return {'verified': false, 'attempts_left': 0, 'locked': true};
      }
      if (pin == tripPin) {
        tripStatuses[tripId] = 'boarded';
        return {'verified': true, 'attempts_left': pinAttemptsLeft};
      }
      pinAttemptsLeft--;
      return {
        'verified': false,
        'attempts_left': pinAttemptsLeft,
        if (pinAttemptsLeft == 0) 'locked': true,
      };
    }
    if (fn == 'mark_boarded') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      onMarkBoarded?.call(tripId);
      tripStatuses[tripId] = 'boarded';
      return sampleTripView(tripId: tripId, status: 'boarded');
    }
    if (fn == 'start_trip') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      onStartTrip?.call(tripId);
      tripStatuses[tripId] = 'in_transit';
      return sampleTripView(tripId: tripId, status: 'in_transit');
    }
    if (fn == 'complete_trip') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      onCompleteTrip?.call(tripId);
      tripStatuses[tripId] = 'completed';
      return {
        'trip': sampleTripView(tripId: tripId, status: 'completed'),
        'commission': {'amount': '34.00', 'currency': 'NGN'},
        'fare': {'amount': '450.00', 'currency': 'NGN'},
      };
    }
    if (fn == 'trip_location_sample') {
      onTripLocationSample?.call(params ?? {});
      return {'boarded_auto': false};
    }
    if (fn == 'driver_earnings_context') {
      return earningsContextResponse ??
          {'online_seconds_by_day': <String, int>{}, 'latest_payout': null};
    }
    if (fn == 'my_day_setup' && myDaySetupResponse != null) {
      return myDaySetupResponse;
    }
    if (fn == 'seat_board' && seatBoardResponse != null) {
      return seatBoardResponse;
    }
    if (fn == 'driver_balance') {
      return driverBalanceResponse ?? defaultDriverBalanceResponse();
    }
    if (fn == 'driver_ledger') {
      return {
        'entries': driverLedgerEntries.isNotEmpty
            ? driverLedgerEntries
            : [
                {
                  'id': '1',
                  'entry_type': 'cash_commission_debit',
                  'amount': {'amount': '-34.00', 'currency': 'NGN'},
                  'balance_after': {'amount': '-1234.00', 'currency': 'NGN'},
                  'created_at': '2026-09-06T10:00:00Z',
                  'memo': null,
                  'trip_id': 'trip-1',
                  'destination_label': 'Area 1',
                },
                {
                  'id': '2',
                  'entry_type': 'digital_settlement_credit',
                  'amount': {'amount': '5000.00', 'currency': 'NGN'},
                  'balance_after': {'amount': '0.00', 'currency': 'NGN'},
                  'created_at': '2026-09-05T10:00:00Z',
                  'memo': 'Paystack settlement',
                  'trip_id': null,
                  'destination_label': null,
                },
              ],
        'meta': {'next_cursor': null},
      };
    }
    if (fn == 'my_standing_history') {
      return [
        {
          'from_standing': 'warned',
          'to_standing': 'matching_paused',
          'actor_type': 'system',
          'reason': 'Balance below block threshold',
          'balance_at': '-5200.00',
          'created_at': '2026-09-06T09:00:00Z',
        },
      ];
    }
    if (fn == 'create_agent_code') {
      return {'agent_code': 'ABC123', 'expires_at': '2026-09-06T11:00:00Z'};
    }
    if (fn == 'nearby_settlement_agents') {
      return nearbySettlementAgents;
    }
    if (fn == 'register_guarantor') {
      return 'guarantor-id';
    }
    if (fn == 'confirm_fare') {
      confirmFareInvokeCount++;
      onConfirmFare?.call(params ?? {});
      return null;
    }
    if (fn == 'rate_trip') {
      onRateTrip?.call(params ?? {});
      return null;
    }
    if (fn == 'raise_sos') {
      raiseSosInvokeCount++;
      lastRaiseSosParams = params;
      if (raiseSosDelay > Duration.zero) {
        await Future<void>.delayed(raiseSosDelay);
      }
      return raiseSosResponse ??
          {'sos_id': 'sos-test-001', 'emergency_number': '112'};
    }
    if (fn == 'update_sos') {
      updateSosInvokeCount++;
      return {'sos_id': params?['p_sos_id'], 'status': 'false_alarm'};
    }
    if (fn == 'report_incident') {
      reportIncidentInvokeCount++;
      lastReportIncidentParams = params;
      return {'incident_id': 'incident-test-001'};
    }
    if (fn == 'propose_extension') {
      onProposeExtension?.call(params ?? {});
      return {
        'extension_id': 'ext-1',
        'fare_delta': {'amount': '150.00', 'currency': 'NGN'},
        'new_total': {'amount': '600.00', 'currency': 'NGN'},
        'tier': 1,
        'unconfirmed': false,
      };
    }
    if (fn == 'respond_extension') {
      respondExtensionInvokeCount++;
      onRespondExtension?.call(params ?? {});
      return {'trip': sampleTripView(tripId: 'trip-1', status: 'in_transit')};
    }
    if (fn == 'create_payment_request') {
      final tripId = params?['p_trip_id'] as String? ?? 'trip-1';
      final expiresAt = DateTime.utc(2026, 9, 6, 12, 10);
      final token = 'signed-token-$tripId';
      final url = publicOrigin == null || publicOrigin!.isEmpty
          ? 'along://p/$driverCode?t=$token'
          : '$publicOrigin/p/$driverCode?t=$token';
      final payload = {
        'url': url,
        'token': token,
        'amount': {'amount': '450.00', 'currency': 'NGN'},
        'expires_at': expiresAt.toIso8601String(),
      };
      paymentRequestsByTrip[tripId] = payload;
      return payload;
    }
    if (fn == 'rotate_driver_code') {
      driverCode = 'NEWCODE1';
      return {
        'driver_code': driverCode,
        'rotated_at': DateTime.utc(2026, 9, 6).toIso8601String(),
      };
    }
    if (fn == 'set_accepts_digital') {
      acceptsDigital = params?['p_enabled'] as bool? ?? true;
      return {'accepts_digital': acceptsDigital};
    }
    if (fn == 'request_qr_sticker') {
      final row = {
        'id': 'sticker-${qrStickerRequests.length + 1}',
        'driver_code': driverCode,
        'reason': 'initial',
        'status': 'pending',
        'created_at': DateTime.utc(2026, 9, 6).toIso8601String(),
      };
      qrStickerRequests.insert(0, row);
      return row;
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
      'rider': {'display_name': 'Ada', 'rating': 4.8, 'trip_count': 12},
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

  static Map<String, dynamic> sampleTripView({
    required String tripId,
    required String status,
    bool loadFlagged = false,
    String paymentMethod = 'cash',
    String? approachBand,
    Map<String, dynamic>? wait,
  }) {
    final isRequested = status == 'requested';
    final isAccepted = status == 'accepted';
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
      'rider': {'display_name': 'Ada', 'rating': 4.8, 'trip_count': 12},
      'driver': <String, dynamic>{},
      'vehicle': <String, dynamic>{},
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
      'route_leg_ids': <dynamic>[],
      'fare': {
        'total': {'amount': '450.00', 'currency': 'NGN'},
        'tier': 1,
        'confidence': 1,
        'unconfirmed': false,
        'components': <dynamic>[],
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
      'timestamps': <String, dynamic>{},
      'payment_method': paymentMethod,
      if (isRequested) 'approach_band': approachBand ?? 'under_2',
      if (isAccepted)
        'wait':
            wait ??
            {
              'walk_eta_s': 180,
              'approach': 'approaching',
              'updated_at': '2026-09-05T13:30:00Z',
            },
    };
  }

  Map<String, dynamic> sampleTripRequestEnvelope({
    String tripId = 'trip-1',
    bool loadFlagged = true,
    String approachBand = 'under_2',
  }) {
    return {
      'type': 'trip_request',
      'expires_at': '2026-09-05T14:00:00Z',
      'trip': sampleTripView(
        tripId: tripId,
        status: 'requested',
        loadFlagged: loadFlagged,
        approachBand: approachBand,
      ),
    };
  }

  /// staging-otp invocations: (body, headers).
  final List<(Map<String, dynamic>, Map<String, String>)> stagingOtpCalls = [];
  String? stagingOtpCode;

  @override
  Future<Map<String, dynamic>> invokeFunction(
    String slug, {
    Map<String, dynamic>? body,
    AlongHttpMethod method = AlongHttpMethod.post,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    if (slug == 'staging-otp') {
      stagingOtpCalls.add((
        Map<String, dynamic>.from(body ?? {}),
        Map<String, String>.from(headers ?? {}),
      ));
      return {'otp': stagingOtpCode};
    }
    if (slug.startsWith('qr/resolve/')) {
      final code = slug.split('/').last;
      if (code != driverCode) {
        return const {'data': <String, dynamic>{}};
      }
      return {
        'data': {
          'driver': {
            'first_name': 'Musa',
            'plate': driverPlate,
            'mode': {'code': 'car'},
            'accepts_digital': acceptsDigital,
            'active': true,
          },
          'currency': 'NGN',
        },
      };
    }
    if (slug == 'verification-ocr') {
      return {
        'data': {
          'hints': {'full_name': 'Test Driver'},
        },
      };
    }
    if (slug == 'places-search') {
      return {
        'data': {'results': placesSearchResults},
      };
    }
    if (slug == 'settlement/initiate') {
      return {
        'data': {
          'settlement_id': 'settlement-1',
          'expires_at': '2026-09-06T12:00:00Z',
          'ussd_code': '*737#',
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
      final id = filters['id'];
      if (id != null) {
        return cities.where((row) => row['id'] == id).toList(growable: false);
      }
      return cities;
    }
    if (table == 'trips') return List.of(tripRows);
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
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '48'},
        ];
      }
      if (key == 'presence.ping_interval_moving_s') {
        return [
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '4'},
        ];
      }
      if (key == 'presence.ping_interval_still_s') {
        return [
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '15'},
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
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '150'},
        ];
      }
      if (key == 'graph.snap_radius_m') {
        return [
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '60'},
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
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '25'},
        ];
      }
      if (key == 'dispatch.max_cascade') {
        return [
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '3'},
        ];
      }
      if (key == 'driver.negotiation_poll_s') {
        return [
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '2'},
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
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '3'},
        ];
      }
      if (key == 'client.trip_location_sample_interval_s') {
        return [
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '5'},
        ];
      }
      if (key == 'motion.naMe.strobe_ms') {
        return [
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '250'},
        ];
      }
      if (key == 'motion.naMe.cycle_duration_s') {
        return [
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '8'},
        ];
      }
      if (key == 'sos.hold_duration_ms') {
        return [
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '600'},
        ];
      }
      if (key == 'rating.tags') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': '["polite","on_time","rude","unsafe","fair_fare","overcharged"]',
          },
        ];
      }
      if (key == 'payments.digital_enabled') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': digitalPaymentsEnabled.toString(),
          },
        ];
      }
      if (key == 'public.origin') {
        return [
          {
            'key': key,
            'scope_type': 'global',
            'scope_id': '*',
            'value': publicOrigin == null ? '""' : '"$publicOrigin"',
          },
        ];
      }
      if (key == 'dispatch.no_show_after_s') {
        return [
          {'key': key, 'scope_type': 'global', 'scope_id': '*', 'value': '300'},
        ];
      }
    }
    if (table == 'drivers') {
      return [
        {
          'id': _user?.id ?? 'test-driver-id',
          'verified_status': 'verified',
          'city_id': driverCityId,
          'standing': 'good_standing',
          'driver_code': driverCode,
          'accepts_digital': acceptsDigital,
          'payout_subaccount_code': hasPayoutSubaccount
              ? 'ACCT_test_subaccount'
              : null,
          'payout_bank_last4': hasPayoutSubaccount ? '1234' : null,
        },
      ];
    }
    if (table == 'profiles') {
      return [
        {
          'id': _user?.id ?? 'test-driver-id',
          'display_name': 'Musa Driver',
          'phone_e164': '+2348000000001',
        },
      ];
    }
    if (table == 'driver_vehicles') {
      return [
        {
          'driver_id': _user?.id ?? 'test-driver-id',
          'vehicle_id': 'test-vehicle-id',
          'active': true,
        },
      ];
    }
    if (table == 'vehicles') {
      return [
        {'id': 'test-vehicle-id', 'plate_number': driverPlate},
      ];
    }
    if (table == 'payments') {
      return digitalPayments
          .where((row) {
            for (final entry in filters.entries) {
              if (row[entry.key] != entry.value) return false;
            }
            return true;
          })
          .toList(growable: false);
    }
    if (table == 'qr_sticker_requests') {
      return qrStickerRequests
          .where((row) {
            for (final entry in filters.entries) {
              if (row[entry.key] != entry.value) return false;
            }
            return true;
          })
          .toList(growable: false);
    }
    if (table == 'settlements') {
      if (settlementRows.isNotEmpty) return settlementRows;
      return [
        {
          'id': 'settlement-1',
          'status': 'confirmed',
          'amount': 5200,
          'currency': 'NGN',
        },
      ];
    }
    if (table == 'trips') {
      return [
        {
          'id': 'trip-cash-1',
          'status': 'completed',
          'payment_method': 'cash',
          'fare_shown': 450,
          'ended_at': clock().toUtc().toIso8601String(),
          'destination_label': 'Area 1 Park',
        },
      ];
    }
    if (table == 'trip_extensions') {
      return tripExtensionRows
          .where((row) {
            for (final entry in filters.entries) {
              if (row[entry.key] != entry.value) return false;
            }
            return true;
          })
          .toList(growable: false);
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
  {
    'id': '0a000000-0000-4000-8000-000000000001',
    'name': 'Zaria-Test',
    'slug': 'zaria-test',
    'country_code': 'NG',
    'status': 'live',
  },
];

Map<String, GeoPoint> defaultCityCentroids() => {
  'b1000000-0000-4000-8000-000000000001': const GeoPoint(
    lat: 9.057,
    lng: 7.495,
  ),
  '0a000000-0000-4000-8000-000000000001': const GeoPoint(
    lat: 11.066,
    lng: 7.702,
  ),
};

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
  'phone_prefix': '+234',
  'currency_code': 'NGN',
  'currency_symbol': '₦',
  'currency_minor_units': 2,
  'verification_schema': defaultVerificationSchema(),
  'regulatory_flags': {'plate_pattern': r'^[A-Za-z]{3}[-\s]?\d{3}[A-Za-z]{2}$'},
};

List<Map<String, dynamic>> defaultVerificationSchema() => [
  {'type': 'nin', 'label': 'NIN', 'pattern': r'^\d{11}$'},
  {
    'type': 'drivers_license',
    'label': "Driver's License",
    'pattern': r'^.{5,}$',
  },
];
