import 'package:along_core/along_core.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// A destination search result from `places-search` (doc 03 §3).
class PlaceResult {
  const PlaceResult({
    required this.kind,
    required this.name,
    required this.area,
    required this.location,
    required this.distanceM,
    this.id,
  });

  final String kind;
  final String? id;
  final String name;
  final String area;
  final GeoPoint location;
  final double distanceM;

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>;
    return PlaceResult(
      kind: json['kind'] as String,
      id: json['id'] as String?,
      name: json['name'] as String,
      area: json['area'] as String,
      location: GeoPoint(
        lat: (loc['lat'] as num).toDouble(),
        lng: (loc['lng'] as num).toDouble(),
      ),
      distanceM: (json['distance_m'] as num).toDouble(),
    );
  }
}

/// Snapped boarding stage from `rpc.snap_stage` (doc 03 §6).
class SnappedStage {
  const SnappedStage({
    required this.stageId,
    required this.name,
    required this.distanceM,
    required this.routeIds,
  });

  final String stageId;
  final String name;
  final double distanceM;
  final List<String> routeIds;

  factory SnappedStage.fromJson(Map<String, dynamic> json) {
    return SnappedStage(
      stageId: json['stage_id'] as String,
      name: json['name'] as String,
      distanceM: (json['distance_m'] as num).toDouble(),
      routeIds: (json['route_ids'] as List<dynamic>).cast<String>(),
    );
  }
}

/// Places search and stage snapping (doc 03 §3, §6).
class PlacesRepository {
  PlacesRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<List<PlaceResult>> searchPlaces({
    required String query,
    required GeoPoint near,
    required String cityId,
    required int limit,
  }) async {
    try {
      final envelope = await _gateway.invokeFunction(
        'places-search',
        body: {
          'q': query,
          'near': {'lat': near.lat, 'lng': near.lng},
          'city_id': cityId,
          'limit': limit,
        },
      );
      final data = envelope['data'] as Map<String, dynamic>? ?? envelope;
      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .cast<Map<String, dynamic>>()
          .map(PlaceResult.fromJson)
          .toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<SnappedStage?> snapStage({
    required GeoPoint location,
    required String cityId,
    required int snapRadiusM,
  }) async {
    try {
      final results = await searchPlaces(
        query: 'st',
        near: location,
        cityId: cityId,
        limit: 8,
      );

      PlaceResult? nearest;
      for (final place in results) {
        if (place.kind != 'park' && place.kind != 'stage') continue;
        if (place.distanceM > snapRadiusM) continue;
        if (nearest == null || place.distanceM < nearest.distanceM) {
          nearest = place;
        }
      }

      if (nearest == null || nearest.id == null) return null;

      return SnappedStage(
        stageId: nearest.id!,
        name: nearest.name,
        distanceM: nearest.distanceM,
        routeIds: const [],
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<GeoPoint?> cityCentroidForId(String cityId) async {
    try {
      final raw = await _gateway.rpc(
        'city_centroid',
        params: {'p_city_id': cityId},
      );
      if (raw is! Map<String, dynamic>) return null;
      final lat = raw['lat'];
      final lng = raw['lng'];
      if (lat is! num || lng is! num) return null;
      return GeoPoint(lat: lat.toDouble(), lng: lng.toDouble());
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<String?> citySlugForId(String cityId) async {
    try {
      final rows = await _gateway.selectRows(
        'cities',
        filters: {'id': cityId},
      );
      if (rows.isEmpty) return null;
      return rows.first['slug'] as String?;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<String?> cityForLocation(GeoPoint location) async {
    try {
      final raw = await _gateway.rpc(
        'city_for_lat_lng',
        params: {
          'p_lat': location.lat,
          'p_lng': location.lng,
        },
      );
      if (raw is Map<String, dynamic>) {
        return raw['city_id'] as String?;
      }
      return null;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
