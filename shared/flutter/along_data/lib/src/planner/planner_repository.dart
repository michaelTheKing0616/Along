import 'package:along_core/along_core.dart';
import 'package:along_data/src/cache/plan_cache_key.dart';
import 'package:along_data/src/cache/plan_cache_store.dart';
import 'package:along_data/src/mappers/domain_mappers.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Calls the `plan-trip` Edge function and maps to [PlanResult].
class PlannerRepository {
  PlannerRepository(this._gateway, {PlanCacheStore? planCache})
      : _planCache = planCache;

  final AlongSupabase _gateway;
  final PlanCacheStore? _planCache;

  Future<PlanTripOutcome> planTrip({
    required Map<String, dynamic> requestBody,
    bool allowStaleRead = true,
  }) async {
    final cacheKey = _planCache == null ? null : _cacheKeyForRequest(requestBody);

    try {
      final envelope =
          await _gateway.invokeFunction('plan-trip', body: requestBody);
      final data = envelope['data'] as Map<String, dynamic>? ?? envelope;
      if (cacheKey != null) {
        await _planCache!.write(cacheKey: cacheKey, planTripPayload: data);
      }
      return PlanTripOutcome(
        result: planResultFromData(data),
        fromCache: false,
      );
    } catch (e) {
      if (!allowStaleRead || cacheKey == null || _planCache == null) {
        throw mapSupabaseError(e);
      }
      final cached = await _planCache!.readPayload(cacheKey);
      if (cached == null) throw mapSupabaseError(e);
      final row = await _planCache!.read(cacheKey);
      return PlanTripOutcome(
        result: planResultFromData(cached),
        fromCache: true,
        cachedAt: row?.cachedAt,
      );
    }
  }

  /// Reads a cached plan without hitting the network.
  Future<PlanTripOutcome?> readCachedPlan({
    required Map<String, dynamic> requestBody,
  }) async {
    if (_planCache == null) return null;
    final cacheKey = _cacheKeyForRequest(requestBody);
    if (cacheKey == null) return null;
    final cached = await _planCache!.readPayload(cacheKey);
    if (cached == null) return null;
    final row = await _planCache!.read(cacheKey);
    return PlanTripOutcome(
      result: planResultFromData(cached),
      fromCache: true,
      cachedAt: row?.cachedAt,
    );
  }

