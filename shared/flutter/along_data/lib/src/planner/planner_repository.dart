import 'package:along_core/along_core.dart';
import 'package:along_data/src/mappers/domain_mappers.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Calls the `plan-trip` Edge function and maps to [PlanResult].
class PlannerRepository {
  PlannerRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<PlanResult> planTrip({
    required Map<String, dynamic> requestBody,
  }) async {
    try {
      final envelope = await _gateway.invokeFunction('plan-trip', body: requestBody);
      final data = envelope['data'] as Map<String, dynamic>? ?? envelope;
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
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  PlanCandidate _mapCandidate(Map<String, dynamic> json) {
    final legsJson = (json['legs'] as List<dynamic>).cast<Map<String, dynamic>>();
    final legs = legsJson.map((leg) {
      final modeCode = (leg['mode'] as Map<String, dynamic>)['code'] as String;
      final mode = TransportMode.tryParse(modeCode) ?? TransportMode.car;
      final fareJson = leg['fare'] as Map<String, dynamic>;
      return PlanCandidateLeg(
        legIndex: (leg['leg_index'] as num).toInt(),
        mode: mode,
        boardName: (leg['board'] as Map)['name'] as String? ?? '',
        alightName: (leg['alight'] as Map)['name'] as String? ?? '',
        inVehicleSeconds: (leg['in_vehicle_s'] as num).toInt(),
        waitSeconds: (leg['wait_s'] as num).toInt(),
        fare: FareQuote.fromJson(fareJson),
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
