import 'package:along_data/src/seats/ride_rules.dart';
import 'package:along_data/src/seats/seat_layout.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

class SavedLayout {
  const SavedLayout({
    required this.id,
    required this.vehicleId,
    required this.name,
    required this.layout,
    required this.passengerSeats,
    required this.overCapacity,
    required this.isActive,
  });

  final String id;
  final String vehicleId;
  final String name;
  final SeatLayout layout;
  final int passengerSeats;
  final bool overCapacity;
  final bool isActive;

  factory SavedLayout.fromJson(Map<String, dynamic> json) {
    return SavedLayout(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      name: json['name'] as String? ?? '',
      layout: SeatLayout.fromJson(_map(json['layout'])),
      passengerSeats: (json['passenger_seats'] as num?)?.toInt() ?? 0,
      overCapacity: json['over_capacity'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}

class DayVehicle {
  const DayVehicle({
    required this.id,
    required this.modeCode,
    required this.plateNumber,
    required this.seatCapacity,
    required this.reviewSeatMax,
    this.color,
    this.makeModel,
    this.layoutPreset,
  });

  final String id;
  final String modeCode;
  final String plateNumber;
  final int seatCapacity;
  final int reviewSeatMax;
  final String? color;
  final String? makeModel;
  final Map<String, dynamic>? layoutPreset;

  factory DayVehicle.fromJson(Map<String, dynamic> json) {
    final preset = json['layout_preset'];
    return DayVehicle(
      id: json['id'] as String,
      modeCode: json['mode_code'] as String? ?? '',
      plateNumber: json['plate_number'] as String? ?? '',
      seatCapacity: (json['seat_capacity'] as num?)?.toInt() ?? 1,
      reviewSeatMax: (json['review_seat_max'] as num?)?.toInt() ?? 1,
      color: json['color'] as String?,
      makeModel: json['make_model'] as String?,
      layoutPreset: preset is Map ? _map(preset) : null,
    );
  }
}

class DayCorridor {
  const DayCorridor({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory DayCorridor.fromJson(Map<String, dynamic> json) => DayCorridor(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
  );
}

class DayRoute {
  const DayRoute({
    required this.id,
    required this.modeCode,
    this.name,
    this.corridorId,
  });

  final String id;
  final String modeCode;
  final String? name;
  final String? corridorId;

  factory DayRoute.fromJson(Map<String, dynamic> json) => DayRoute(
    id: json['id'] as String,
    modeCode: json['mode_code'] as String? ?? '',
    name: json['name'] as String?,
    corridorId: json['corridor_id'] as String?,
  );
}

class DaySetup {
  const DaySetup({
    required this.vehicles,
    required this.layouts,
    required this.corridors,
    required this.routes,
    required this.rules,
    required this.presets,
  });

  final List<DayVehicle> vehicles;
  final List<SavedLayout> layouts;
  final List<DayCorridor> corridors;
  final List<DayRoute> routes;
  final List<RideRule> rules;
  final List<RideRulePreset> presets;

  factory DaySetup.fromJson(Map<String, dynamic> json) {
    return DaySetup(
      vehicles: _list(json['vehicles'], DayVehicle.fromJson),
      layouts: _list(json['layouts'], SavedLayout.fromJson),
      corridors: _list(json['corridors'], DayCorridor.fromJson),
      routes: _list(json['routes'], DayRoute.fromJson),
      rules: _list(json['rules'], RideRule.fromJson),
      presets: _list(json['presets'], RideRulePreset.fromJson),
    );
  }
}

class SeatState {
  const SeatState({
    required this.seatId,
    required this.status,
    required this.version,
    this.holdUntil,
    this.updatedAt,
  });

  final String seatId;
  final String status;
  final int version;
  final DateTime? holdUntil;
  final DateTime? updatedAt;

  factory SeatState.fromJson(Map<String, dynamic> json) {
    return SeatState(
      seatId: json['seat_id'] as String,
      status: json['status'] as String? ?? 'free',
      version: (json['version'] as num?)?.toInt() ?? 1,
      holdUntil: _time(json['hold_until']),
      updatedAt: _time(json['updated_at']),
    );
  }
}

class SeatBoard {
  const SeatBoard({
    required this.layoutId,
    required this.vehicleId,
    required this.layout,
    required this.freeCount,
    required this.seats,
    required this.rules,
    this.seatUpdatedAt,
    this.overCapacity = false,
  });

  final String layoutId;
  final String vehicleId;
  final SeatLayout layout;
  final int freeCount;
  final List<SeatState> seats;
  final List<RideRule> rules;
  final DateTime? seatUpdatedAt;
  final bool overCapacity;

  factory SeatBoard.fromJson(Map<String, dynamic> json) {
    return SeatBoard(
      layoutId: json['layout_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      layout: SeatLayout.fromJson(_map(json['layout'])),
      freeCount: (json['free'] as num?)?.toInt() ?? 0,
      seats: _list(json['seats'], SeatState.fromJson),
      rules: _list(json['rules'], RideRule.fromJson),
      seatUpdatedAt: _time(json['seat_updated_at']),
      overCapacity: json['over_capacity'] as bool? ?? false,
    );
  }
}

class VehicleCard {
  const VehicleCard({
    required this.driverId,
    required this.vehicleId,
    required this.layoutId,
    required this.plateNumber,
    required this.modeCode,
    required this.layout,
    required this.freeCount,
    required this.seats,
    required this.rules,
    this.color,
    this.makeModel,
    this.seatUpdatedAt,
  });

  final String driverId;
  final String vehicleId;
  final String layoutId;
  final String plateNumber;
  final String modeCode;
  final String? color;
  final String? makeModel;
  final SeatLayout layout;
  final int freeCount;
  final List<SeatState> seats;
  final List<RideRule> rules;
  final DateTime? seatUpdatedAt;

  bool hiddenAt(DateTime now) =>
      seatUpdatedAt != null && seatStateIsHidden(seatUpdatedAt!, now);

  bool staleAt(DateTime now) =>
      seatUpdatedAt != null && seatStateIsStale(seatUpdatedAt!, now);

  factory VehicleCard.fromJson(Map<String, dynamic> json) {
    return VehicleCard(
      driverId: json['driver_id'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? '',
      layoutId: json['layout_id'] as String,
      plateNumber: json['plate_number'] as String? ?? '',
      modeCode: json['mode_code'] as String? ?? '',
      color: json['color'] as String?,
      makeModel: json['make_model'] as String?,
      layout: SeatLayout.fromJson(_map(json['layout'])),
      freeCount: (json['free_count'] as num?)?.toInt() ?? 0,
      seats: _list(json['seats'], SeatState.fromJson),
      rules: _list(json['rules'], RideRule.fromJson),
      seatUpdatedAt: _time(json['seat_updated_at']),
    );
  }
}

class VehicleCardFeed {
  const VehicleCardFeed({required this.presets, required this.cards});

  final List<RideRulePreset> presets;
  final List<VehicleCard> cards;

  factory VehicleCardFeed.fromJson(Map<String, dynamic> json) {
    return VehicleCardFeed(
      presets: _list(json['presets'], RideRulePreset.fromJson),
      cards: _list(json['cards'], VehicleCard.fromJson),
    );
  }
}

class SeatClaimResult {
  const SeatClaimResult({
    required this.seatId,
    required this.status,
    required this.version,
    required this.freeCount,
    this.updatedAt,
    this.holdUntil,
  });

  final String seatId;
  final String status;
  final int version;
  final int freeCount;
  final DateTime? updatedAt;
  final DateTime? holdUntil;

  factory SeatClaimResult.fromJson(Map<String, dynamic> json) {
    return SeatClaimResult(
      seatId: json['seat_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      freeCount: (json['free'] as num?)?.toInt() ?? 0,
      updatedAt: _time(json['updated_at']),
      holdUntil: _time(json['hold_until']),
    );
  }

  Map<String, dynamic> toJson() => {
    'seat_id': seatId,
    'status': status,
    'version': version,
    'free': freeCount,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    if (holdUntil != null) 'hold_until': holdUntil!.toIso8601String(),
  };
}

class SeatRepository {
  SeatRepository(this._supabase);

  final AlongSupabase _supabase;

  Future<Map<String, dynamic>> saveVehicleLayout({
    required String vehicleId,
    required String name,
    required SeatLayout layout,
    bool activate = true,
  }) {
    return _call('save_vehicle_layout', {
      'p_vehicle_id': vehicleId,
      'p_name': name,
      'p_layout': layout.toJson(),
      'p_activate': activate,
    });
  }

  Future<DaySetup> myDaySetup() async {
    final raw = await _call('my_day_setup', const {});
    return DaySetup.fromJson(raw);
  }

  Future<RideRule> saveRideRule({
    required String vehicleId,
    String? presetId,
    String? title,
    String? body,
    Map<String, dynamic> params = const {},
    String? targetRef,
    bool enabled = true,
    String? ruleId,
  }) async {
    final raw = await _call('save_ride_rule', {
      'p_vehicle_id': vehicleId,
      'p_preset_id': presetId,
      'p_title': title,
      'p_body': body,
      'p_params': params,
      'p_target_ref': targetRef,
      'p_enabled': enabled,
      'p_rule_id': ruleId,
    });
    return RideRule.fromJson(raw);
  }

  Future<void> deleteRideRule(String ruleId) {
    return _call('delete_ride_rule', {'p_rule_id': ruleId});
  }

  Future<void> startDriverDay({
    required String vehicleId,
    required String layoutId,
    required String corridorId,
    String? routeId,
    String? shiftStart,
    String? shiftEnd,
    String? homeLabel,
  }) {
    return _call('start_driver_day', {
      'p_vehicle_id': vehicleId,
      'p_layout_id': layoutId,
      'p_corridor_id': corridorId,
      'p_route_id': routeId,
      'p_shift_start': shiftStart,
      'p_shift_end': shiftEnd,
      'p_home_label': homeLabel,
    });
  }

  Future<SeatBoard> seatBoard({String? layoutId}) async {
    final raw = await _call('seat_board', {'p_layout_id': layoutId});
    return SeatBoard.fromJson(raw);
  }

  Future<SeatClaimResult> setSeatStatus({
    required String layoutId,
    required String seatId,
    required String status,
  }) async {
    final raw = await _call('set_seat_status', {
      'p_layout_id': layoutId,
      'p_seat_id': seatId,
      'p_status': status,
    });
    return SeatClaimResult.fromJson(raw);
  }

  Future<SeatClaimResult> setAllSeats({
    required String layoutId,
    required String status,
  }) async {
    final raw = await _call('set_all_seats', {
      'p_layout_id': layoutId,
      'p_status': status,
    });
    return SeatClaimResult.fromJson(raw);
  }

  Future<SeatClaimResult> claimSeat({
    required String layoutId,
    required String seatId,
    required int expectedVersion,
    List<String> ackRuleIds = const [],
  }) async {
    final raw = await _call('claim_seat', {
      'p_layout_id': layoutId,
      'p_seat_id': seatId,
      'p_expected_version': expectedVersion,
      'p_ack_rule_ids': ackRuleIds,
    });
    return SeatClaimResult.fromJson(raw);
  }

  Future<SeatClaimResult> holdSeat({
    required String layoutId,
    required String seatId,
    required int expectedVersion,
    int? walkMinutes,
    List<String> ackRuleIds = const [],
  }) async {
    final raw = await _call('hold_seat', {
      'p_layout_id': layoutId,
      'p_seat_id': seatId,
      'p_expected_version': expectedVersion,
      'p_walk_minutes': walkMinutes,
      'p_ack_rule_ids': ackRuleIds,
    });
    return SeatClaimResult.fromJson(raw);
  }

  Future<SeatClaimResult> claimBundle({
    required String layoutId,
    required String ruleId,
    List<String> ackRuleIds = const [],
  }) async {
    final raw = await _call('claim_bundle', {
      'p_layout_id': layoutId,
      'p_rule_id': ruleId,
      'p_ack_rule_ids': ackRuleIds,
    });
    return SeatClaimResult.fromJson(raw);
  }

  Future<String> openConductorSession() async {
    final raw = await _call('open_conductor_session', {});
    return raw['code'] as String? ?? '';
  }

  Future<SeatBoard> conductorBoard(String code) async {
    final raw = await _call('conductor_board', {'p_code': code});
    return SeatBoard.fromJson(raw);
  }

  Future<SeatClaimResult> conductorSetSeat({
    required String code,
    required String seatId,
    required String status,
  }) async {
    final raw = await _call('conductor_set_seat', {
      'p_code': code,
      'p_seat_id': seatId,
      'p_status': status,
    });
    return SeatClaimResult.fromJson(raw);
  }

  Future<VehicleCardFeed> onlineVehicleCards({
    required String cityId,
    List<String> presetIds = const [],
    String? query,
  }) async {
    final raw = await _call('online_vehicle_cards', {
      'p_city_id': cityId,
      'p_preset_ids': presetIds,
      'p_query': query,
    });
    return VehicleCardFeed.fromJson(raw);
  }

  Future<VehicleCard?> cardForTrip(String tripId) async {
    final raw = await _call('vehicle_card_for_trip', {'p_trip_id': tripId});
    if (raw['layout'] == null) return null;
    return VehicleCard.fromJson(raw);
  }

  Future<Map<String, dynamic>> _call(
    String fn,
    Map<String, dynamic> params,
  ) async {
    try {
      final raw = await _supabase.rpc(fn, params: params);
      return _map(raw);
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }
}

Map<String, dynamic> _map(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

DateTime? _time(Object? raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.parse(raw);
  return null;
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map) parse(_map(item)),
  ];
}