  String? _cacheKeyForRequest(Map<String, dynamic> body) {
    final origin = body['origin'];
    final destination = body['destination'];
    if (origin is! Map || destination is! Map) return null;
    final filters = body['filters'];
    return planCacheKey(
      origin: GeoPoint(
        lat: (origin['lat'] as num).toDouble(),
        lng: (origin['lng'] as num).toDouble(),
      ),
      destination: GeoPoint(
        lat: (destination['lat'] as num).toDouble(),
        lng: (destination['lng'] as num).toDouble(),
      ),
      filters: filters is Map<String, dynamic>
          ? filters
          : (filters as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Shared mapper for plan-trip and itinerary prepared_plan payloads.
  PlanResult planResultFromData(Map<String, dynamic> data) {
    final candidatesJson = (data['candidates'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final sortOrdersRaw =
        (data['sort_orders'] as Map<String, dynamic>? ?? {});

    final candidates = candidatesJson.map(_mapCandidate).toList();
    final sortOrders = <SortCriterion, List<String>>{};
    for (final entry in sortOrdersRaw.entries) {
      final criterion = _sortCriterion(entry.key);
      if (criterion != null) {
        sortOrders[criterion] =
            (entry.value as List<dynamic>).cast<String>();
      }
    }

    return PlanResult(
      queryId: data['query_id'] as String? ?? '',
      cityId: data['city_id'] as String? ?? '',
      degraded: data['degraded'] as bool? ?? false,
      candidates: candidates,
      sortOrders: sortOrders,
      coverageGap: _mapCoverageGap(data['coverage_gap']),
    );
  }

  CoverageGap? _mapCoverageGap(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final nearest = raw['nearest_stage'] as Map<String, dynamic>?;
    if (nearest == null) return null;
    final location = nearest['location'] as Map<String, dynamic>;
    return CoverageGap(
      reportId: raw['report_id'] as String? ?? '',
      nearestStage: NearestStage(
        stageId: nearest['stage_id'] as String? ?? '',
        name: nearest['name'] as String? ?? '',
        location: GeoPoint(
          lat: (location['lat'] as num).toDouble(),
          lng: (location['lng'] as num).toDouble(),
        ),
        distanceM: (nearest['distance_m'] as num?)?.toInt() ?? 0,
      ),
      ambientVehicleCount:
          (raw['ambient_vehicle_count'] as num?)?.toInt() ?? 0,
    );
  }

  PlanCandidate _mapCandidate(Map<String, dynamic> json) {
    final legsJson =
        (json['legs'] as List<dynamic>).cast<Map<String, dynamic>>();
    final legs = legsJson.map((leg) {
      final modeCode = (leg['mode'] as Map<String, dynamic>)['code'] as String;
      final mode = TransportMode.tryParse(modeCode) ?? TransportMode.car;
      final fareJson = leg['fare'] as Map<String, dynamic>;
      final board = leg['board'] as Map<String, dynamic>;
      return PlanCandidateLeg(
        legIndex: (leg['leg_index'] as num).toInt(),
        mode: mode,
        boardName: board['name'] as String? ?? '',
        alightName: (leg['alight'] as Map)['name'] as String? ?? '',
        walkMeters: (board['walk_m'] as num?)?.toInt() ?? 0,
        walkSeconds: (board['walk_s'] as num?)?.toInt() ?? 0,
        inVehicleSeconds: (leg['in_vehicle_s'] as num).toInt(),
        waitSeconds: (leg['wait_s'] as num).toInt(),
        fare: FareQuote.fromJson(fareJson),
        loadWarning: _mapLoadWarning(leg['load_warning']),
      );
    }).toList();

    final metrics = json['metrics'] as Map<String, dynamic>? ?? {};
    return PlanCandidate(
      candidateId: json['candidate_id'] as String,
      kind: json['kind'] as String,
      source: json['source'] as String,
      viableDirect: json['viable_direct'] as bool,
      legs: legs,
      totalFareMinorUnits: (metrics['total_fare_minor'] as num?)?.toInt() ??
          legs.fold(0, (sum, l) => sum + l.fare.total.minorUnits),
      totalTimeSeconds: (metrics['total_time_s'] as num?)?.toInt() ?? 0,
      transferCount: (metrics['transfer_count'] as num?)?.toInt() ?? 0,
      metrics: _mapMetrics(metrics),
      transfers: _mapTransfers(json['transfers']),
    );
  }

  PlanMetrics? _mapMetrics(Map<String, dynamic> metrics) {
    if (metrics.isEmpty) return null;
    final explainRaw = metrics['explain'] as Map<String, dynamic>? ?? {};
    return PlanMetrics(
      totalWalkingDistanceM:
          (metrics['total_walking_distance_m'] as num?)?.toInt() ?? 0,
      strenuousnessScore:
          (metrics['strenuousness_score'] as num?)?.toDouble() ?? 0,
      recommendedScore:
          (metrics['recommended_score'] as num?)?.toDouble() ?? 0,
      explain: PlanExplain(
        fare: (explainRaw['fare'] as num?)?.toDouble() ?? 0,
        time: (explainRaw['time'] as num?)?.toDouble() ?? 0,
        strenuous: (explainRaw['strenuous'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  List<PlanTransfer> _mapTransfers(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (t) => PlanTransfer(
            parkName: t['park_name'] as String? ?? '',
            walkMeters: (t['walk_m'] as num?)?.toInt() ?? 0,
            transferSeconds: (t['transfer_s'] as num?)?.toInt() ??
                (t['transfer_time_s'] as num?)?.toInt() ??
                0,
          ),
        )
        .toList(growable: false);
  }

  LoadWarning? _mapLoadWarning(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return LoadWarning(
      reason: raw['reason'] as String? ?? 'mode_capacity',
      modeCapacity: raw['mode_capacity'] as String?,
    );
  }

  SortCriterion? _sortCriterion(String raw) => switch (raw) {
        'recommended' => SortCriterion.recommended,
        'cheapest' => SortCriterion.cheapest,
        'fastest' => SortCriterion.fastest,
        'least_strenuous' => SortCriterion.leastStrenuous,
        _ => null,
      };
}

class PlanTripOutcome {
  const PlanTripOutcome({
    required this.result,
    required this.fromCache,
    this.cachedAt,
  });

  final PlanResult result;
  final bool fromCache;
  final DateTime? cachedAt;
}
