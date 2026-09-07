import 'dart:io';

import 'package:along_map/src/cache/tile_cache_manager.dart';

/// Default bounded corridor pre-cache size (doc 07 §4).
const corridorPrecacheDefaultMaxBytes = 5 * 1024 * 1024;

/// Records corridor PMTiles pre-cache requests (doc 07 §4).
///
/// MapLibre owns tile LRU; this service tracks bounded corridor downloads
/// after the first successful plan-trip for a corridor bbox.
class CorridorTilePrecacheService {
  CorridorTilePrecacheService({
    required Directory cacheDirectory,
    TileCacheManager? tileCacheManager,
  }) : _tileCache = tileCacheManager ?? TileCacheManager(cacheDirectory: cacheDirectory);

  final TileCacheManager _tileCache;
  final List<CorridorPrecacheRequest> _requests = [];

  List<CorridorPrecacheRequest> get recordedRequests =>
      List.unmodifiable(_requests);

  /// Queues a bounded corridor download. Does not invent a new map renderer.
  Future<void> precacheCorridor(CorridorPrecacheRequest request) async {
    _requests.add(request);
    if (request.pmtilesUrl == null) return;

    await _tileCache.cacheDirectory.create(recursive: true);
    final fileName = 'corridor_${request.corridorId}.pmtiles';
    final target = File('${_tileCache.cacheDirectory.path}/$fileName');

    // Stub: record intent; production would range-fetch PMTiles bytes.
    if (!await target.exists()) {
      await target.writeAsBytes(const [0x50, 0x4d]); // placeholder header
    }
    await _tileCache.enforceLimit();
  }

  void clearRecordedRequests() => _requests.clear();
}

class CorridorPrecacheRequest {
  const CorridorPrecacheRequest({
    required this.corridorId,
    required this.bbox,
    this.pmtilesUrl,
    this.maxBytes = corridorPrecacheDefaultMaxBytes,
  });

  final String corridorId;
  final CorridorBbox bbox;
  final String? pmtilesUrl;
  final int maxBytes;
}

class CorridorBbox {
  const CorridorBbox({
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
  });

  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;
}
