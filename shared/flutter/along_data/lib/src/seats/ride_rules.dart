import 'dart:convert';

import 'package:along_data/src/seats/seat_layout.dart';

/// A preset row. The effect vocabulary is fixed; the words belong to the data.
class RideRulePreset {
  const RideRulePreset({
    required this.id,
    required this.title,
    required this.effect,
    required this.targetScope,
    this.body,
    this.defaultParams = const {},
  });

  final String id;
  final String title;
  final String? body;
  final String effect;
  final String targetScope;
  final Map<String, dynamic> defaultParams;

  factory RideRulePreset.fromJson(Map<String, dynamic> json) {
    return RideRulePreset(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      effect: json['effect'] as String? ?? 'badge',
      targetScope: json['target_scope'] as String? ?? 'vehicle',
      defaultParams: _map(json['default_params']),
    );
  }
}

/// A rule the driver authored. Custom rules have a null [presetId] and effect badge.
class RideRule {
  const RideRule({
    required this.id,
    required this.effect,
    required this.targetScope,
    required this.title,
    required this.enabled,
    this.presetId,
    this.targetRef,
    this.body,
    this.params = const {},
  });

  final String id;
  final String? presetId;
  final String effect;
  final String targetScope;
  final String? targetRef;
  final String title;
  final String? body;
  final Map<String, dynamic> params;
  final bool enabled;

