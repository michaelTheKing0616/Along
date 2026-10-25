import 'dart:async';

import 'package:along_core/along_core.dart';
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
    this.planTripError,
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
    this.paymentInitiateTransferAccount,
    this.paymentReceiptStatus,
    this.raiseSosDelay = Duration.zero,
    this.raiseSosResponse,
    this.tripShareRows = const [],
    this.profileRow,
    this.riderRow,
    this.cityRegulatoryFlags = const {'women_only_matching': true},
    List<Map<String, dynamic>>? cityRows,
    Map<String, GeoPoint>? cityCentroids,
    this.itineraryStateResponse,
    this.parseItineraryResponse,
    this.sponsoredPlacementsResponse = const [],
    this.corridorRows = const [],
    Map<String, dynamic>? countryRow,
    Map<String, dynamic>? deploymentRow,
    FakeNegotiationEngine? negotiationEngine,
  })  : cityRows = cityRows ?? defaultCityRows(),
        cityCentroids = cityCentroids ?? defaultCityCentroids(),
        countryRow = countryRow ?? defaultCountryRow(),
        deploymentRow = deploymentRow ?? defaultDeploymentRow(),
        negotiationEngine = negotiationEngine ?? FakeNegotiationEngine();

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
  Object? planTripError;
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
  Map<String, dynamic>? paymentInitiateTransferAccount;
  String? paymentReceiptStatus;
  Duration raiseSosDelay;
  Map<String, dynamic>? raiseSosResponse;
  List<Map<String, dynamic>> tripShareRows;
  Map<String, dynamic>? profileRow;
  Map<String, dynamic>? riderRow;
  Map<String, dynamic> cityRegulatoryFlags;
  List<Map<String, dynamic>> cityRows;
  Map<String, GeoPoint> cityCentroids;
  Map<String, dynamic>? itineraryStateResponse;
  Map<String, dynamic>? parseItineraryResponse;
  List<Map<String, dynamic>> sponsoredPlacementsResponse;
  List<Map<String, dynamic>> corridorRows;

  final Map<String, dynamic> countryRow;
  final Map<String, dynamic> deploymentRow;

  final FakeNegotiationEngine negotiationEngine;

  int planTripInvokeCount = 0;
  int requestTripInvokeCount = 0;
  int createItineraryInvokeCount = 0;
  int updateItineraryStopsInvokeCount = 0;
  int itineraryStateInvokeCount = 0;
  int itineraryMatchNextInvokeCount = 0;
  int parseItineraryInvokeCount = 0;
  int tripSnapshotCallCount = 0;
  int markBoardedInvokeCount = 0;
  int confirmFareInvokeCount = 0;
  int rateTripInvokeCount = 0;
  int proposeExtensionInvokeCount = 0;
  int respondExtensionInvokeCount = 0;
  int qrResolveInvokeCount = 0;
  int paymentInitiateInvokeCount = 0;
  int raiseSosInvokeCount = 0;
  int updateSosInvokeCount = 0;
  int reportIncidentInvokeCount = 0;
  int createTripShareInvokeCount = 0;
  int revokeTripShareInvokeCount = 0;
  Map<String, dynamic>? lastRaiseSosParams;
  Map<String, dynamic>? lastReportIncidentParams;
  Map<String, dynamic>? lastUpdateRiderPrefsParams;
  Map<String, dynamic>? lastCreateItineraryParams;
  Map<String, dynamic>? lastUpdateItineraryStopsParams;
  Map<String, dynamic>? lastPaymentInitiateBody;
  Map<String, dynamic>? lastConfirmFareParams;
  Map<String, dynamic>? lastRateTripParams;
  Map<String, dynamic>? lastProposeExtensionParams;
  Map<String, dynamic>? lastRespondExtensionParams;
  List<Map<String, dynamic>> tripSnapshotSequence = const [];
  Map<String, dynamic>? lastRequestTripParams;
  final List<(String fn, Map<String, dynamic> params)> rpcCalls = [];

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
    final p = params ?? {};
    rpcCalls.add((fn, Map<String, dynamic>.from(p)));
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
    if (fn == 'raise_sos') {
      raiseSosInvokeCount++;
      lastRaiseSosParams = params;
      if (raiseSosDelay > Duration.zero) {
        await Future<void>.delayed(raiseSosDelay);
      }
      return raiseSosResponse ??
          {
            'sos_id': 'sos-test-001',
            'emergency_number': '112',
          };
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
    if (fn == 'create_trip_share') {
      createTripShareInvokeCount++;
      final shareId = 'share-${tripShareRows.length + 1}';
      final url = 'https://along.ng/s/test-token-$shareId';
      final expiresAt =
          DateTime.now().add(const Duration(hours: 6)).toUtc().toIso8601String();
      tripShareRows = [
        ...tripShareRows,
        {
          'id': shareId,
          'journey_id': params?['p_journey_id'],
          'expires_at': expiresAt,
          'revoked_at': null,
          'contact_name': params?['p_contact_name'],
        },
      ];
      return {
        'url': url,
        'expires_at': expiresAt,
        'share_id': shareId,
      };
    }
    if (fn == 'revoke_trip_share') {
      revokeTripShareInvokeCount++;
      final shareId = params?['p_share_id'] as String?;
      tripShareRows = tripShareRows
          .map(
            (row) => row['id'] == shareId
                ? {
                    ...row,
                    'revoked_at': DateTime.now().toUtc().toIso8601String(),
                  }
                : row,
          )
          .toList(growable: false);
      return {'share_id': shareId};
    }
    if (fn == 'shared_trip_view') {
      return {
        'rider_first_name': 'Ada',
        'status': 'in_transit',
        'mode': {'code': 'keke', 'label': 'Keke'},
        'vehicle': {'plate': 'SHR-01', 'color': 'Yellow'},
        'driver_first_name': 'Musa',
        'current_location': {'lat': 9.05, 'lng': 7.49},
        'destination_label': 'Area 1',
        'eta_s': 420,
        'legs_progress': [
          {'sequence': 1, 'status': 'current', 'label': 'Lugbe → Area 1'},
        ],
      };
    }
    if (fn == 'update_rider_prefs') {
      lastUpdateRiderPrefsParams = params;
      if (riderRow != null) {
        riderRow = {
          ...riderRow!,
          if (params?['wayfinding_mode'] != null)
            'wayfinding_mode': params!['wayfinding_mode'],
          if (params?['saved_sort'] != null) 'saved_sort': params!['saved_sort'],
          if (params?['women_only_pref'] != null)
            'women_only_pref': params!['women_only_pref'],
        };
      }
      return {};
    }
    if (fn == 'set_home_city') {
      final nextCityId = params?['p_city_id'] as String?;
      if (nextCityId != null) {
        cityId = nextCityId;
        if (riderRow != null) {
          riderRow = {...riderRow!, 'home_city_id': nextCityId};
        }
      }
      return {};
    }
    if (fn == 'city_centroid') {
      final id = params?['p_city_id'] as String? ?? cityId;
      final centroid = cityCentroids[id];
      if (centroid == null) return {};
      return {'lat': centroid.lat, 'lng': centroid.lng};
    }
    if (fn == 'create_itinerary') {
      createItineraryInvokeCount++;
      lastCreateItineraryParams = params;
      return itineraryStateResponse ?? sampleItineraryStateJson();
    }
    if (fn == 'update_itinerary_stops') {
      updateItineraryStopsInvokeCount++;
      lastUpdateItineraryStopsParams = params;
      return itineraryStateResponse ?? sampleItineraryStateJson();
    }
    if (fn == 'itinerary_state') {
      itineraryStateInvokeCount++;
      return itineraryStateResponse ?? sampleItineraryStateJson();
    }
    if (fn == 'itinerary_match_next') {
      itineraryMatchNextInvokeCount++;
      return sampleItineraryStateWithPreparedPlan();
    }
    if (fn == 'resolve_sponsored_placements') {
      PlacementsRepository.assertNoPersonalIdentifiers(params ?? {});
      return sponsoredPlacementsResponse;
    }
    if (fn == 'record_placement_counter') {
      PlacementsRepository.assertNoPersonalIdentifiers(params ?? {});
      return {};
    }
    return {};
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
      stagingOtpCalls.add((Map<String, dynamic>.from(body ?? {}), Map<String, String>.from(headers ?? {})));
      return {'otp': stagingOtpCode};
    }
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
          if (paymentInitiateTransferAccount != null)
            'transfer_account': paymentInitiateTransferAccount,
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
          'status': paymentReceiptStatus ??
              (paymentInitiateImmediateSuccess ? 'succeeded' : 'pending'),
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
      if (planTripError != null) throw planTripError!;
      if (planTripDelay > Duration.zero) {
        await Future<void>.delayed(planTripDelay);
      }
      return planTripResponse ?? {'data': {'candidates': []}};
    }
    if (slug == 'parse-itinerary') {
      parseItineraryInvokeCount++;
      return parseItineraryResponse ??
          {
            'data': {
              'proposal': [
                {
                  'sequence': 1,
                  'destination_description': 'School',
                  'resolved': null,
                },
                {
                  'sequence': 2,
                  'destination_description': 'Work',
                  'resolved': {
                    'label': 'Area 1',
                    'location': {'lat': 9.08, 'lng': 7.45},
                    'confidence': 0.8,
                  },
                },
              ],
              'needs_confirmation': true,
            },
          };
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
      if (inColumn == 'status' && inValues != null) {
        return cityRows
            .where((row) => inValues.contains(row['status']))
            .toList(growable: false);
      }
      final id = filters['id'];
      final slug = filters['slug'];
      if (id != null) {
        return cityRows.where((row) => row['id'] == id).toList(growable: false);
      }
      if (slug != null) {
        return cityRows.where((row) => row['slug'] == slug).toList(growable: false);
      }
      if (cityId != null) {
        return cityRows.where((row) => row['id'] == cityId).toList(growable: false);
      }
      return cityRows;
    }
    if (table == 'profiles') {
      final id = filters['id'];
      if (profileRow != null && profileRow!['id'] == id) {
        return [profileRow!];
      }
      if (id == _user?.id) {
        return [
          profileRow ??
              {
                'id': id,
                'display_name': 'Test Rider',
                'phone_e164': '+2348000000001',
              },
        ];
      }
      return [];
    }
    if (table == 'riders') {
      final id = filters['id'];
      if (riderRow != null && riderRow!['id'] == id) {
        return [riderRow!];
      }
      if (id == _user?.id) {
        return [
          riderRow ??
              {
                'id': id,
                'home_city_id': cityId,
                'wayfinding_mode': 'text',
                'saved_sort': 'recommended',
                'women_only_pref': false,
              },
        ];
      }
      return [];
    }
    if (table == 'trip_shares') {
      return tripShareRows
          .where((row) {
            for (final entry in filters.entries) {
              if (row[entry.key] != entry.value) return false;
            }
            return true;
          })
          .toList(growable: false);
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
    if (table == 'corridors') {
      return corridorRows
          .where((row) {
            for (final entry in filters.entries) {
              if (row[entry.key] != entry.value) return false;
            }
            return true;
          })
          .toList(growable: false);
    }
    if (table == 'countries') {
      final code = filters['code'];
      if (code != null && countryRow['code'] == code) {
        return [countryRow];
      }
      if (filters['active'] == true) {
        return [countryRow];
      }
      return [];
    }
    if (table == 'deployments') {
      final id = filters['id'];
      if (id != null && deploymentRow['id'] == id) {
        return [deploymentRow];
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
      {
        'key': 'client.trip_poll_interval_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '3',
      },
      {
        'key': 'client.low_data_tile_max_zoom',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '15',
      },
      {
        'key': 'client.ambient_poll_interval_s',
        'scope_type': 'global',
        'scope_id': '*',
        'value': '30',
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
        'key': 'sos.emergency_number',
        'scope_type': 'country',
        'scope_id': 'NG',
        'value': '112',
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

/// Default NG country + Along NG deployment for catalog/branding tests.
Map<String, dynamic> defaultCountryRow() => {
      'code': 'NG',
      'name': 'Nigeria',
      'currency_code': 'NGN',
      'currency_minor_units': 2,
      'currency_symbol': '₦',
      'phone_prefix': '+234',
      'default_locale': 'en-NG',
      'timezone': 'Africa/Lagos',
      'deployment_id': 'a0000000-0000-4000-8000-000000000001',
      'verification_schema': const [],
      'regulatory_flags': const {'plate_pattern': r'^[A-Za-z]{3}[-\s]?\d{3}[A-Za-z]{2}$'},
      'active': true,
    };

Map<String, dynamic> defaultDeploymentRow() => {
      'id': 'a0000000-0000-4000-8000-000000000001',
      'tenant_name': 'Along NG',
      'branding_config': const {},
      'region_config': const {},
      'active': true,
    };

/// Default `load.warn_capacities` + `mode_config` rows for FM36 tests.
List<Map<String, dynamic>> defaultCityRows() => [
      {
        'id': 'b1000000-0000-4000-8000-000000000001',
        'name': 'Abuja',
        'slug': 'abuja',
        'country_code': 'NG',
        'status': 'live',
        'regulatory_flags': {'women_only_matching': true},
      },
      {
        'id': '0a000000-0000-4000-8000-000000000001',
        'name': 'Zaria-Test',
        'slug': 'zaria-test',
        'country_code': 'NG',
        'status': 'live',
        'regulatory_flags': const {},
      },
    ];

Map<String, GeoPoint> defaultCityCentroids() => {
      'b1000000-0000-4000-8000-000000000001':
          const GeoPoint(lat: 9.057, lng: 7.495),
      '0a000000-0000-4000-8000-000000000001':
          const GeoPoint(lat: 11.066, lng: 7.702),
    };

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

Map<String, dynamic> sampleItineraryStateJson({
  String itineraryId = 'itin-test-001',
  String nextStopId = 'stop-2',
  bool withPreparedPlan = false,
  bool loadFlagged = false,
  String? loadSize,
  String? loadNote,
}) {
  final preparedPlan = {
    'query_id': 'query-itin-1',
    'city_id': 'b1000000-0000-4000-8000-000000000001',
    'degraded': false,
    'candidates': [
      {
        'candidate_id': 'cand-itin-1',
        'kind': 'direct',
        'source': 'parked',
        'viable_direct': true,
        'legs': [
          {
            'leg_index': 0,
            'mode': {
              'code': 'keke',
              'label': 'Keke',
              'icon_key': 'keke',
              'color_token': 'modeKeke',
            },
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
            'route_id': 'route-1',
            'route_leg_ids': ['leg-1'],
            'in_vehicle_s': 900,
            'wait_s': 360,
            'fare': {
              'total': {'amount': '450.00', 'currency': 'NGN'},
              'tier': 1,
              'confidence': 0.95,
              'unconfirmed': false,
              'quote_id': 'quote-itin-1',
              'expires_at': '2026-09-05T16:00:00Z',
            },
            'supply': {'kind': 'parked', 'vehicles_bucket': '1-2'},
            'load_warning': null,
          },
        ],
        'transfers': [],
        'metrics': {
          'total_fare_minor': 45000,
          'total_time_s': 1500,
          'transfer_count': 0,
          'total_walking_distance_m': 240,
          'strenuousness_score': 0.2,
          'recommended_score': 1.0,
          'explain': {'fare': 0.4, 'time': 0.4, 'strenuous': 0.2},
        },
      },
    ],
    'sort_orders': {
      'recommended': ['cand-itin-1'],
      'cheapest': ['cand-itin-1'],
      'fastest': ['cand-itin-1'],
      'least_strenuous': ['cand-itin-1'],
    },
    'coverage_gap': null,
    'candidate_set_only': true,
    'match_requires_request_trip': true,
  };

  final stop1 = {
    'id': 'stop-1',
    'sequence': 1,
    'destination_description': 'School',
    'destination_location': {'lat': 9.05, 'lng': 7.40},
    'status': 'completed',
    'linked_journey_id': null,
    'prepared_plan': null,
  };
  final stop2 = {
    'id': nextStopId,
    'sequence': 2,
    'destination_description': 'Work',
    'destination_location': {'lat': 9.08, 'lng': 7.45},
    'status': 'pending',
    'linked_journey_id': null,
    'prepared_plan': withPreparedPlan ? preparedPlan : null,
  };
  return {
    'itinerary_id': itineraryId,
    'status': 'active',
    'plan_date': '2026-09-07',
    'load_flagged': loadFlagged,
    'load_size': loadSize,
    'load_note': loadNote,
    'stops': [stop1, stop2],
    'next_pending_stop_id': nextStopId,
    'next_prepared_plan': withPreparedPlan ? preparedPlan : null,
    'not_booked': true,
    'match_action': 'request_trip',
  };
}

Map<String, dynamic> sampleItineraryStateWithPreparedPlan() =>
    sampleItineraryStateJson(withPreparedPlan: true);

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
  String status = 'open';
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
