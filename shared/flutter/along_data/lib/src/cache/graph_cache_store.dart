import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/src/database/along_database.dart';
import 'package:along_data/src/routes/routes_repository.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Persists compact graph bundles per city (doc 07 §4 `graph_cache`).
class GraphCacheStore {
  GraphCacheStore(this._db, this._gateway, this._routes);

  final AlongDatabase _db;
  final AlongSupabase _gateway;
  final RoutesRepository _routes;

  Future<GraphCacheData?> read(String cityId) async {
    return (_db.select(_db.graphCache)
          ..where((t) => t.cityId.equals(cityId)))
        .getSingleOrNull();
  }

  Future<Map<String, dynamic>?> readPayload(String cityId) async {
    final row = await read(cityId);
    if (row == null) return null;
    return jsonDecode(row.payloadJson) as Map<String, dynamic>;
  }

  Future<void> upsert({
    required String cityId,
    required String graphVersion,
    required Map<String, dynamic> payload,
    DateTime? fetchedAt,
  }) async {
    await _db.into(_db.graphCache).insertOnConflictUpdate(
          GraphCacheCompanion.insert(
            cityId: cityId,
            graphVersion: graphVersion,
            payloadJson: jsonEncode(payload),
            fetchedAt: fetchedAt ?? DateTime.now().toUtc(),
          ),
        );
  }

  /// Refreshes when local [graphVersion] differs from server token.
  Future<Map<String, dynamic>?> refreshIfNeeded({
    required String cityId,
    String? knownGraphVersion,
  }) async {
    try {
      final versionRaw = await _gateway.rpc(
        'city_graph_version',
        params: {'p_city_id': cityId},
      );
      final serverVersion = versionRaw?.toString() ?? '';
      if (serverVersion.isEmpty) return null;

      final cached = await read(cityId);
      if (cached != null && cached.graphVersion == serverVersion) {
        return jsonDecode(cached.payloadJson) as Map<String, dynamic>;
      }
      if (knownGraphVersion != null &&
          cached != null &&
          cached.graphVersion == knownGraphVersion) {
        return jsonDecode(cached.payloadJson) as Map<String, dynamic>;
      }

      final envelope = await _routes.fetchGraphBundle(
        cityId: cityId,
        graphVersion: serverVersion,
      );
      final data = envelope['data'] as Map<String, dynamic>? ?? envelope;
      await upsert(
        cityId: cityId,
        graphVersion: serverVersion,
        payload: data,
      );
      return data;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<GraphCachePlaceHit>> searchByName({
    required String query,
    String? cityId,
    int limit = 8,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return const [];

    final rows = cityId == null
        ? await _db.select(_db.graphCache).get()
        : await (_db.select(_db.graphCache)
              ..where((t) => t.cityId.equals(cityId)))
            .get();

    final hits = <GraphCachePlaceHit>[];
    for (final row in rows) {
      final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      _collectHits(
        payload: payload,
        cityId: row.cityId,
        graphVersion: row.graphVersion,
        cachedAt: row.fetchedAt,
        normalized: normalized,
        hits: hits,
      );
      if (hits.length >= limit) break;
    }

    hits.sort((a, b) => a.name.compareTo(b.name));
    return hits.take(limit).toList(growable: false);
  }

  void _collectHits({
    required Map<String, dynamic> payload,
    required String cityId,
    required String graphVersion,
    required DateTime cachedAt,
    required String normalized,
    required List<GraphCachePlaceHit> hits,
  }) {
    for (final park in (payload['parks'] as List<dynamic>? ?? [])) {
      if (park is! Map<String, dynamic>) continue;
      final name = (park['name'] as String? ?? '').toLowerCase();
      if (!name.contains(normalized)) continue;
      hits.add(
        GraphCachePlaceHit(
          kind: 'park',
          id: park['id'] as String?,
          name: park['name'] as String? ?? '',
          area: 'Cached',
          location: GeoPoint(
            lat: (park['lat'] as num).toDouble(),
            lng: (park['lng'] as num).toDouble(),
          ),
          cityId: cityId,
          graphVersion: graphVersion,
          cachedAt: cachedAt,
        ),
      );
    }

    for (final stage in (payload['stages'] as List<dynamic>? ?? [])) {
      if (stage is! Map<String, dynamic>) continue;
      final name = (stage['name'] as String? ?? '').toLowerCase();
      if (!name.contains(normalized)) continue;
      hits.add(
        GraphCachePlaceHit(
          kind: 'stage',
          id: stage['id'] as String?,
          name: stage['name'] as String? ?? '',
          area: 'Cached',
          location: GeoPoint(
            lat: (stage['lat'] as num).toDouble(),
            lng: (stage['lng'] as num).toDouble(),
          ),
          cityId: cityId,
          graphVersion: graphVersion,
          cachedAt: cachedAt,
        ),
      );
    }
  }
}

class GraphCachePlaceHit {
  const GraphCachePlaceHit({
    required this.kind,
    required this.name,
    required this.area,
    required this.location,
    required this.cityId,
    required this.graphVersion,
    required this.cachedAt,
    this.id,
  });

  final String kind;
  final String? id;
  final String name;
  final String area;
  final GeoPoint location;
  final String cityId;
  final String graphVersion;
  final DateTime cachedAt;
}
