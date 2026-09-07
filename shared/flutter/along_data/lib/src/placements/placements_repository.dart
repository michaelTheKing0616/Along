import 'package:along_data/src/placements/placement_models.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// FM39-compliant sponsored placement fetch + aggregate counters (P8-B-01).
class PlacementsRepository {
  PlacementsRepository(this._gateway);

  final AlongSupabase _gateway;

  /// Builds the RPC payload for `resolve_sponsored_placements` — unit-test surface.
  static Map<String, dynamic> buildResolvePlacementsParams(PlacementContext context) {
    final params = <String, dynamic>{
      'p_context_type': context.type.rpcValue,
      'p_target_reference': context.targetReference,
      if (context.deploymentId != null) 'p_deployment_id': context.deploymentId,
    };
    assertNoPersonalIdentifiers(params);
    return params;
  }

  /// Builds the RPC payload for `record_placement_counter`.
  static Map<String, dynamic> buildRecordCounterParams({
    required String placementId,
    required String metric,
  }) {
    final params = <String, dynamic>{
      'p_placement_id': placementId,
      'p_metric': metric,
    };
    assertNoPersonalIdentifiers(params);
    return params;
  }

  static void assertNoPersonalIdentifiers(Map<String, dynamic> params) {
    for (final key in params.keys) {
      final normalized = key.toLowerCase();
      if (placementForbiddenRequestKeys.contains(normalized)) {
        throw ArgumentError('Personal identifier in placement request: $key');
      }
      for (final forbidden in placementForbiddenRequestKeys) {
        if (normalized.contains(forbidden)) {
          throw ArgumentError('Personal identifier in placement request: $key');
        }
      }
    }
  }

  Future<List<SponsoredPlacement>> resolvePlacements(PlacementContext context) async {
    try {
      final raw = await _gateway.rpc(
        'resolve_sponsored_placements',
        params: buildResolvePlacementsParams(context),
      );
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(SponsoredPlacement.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> recordImpression(String placementId) =>
      _recordCounter(placementId, 'impression');

  Future<void> recordTap(String placementId) => _recordCounter(placementId, 'tap');

  Future<void> _recordCounter(String placementId, String metric) async {
    try {
      await _gateway.rpc(
        'record_placement_counter',
        params: buildRecordCounterParams(
          placementId: placementId,
          metric: metric,
        ),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// First corridor for a city — aggregate context for history screens.
  Future<String?> corridorIdForCity(String cityId) async {
    try {
      final rows = await _gateway.selectRows(
        'corridors',
        filters: {'city_id': cityId},
      );
      if (rows.isEmpty) return null;
      return rows.first['id'] as String?;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