  factory RideRule.fromJson(Map<String, dynamic> json) {
    return RideRule(
      id: json['id'] as String,
      presetId: json['preset_id'] as String?,
      effect: json['effect'] as String? ?? 'badge',
      targetScope: json['target_scope'] as String? ?? 'vehicle',
      targetRef: json['target_ref'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      params: _map(json['params']),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class SeatOccupancy {
  const SeatOccupancy({required this.status, this.holdUntil, this.version = 1});

  final String status;
  final DateTime? holdUntil;
  final int version;

  bool isFreeAt(DateTime now) {
    if (status == 'free') return true;
    if (status == 'held' && holdUntil != null && holdUntil!.isBefore(now)) {
      return true;
    }
    return false;
  }
}

/// Interprets rule records. It does not know preset ids such as women-only.
class SeatRuleEngine {
  const SeatRuleEngine();

  bool appliesTo({
    required RideRule rule,
    required String seatId,
    required String? rowId,
  }) {
    switch (rule.targetScope) {
      case 'vehicle':
        return true;
      case 'row':
        return rule.targetRef != null && rule.targetRef == rowId;
      case 'seat':
        return rule.targetRef != null && rule.targetRef == seatId;
      default:
        return false;
    }
  }

  List<RideRule> acknowledgementsRequired({
    required List<RideRule> rules,
    required String seatId,
    required String? rowId,
  }) {
    return [
      for (final rule in rules)
        if (rule.enabled &&
            rule.effect == 'acknowledge' &&
            appliesTo(rule: rule, seatId: seatId, rowId: rowId))
          rule,
    ];
  }

  /// Rules whose cap is already full for the seats they cover.
  List<RideRule> capBlocksClaim({
    required List<RideRule> rules,
    required SeatLayout layout,
    required String seatId,
    required Map<String, SeatOccupancy> states,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final rowId = layout.rowIdOf(seatId);
    final blocking = <RideRule>[];
    for (final rule in rules) {
      if (!rule.enabled || rule.effect != 'cap_seats') continue;
      if (!appliesTo(rule: rule, seatId: seatId, rowId: rowId)) continue;
      final max = (rule.params['max'] as num?)?.toInt();
      if (max == null) continue;
      final taken = _nonFreeInTarget(
        rule: rule,
        layout: layout,
        states: states,
        now: clock,
      );
      if (taken >= max) blocking.add(rule);
    }
    return blocking;
  }

  /// Most specific enabled hold: seat, then row, then vehicle.
  int? holdMinutes({
    required List<RideRule> rules,
    required String seatId,
    required String? rowId,
  }) {
    RideRule? best;
    var rank = 4;
    for (final rule in rules) {
      if (!rule.enabled || rule.effect != 'hold_minutes') continue;
      if (!appliesTo(rule: rule, seatId: seatId, rowId: rowId)) continue;
      final next = switch (rule.targetScope) {
        'seat' => 1,
        'row' => 2,
        _ => 3,
      };
      if (next < rank) {
        rank = next;
        best = rule;
      }
    }
    return (best?.params['duration_minutes'] as num?)?.toInt();
  }

  /// Extra hold minutes the driver allows for a walking rider. Zero means none.
  int walkExtensionMinutes({
    required List<RideRule> rules,
    required String seatId,
    required String? rowId,
  }) {
    RideRule? best;
    var rank = 4;
    for (final rule in rules) {
      if (!rule.enabled || rule.effect != 'hold_minutes') continue;
      if (!appliesTo(rule: rule, seatId: seatId, rowId: rowId)) continue;
      final next = switch (rule.targetScope) {
        'seat' => 1,
        'row' => 2,
        _ => 3,
      };
      if (next < rank) {
        rank = next;
        best = rule;
      }
    }
    return (best?.params['walk_extension_minutes'] as num?)?.toInt() ?? 0;
  }

  /// Passenger seats covered by one bundle rule.
  List<String> bundleSeatIds({
    required RideRule rule,
    required SeatLayout layout,
  }) {
    if (!rule.enabled || rule.effect != 'bundle') return const [];
    return [
      for (final row in layout.rows)
        for (final seat in row.seats)
          if (seat.isPassenger &&
              appliesTo(rule: rule, seatId: seat.id, rowId: row.id))
            seat.id,
    ];
  }

  int _nonFreeInTarget({
    required RideRule rule,
    required SeatLayout layout,
    required Map<String, SeatOccupancy> states,
    required DateTime now,
  }) {
    var taken = 0;
    for (final row in layout.rows) {
      for (final seat in row.seats) {
        if (!seat.isPassenger) continue;
        final inTarget = switch (rule.targetScope) {
          'vehicle' => true,
          'row' => row.id == rule.targetRef,
          'seat' => seat.id == rule.targetRef,
          _ => false,
        };
        if (!inTarget) continue;
        final state = states[seat.id];
        if (state != null && !state.isFreeAt(now)) taken += 1;
      }
    }
    return taken;
  }
}

bool rulesMatchFilter({
  required List<RideRule> rules,
  required List<String> presetIds,
  String? query,
}) {
  final enabled = rules.where((rule) => rule.enabled);
  if (presetIds.isNotEmpty) {
    final have = enabled
        .map((rule) => rule.presetId)
        .whereType<String>()
        .toSet();
    if (!presetIds.every(have.contains)) return false;
  }
  final text = query?.trim().toLowerCase() ?? '';
  if (text.isEmpty) return true;
  return enabled.any(
    (rule) =>
        rule.title.toLowerCase().contains(text) ||
        (rule.body ?? '').toLowerCase().contains(text),
  );
}

bool seatStateIsStale(DateTime updatedAt, DateTime now) =>
    now.difference(updatedAt) > const Duration(seconds: 60);

bool seatStateIsHidden(DateTime updatedAt, DateTime now) =>
    now.difference(updatedAt) > const Duration(minutes: 5);

int seatDeltaPayloadBytes(Map<String, dynamic> payload) =>
    utf8.encode(jsonEncode(payload)).length;

/// Occupied passenger seats the driver should confirm after a drop.
List<String> ghostSeatIds({
  required SeatLayout layout,
  required Map<String, SeatOccupancy> states,
}) {
  return [
    for (final row in layout.rows)
      for (final seat in row.seats)
        if (seat.isPassenger && states[seat.id]?.status == 'occupied') seat.id,
  ];
}

Map<String, dynamic> _map(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}
