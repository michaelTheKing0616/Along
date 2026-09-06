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
    this.tripRows = const [],
    this.tripExtensionRows = const [],
    this.routeStageRows = const [],
    this.qrResolveResponse,
    this.qrResolveByCode = const {},
    this.paymentMethods = const [],
    this.paymentInitiateImmediateSuccess = true,
    FakeNegotiationEngine? negotiationEngine,
  }) : negotiationEngine = negotiationEngine ?? FakeNegotiationEngine();

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
  List<Map<String, dynamic>> tripRows;
  List<Map<String, dynamic>> tripExtensionRows;
  List<Map<String, dynamic>> routeStageRows;
  Map<String, dynamic>? qrResolveResponse;
  Map<String, Map<String, dynamic>> qrResolveByCode;
  List<Map<String, dynamic>> paymentMethods;
  bool paymentInitiateImmediateSuccess;

  final FakeNegotiationEngine negotiationEngine;

  int planTripInvokeCount = 0;
  int requestTripInvokeCount = 0;
  int tripSnapshotCallCount = 0;
  int markBoardedInvokeCount = 0;
  int confirmFareInvokeCount = 0;
  int rateTripInvokeCount = 0;
  int proposeExtensionInvokeCount = 0;
  int respondExtensionInvokeCount = 0;
  int qrResolveInvokeCount = 0;
  int paymentInitiateInvokeCount = 0;
  Map<String, dynamic>? lastPaymentInitiateBody;
  Map<String, dynamic>? lastConfirmFareParams;
  Map<String, dynamic>? lastRateTripParams;
  Map<String, dynamic>? lastProposeExtensionParams;
  Map<String, dynamic>? lastRespondExtensionParams;
  List<Map<String, dynamic>> tripSnapshotSequence = const [];
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
      tripSnapshotCallCount++;
      if (tripSnapshotSequence.isNotEmpty) {
        final index = tripSnapshotCallCount - 1;
        final clamped = index.clamp(0, tripSnapshotSequence.length - 1);
        return tripSnapshotSequence[clamped];
      }
      return requestTripResponse ?? {};
    }
    if (fn == 'mark_boarded') {
      markBoardedInvokeCount++;
      final base = requestTripResponse ?? {};
      return {
        ...base,
        'status': 'boarded',
      };
    }
    if (fn == 'cancel_trip') {
      return {};
    }
    if (fn == 'open_negotiation') {
      return negotiationEngine.open(params ?? {});
    }
    if (fn == 'negotiation_round') {
      return negotiationEngine.round(params ?? {});
    }
    if (fn == 'negotiation_split') {
      return negotiationEngine.split(params ?? {});
    }
    if (fn == 'hail_roaming') {
      return requestTripResponse ?? {};
    }
    if (fn == 'confirm_fare') {
      confirmFareInvokeCount++;
      lastConfirmFareParams = params;
      return {};
    }
    if (fn == 'rate_trip') {
      rateTripInvokeCount++;
      lastRateTripParams = params;
      return {};
    }
    if (fn == 'propose_extension') {
      proposeExtensionInvokeCount++;
      lastProposeExtensionParams = params;
      return {
        'extension_id': 'ext-test-1',
        'fare_delta': {'amount': '150.00', 'currency': 'NGN'},
        'new_total': {'amount': '600.00', 'currency': 'NGN'},
        'tier': 1,
        'unconfirmed': false,
      };
    }
    if (fn == 'respond_extension') {
      respondExtensionInvokeCount++;
      lastRespondExtensionParams = params;
      final base = requestTripResponse ?? {};
      return {
        'extension_id': params?['p_extension_id'],
        'status': params?['p_response'],
        if (params?['p_response'] == 'accept')
          'trip': {
            ...base,
            'status': 'in_transit',
          },
      };
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> invokeFunction(
    String slug, {
    Map<String, dynamic>? body,
    AlongHttpMethod method = AlongHttpMethod.post,
    Map<String, String>? queryParameters,
  }) async {
    if (slug.startsWith('qr/resolve/')) {
      qrResolveInvokeCount++;
      final code = slug.split('/').last;
      final payload = qrResolveByCode[code] ?? qrResolveResponse ?? sampleQrResolveMatchedTrip(code: code);
      return {'data': payload};
    }
    if (slug == 'payments/initiate') {
      paymentInitiateInvokeCount++;
      lastPaymentInitiateBody = body;
      final amount = (body?['amount'] as num?)?.toDouble() ?? 850.0;
      final commission = (amount * 0.05 * 100).round() / 100;
      final driverAmount = amount - commission;
      return {
        'data': {
          'payment_id': 'pay-test-001',
          'amount': amount,
          'commission_amount': commission,
          'driver_amount': driverAmount,
          'expires_at': DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
          if (paymentInitiateImmediateSuccess) 'status': 'succeeded',
        },
      };
    }
    if (slug == 'payments/methods') {
      if (body?['action'] == 'add') {
        paymentMethods = [
          ...paymentMethods,
          {
            'id': 'pm-${paymentMethods.length + 1}',
            'brand': body?['brand'] ?? 'Visa',
            'last4': body?['last4'] ?? '4242',
            'is_default': body?['set_default'] ?? true,
          },
        ];
      } else if (body?['action'] == 'remove') {
        paymentMethods = paymentMethods
            .where((m) => m['id'] != body?['payment_method_id'])
            .toList(growable: false);
      } else if (body?['action'] == 'default') {
        paymentMethods = paymentMethods
            .map(
              (m) => {
                ...m,
                'is_default': m['id'] == body?['payment_method_id'],
              },
            )
            .toList(growable: false);
      }
      return {'data': {'methods': paymentMethods}};
    }
    if (slug.startsWith('payments/receipt/')) {
      return {
        'data': {
          'payment_id': slug.split('/').last,
          'amount': 850.0,
          'commission_amount': 42.5,
          'driver_amount': 807.5,
          'driver_first_name': 'Musa',
          'currency': 'NGN',
        },
      };
    }
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
    if (table == 'trips') {
      return tripRows
          .where((row) {
            for (final entry in filters.entries) {
              if (row[entry.key] != entry.value) return false;
            }
            return true;
          })
          .toList(growable: false);
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
    if (table == 'route_stages') {
      return routeStageRows
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
        'key': 'client.trip_poll_interval_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '3',
      },
      {
        'key': 'boarding.colocation_radius_m',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '25',
      },
      {
        'key': 'realtime.heartbeat_stale_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '15',
      },
      {
        'key': 'realtime.live_paused_after_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '30',
      },
      {
        'key': 'presence.offline_after_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '180',
      },
      {
        'key': 'motion.naMe.strobe_ms',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '250',
      },
      {
        'key': 'motion.naMe.cycle_duration_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '8',
      },
      {
        'key': 'sos.hold_duration_ms',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '600',
      },
      {
        'key': 'payments.digital_enabled',
        'scope_type': 'global',
        'scope_id': '*',
        'value': 'false',
      },
      {
        'key': 'rating.tags',
        'scope_type': 'global',
        'scope_id': '*',
        'value': [
          'safe_driving',
          'fair_fare',
          'clean_vehicle',
          'polite',
          'on_time',
        ],
      },
    ];

/// Compact qr/resolve fixture for matched-trip scan (≤ 2 KB — TS-UI-06 2G gate).
Map<String, dynamic> sampleQrResolveMatchedTrip({
  String code = 'TEST0301',
  String tripId = 'trip-accepted-1',
  double amount = 850.0,
  String? warning,
}) =>
    {
      'driver': {
        'first_name': 'Musa',
        'plate': 'ABC-123-XY',
        'mode': {'code': 'keke', 'label': 'Keke'},
        'accepts_digital': true,
        'active': true,
      },
      'context': {
        'trip_id': tripId,
        'amount': {'amount': amount.toStringAsFixed(2), 'currency': 'NGN'},
        'label': 'Trip fare',
        'locked': true,
      },
      'suggested_amounts': [],
      'currency': 'NGN',
      if (warning != null) 'warning': warning,
    };

Map<String, dynamic> sampleQrResolveDifferentDriver({String code = 'TEST0301'}) =>
    sampleQrResolveMatchedTrip(code: code, warning: 'different_driver');

List<Map<String, dynamic>> sampleSavedPaymentMethods() => [
      {
        'id': 'pm-default-1',
        'brand': 'Visa',
        'last4': '4242',
        'is_default': true,
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
  int etaBandS = 180,
  String candidateToken = 'tok-test-1',
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
      'eta_band_s': etaBandS,
      'candidate_token': candidateToken,
    };

/// In-memory negotiation state machine for widget tests.
class FakeNegotiationEngine {
  FakeNegotiationEngine({
    this.chipSteps = const [100, 50, 50, 100],
    this.defaultRoundCap = 4,
    this.roundTimeoutS = 20,
    this.expiresAt = '2026-09-05T16:01:00Z',
  });

  List<int> chipSteps;
  final int defaultRoundCap;
  final int roundTimeoutS;
  String expiresAt;

  final Map<String, _FakeNegotiation> _sessions = {};
  int _seq = 0;

  Map<String, dynamic> open(Map<String, dynamic> params) {
    final id = 'neg-${++_seq}';
    final context = params['p_context'] as String? ?? 'park';
    final etaBand = _etaBandForContext(context, params);
    final roundCap = _roundCapForBand(context, etaBand);
    final session = _FakeNegotiation(
      id: id,
      context: context,
      anchor: 600,
      amount: 600,
      roundCap: roundCap,
      roundTimeoutS: roundTimeoutS,
      etaBand: etaBand,
      expiresAt: expiresAt,
      proposedBy: 'rider',
      round: 1,
      riderAmount: 600,
    );
    _sessions[id] = session;
    return session.openPayload(chipSteps);
  }

  Map<String, dynamic> round(Map<String, dynamic> params) {
    final id = params['p_negotiation_id'] as String;
    final action = params['p_action'] as String;
    final session = _sessions[id];
    if (session == null) throw StateError('unknown negotiation');

    if (action == 'decline') {
      session.status = 'declined';
      return session.viewPayload(chipSteps);
    }

    if (action == 'accept') {
      session.status = 'agreed';
      session.trip = _sampleTrip();
      return session.viewPayload(chipSteps);
    }

    final amountMap = params['p_amount'] as Map<String, dynamic>?;
    final amount = amountMap == null
        ? session.amount
        : double.parse(amountMap['amount'] as String).round();
    session.round++;
    session.amount = amount;
    session.proposedBy = 'rider';
    session.riderAmount = amount;

    if (session.round >= session.roundCap) {
      session.driverAmount = amount + 50;
      session.amount = session.driverAmount!;
      session.proposedBy = 'driver';
    } else {
      session.driverAmount = amount - 25;
      session.amount = session.driverAmount!;
      session.proposedBy = 'driver';
    }

    return session.viewPayload(chipSteps);
  }

  Map<String, dynamic> split(Map<String, dynamic> params) {
    final id = params['p_negotiation_id'] as String;
    final session = _sessions[id];
    if (session == null) throw StateError('unknown negotiation');
    final mid = ((session.riderAmount + (session.driverAmount ?? session.amount)) / 2)
        .round();
    session.round++;
    session.amount = mid;
    session.proposedBy = 'system';
    return session.viewPayload(chipSteps);
  }

  void lapse(String id) {
    final session = _sessions[id];
    if (session == null) return;
    session.status = 'lapsed';
  }

  String _etaBandForContext(String context, Map<String, dynamic> params) {
    if (context != 'roaming') return 'full';
    final token = params['p_candidate_token'] as String? ?? '';
    if (token.contains('none')) return 'none';
    if (token.contains('single')) return 'single';
    return 'full';
  }

  int _roundCapForBand(String context, String etaBand) {
    if (context == 'roaming') {
      return switch (etaBand) {
        'none' => 0,
        'single' => 1,
        _ => 3,
      };
    }
    return defaultRoundCap;
  }

  Map<String, dynamic> _sampleTrip() => {
        'trip_id': 'trip-neg-1',
        'journey_id': 'journey-1',
        'journey_sequence': 1,
        'status': 'requested',
        'mode': {
          'code': 'keke',
          'label': 'Keke',
          'icon_key': 'keke',
          'color_token': 'modeKeke',
        },
        'rider': {},
        'driver': {},
        'vehicle': {},
        'board': {
          'stage_id': 's-lugbe',
          'name': 'Lugbe Park',
          'location': {'lat': 9.01, 'lng': 7.40},
          'walk_m': 240,
          'walk_s': 240,
          'wayfinding_available': true,
        },
        'alight': {
          'stage_id': 's-area1',
          'name': 'Area 1 Park',
          'location': {'lat': 9.05, 'lng': 7.45},
        },
        'route_leg_ids': ['leg-1'],
        'fare': {
          'total': {'amount': '575.00', 'currency': 'NGN'},
          'tier': 3,
          'confidence': 0.5,
          'unconfirmed': false,
          'components': [],
          'quote_id': 'quote-neg',
          'expires_at': '2026-09-05T16:05:00Z',
        },
        'load': {'flagged': false},
        'women_only': false,
        'na_me': {
          'color_token': 'green',
          'shape': 'diamond',
          'label': 'Green Diamond',
        },
        'live_channel': 'trip:trip-neg-1',
        'expires_at': '2026-09-05T16:05:00Z',
        'timestamps': {},
      };
}

class _FakeNegotiation {
  _FakeNegotiation({
    required this.id,
    required this.context,
    required this.anchor,
    required this.amount,
    required this.roundCap,
    required this.roundTimeoutS,
    required this.etaBand,
    required this.expiresAt,
    required this.proposedBy,
    required this.round,
    required this.riderAmount,
    this.driverAmount,
    this.status = 'open',
    this.trip,
  });

  final String id;
  final String context;
  final int anchor;
  int amount;
  final int roundCap;
  final int roundTimeoutS;
  final String etaBand;
  String expiresAt;
  String proposedBy;
  int round;
  int riderAmount;
  int? driverAmount;
  String status;
  Map<String, dynamic>? trip;

  Map<String, dynamic> openPayload(List<int> chipSteps) => {
        'negotiation_id': id,
        'anchor': {'amount': anchor.toStringAsFixed(2), 'currency': 'NGN'},
        'chip_steps': [
          for (final s in chipSteps)
            {'amount': s.toStringAsFixed(2), 'currency': 'NGN'},
        ],
        'round_cap': roundCap,
        'round_timeout_s': roundTimeoutS,
        'eta_band': etaBand,
        'expires_at': expiresAt,
      };

  Map<String, dynamic> viewPayload(List<int> chipSteps) => {
        'negotiation_id': id,
        'status': status,
        'context': context,
        'anchor': {'amount': anchor.toStringAsFixed(2), 'currency': 'NGN'},
        'agreed_amount': status == 'agreed'
            ? {'amount': amount.toStringAsFixed(2), 'currency': 'NGN'}
            : null,
        'round_cap': roundCap,
        'round_timeout_s': roundTimeoutS,
        'eta_band': etaBand,
        'expires_at': expiresAt,
        'round': round,
        'amount': {'amount': amount.toStringAsFixed(2), 'currency': 'NGN'},
        'proposed_by': proposedBy,
        'chip_steps': [
          for (final s in chipSteps)
            {'amount': s.toStringAsFixed(2), 'currency': 'NGN'},
        ],
        'trip': trip,
      };
}

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
