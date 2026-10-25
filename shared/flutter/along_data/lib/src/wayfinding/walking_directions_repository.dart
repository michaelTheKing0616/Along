import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/src/database/along_database.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Fetches and caches OSRM foot directions from the `walking-directions` Edge fn.
class WalkingDirectionsRepository {
  WalkingDirectionsRepository(this._gateway, this._db);

  final AlongSupabase _gateway;
  final AlongDatabase _db;

  Future<WalkingDirections> fetchDirections({
    required GeoPoint from,
    required GeoPoint to,
    required WayfindingMode mode,
    String? cacheTripId,
  }) async {
    try {
      final envelope = await _gateway.invokeFunction(
        'walking-directions',
        body: {
          'from': {'lat': from.lat, 'lng': from.lng},
          'to': {'lat': to.lat, 'lng': to.lng},
          'mode_pref': mode.wireValue,
        },
      );
      final data = envelope['data'] as Map<String, dynamic>? ?? envelope;
      final directions = _mapDirections(data);
      if (cacheTripId != null) {
        await _cacheDirections(cacheTripId, data);
      }
      return directions;
    } catch (e) {
      if (cacheTripId != null) {
        final cached = await cachedDirections(cacheTripId);
        if (cached != null) return cached;
      }
      throw mapSupabaseError(e);
    }
  }

  Future<WalkingDirections?> cachedDirections(String tripId) async {
    final row = await (_db.select(_db.stepsCache)
          ..where((t) => t.tripId.equals(tripId)))
        .getSingleOrNull();
    if (row == null) return null;
    final data = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    return _mapDirections(data);
  }

  Future<void> _cacheDirections(
    String tripId,
    Map<String, dynamic> payload,
  ) async {
    await _db.into(_db.stepsCache).insertOnConflictUpdate(
          StepsCacheCompanion.insert(
            tripId: tripId,
            payloadJson: jsonEncode(payload),
            cachedAt: DateTime.now().toUtc(),
          ),
        );
  }

  WalkingDirections _mapDirections(Map<String, dynamic> data) {
    final stepsJson = (data['steps'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final polylineJson = (data['polyline'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return WalkingDirections(
      distanceM: (data['distance_m'] as num?)?.toInt() ?? 0,
      durationS: (data['duration_s'] as num?)?.toInt() ?? 0,
      steps: stepsJson
          .map(
            (s) => WalkingStep(
              instruction: s['instruction'] as String? ?? '',
              distanceM: (s['distance_m'] as num?)?.toInt() ?? 0,
              maneuver: s['maneuver'] as String?,
              bearing: (s['bearing'] as num?)?.toDouble(),
            ),
          )
          .toList(growable: false),
      polyline: polylineJson
          .map(
            (p) => GeoPoint(
              lat: (p['lat'] as num).toDouble(),
              lng: (p['lng'] as num).toDouble(),
            ),
          )
          .toList(growable: false),
      ttsScript: (data['tts_script'] as List<dynamic>? ?? [])
          .cast<String>()
          .toList(growable: false),
      degraded: data['degraded'] as bool? ?? false,
    );
  }

  /// Maps prefetched `journey_transfer_walks.directions` JSON to domain.
  WalkingDirections fromPrefetchJson(Map<String, dynamic> data) =>
      _mapDirections(data);
}
