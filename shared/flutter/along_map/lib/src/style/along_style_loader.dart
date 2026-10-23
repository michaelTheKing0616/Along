import 'dart:convert';
import 'dart:io';

import 'package:along_map/src/layers/layer_ids.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads and resolves the along-light MapLibre style for online or offline use.
class AlongStyleLoader {
  const AlongStyleLoader({
    this.tilesBase = 'https://tiles-staging.along.ng',
    this.spriteUrl,
    this.glyphsUrl,
  });

  /// Public MapLibre demotiles style. A full style URL, not a tiles base.
  /// Misleading as a production basemap (world demo, not Nigeria).
  static const demoStyleUrl = 'https://demotiles.maplibre.org/style.json';

  /// Free vector basemap. No API key. Used when Along PMTiles are unset or
  /// the configured host is one of the retired along.ng tile domains.
  static const openFreeMapStyleUrl =
      'https://tiles.openfreemap.org/styles/positron';

  /// Bundled brand styles. Paper for light, dusk for dark. Free OpenFreeMap
  /// tiles, Along colours. Used when no private tile host is configured.
  static const brandPaperAsset =
      'packages/along_design/assets/map/along-paper.json';
  static const brandDuskAsset =
      'packages/along_design/assets/map/along-dusk.json';

  /// Hosts that were written into env files before a tile CDN existed.
  static const unreachableTileHosts = <String>{
    'tiles.along.ng',
    'tiles.dev.along.ng',
    'tiles-staging.along.ng',
  };

  /// True when [tilesBase] is an http(s) origin we can request a style from.
  static bool isReachableTilesBase(String? tilesBase) {
    final trimmed = tilesBase?.trim() ?? '';
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return false;
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    if (uri.host.contains('placeholder')) return false;
    return !unreachableTileHosts.contains(uri.host);
  }

  /// Along style when a real tiles base is configured, otherwise OpenFreeMap.
  static String resolveBasemapStyleUrl({String? tilesBase, String? citySlug}) {
    final trimmed = tilesBase?.trim() ?? '';
    if (!isReachableTilesBase(trimmed)) return openFreeMapStyleUrl;
    return AlongStyleLoader(tilesBase: trimmed)
        .remoteStyleUrl(citySlug: citySlug);
  }

  final String tilesBase;
  final String? spriteUrl;
  final String? glyphsUrl;

  /// Default remote style URL (doc 07 §7).
  ///
  /// [TILES_BASE] is deployment-wide; [citySlug] scopes CDN cache keys and style
  /// query so per-city PMTiles archives do not collide in the tile cache.
  String remoteStyleUrl({String? citySlug}) {
    final base = '$tilesBase/styles/along-light.json';
    if (citySlug == null || citySlug.isEmpty) return base;
    return '$base?city=$citySlug';
  }

  /// True when [styleString] is the demotiles fallback (not Along CDN).
  static bool isDemoStyle(String? styleString) => styleString == demoStyleUrl;

  /// Resolves placeholders in a style JSON string for the given PMTiles location.
  ///
  /// [pmtilesLocation] may be an `https://` CDN URL or a local `file://` path
  /// pointing at a cached PMTiles archive (offline fixture / corridor pre-cache).
  String resolveStyleJson(
    String rawStyleJson, {
    required String pmtilesLocation,
  }) {
    final sprite = spriteUrl ?? '$tilesBase/sprites/along-light';
    final glyphs = glyphsUrl ?? '$tilesBase/glyphs/{fontstack}/{range}.pbf';
    final pmtilesRef = pmtilesLocation.startsWith('pmtiles://')
        ? pmtilesLocation
        : 'pmtiles://$pmtilesLocation';

    return rawStyleJson
        .replaceAll('{{PMTILES_URL}}', pmtilesLocation)
        .replaceAll('{{SPRITE_URL}}', sprite)
        .replaceAll('{{GLYPHS_URL}}', glyphs)
        .replaceAll(
          '"url": "pmtiles://{{PMTILES_URL}}"',
          '"url": "$pmtilesRef"',
        );
  }

  /// Parses style JSON and verifies all along overlay sources/layers are present.
  Map<String, dynamic> parseAndValidate(String styleJson) {
    final decoded = jsonDecode(styleJson) as Map<String, dynamic>;
    final sources = decoded['sources'] as Map<String, dynamic>? ?? {};
    final layers = decoded['layers'] as List<dynamic>? ?? [];
    final layerIds = {
      for (final layer in layers)
        if (layer is Map<String, dynamic> && layer['id'] is String)
          layer['id'] as String,
    };

    for (final sourceId in AlongLayerIds.allOverlaySources) {
      if (!sources.containsKey(sourceId)) {
        throw AlongStyleException('Missing overlay source: $sourceId');
      }
      final source = sources[sourceId] as Map<String, dynamic>;
      if (source['type'] != 'geojson') {
        throw AlongStyleException(
          'Source $sourceId must be geojson, got ${source['type']}',
        );
      }
    }

    for (final layerId in AlongLayerIds.allOverlayLayers) {
      if (!layerIds.contains(layerId)) {
        throw AlongStyleException('Missing overlay layer: $layerId');
      }
    }

    return decoded;
  }

  /// Loads bundled test style and resolves it against a local cached PMTiles path.
  Future<String> loadOfflineStyleFromAsset({
    required String styleAssetPath,
    required String cachedPmtilesPath,
  }) async {
    final raw = await rootBundle.loadString(styleAssetPath);
    final resolved = resolveStyleJson(
      raw,
      pmtilesLocation: _toFileUri(cachedPmtilesPath),
    );
    parseAndValidate(resolved);
    return resolved;
  }

  /// Loads style from a file on disk (e.g. copied into tile cache directory).
  Future<String> loadOfflineStyleFromFile({
    required String styleFilePath,
    required String cachedPmtilesPath,
  }) async {
    final raw = await File(styleFilePath).readAsString();
    final resolved = resolveStyleJson(
      raw,
      pmtilesLocation: _toFileUri(cachedPmtilesPath),
    );
    parseAndValidate(resolved);
    return resolved;
  }

  static String _toFileUri(String path) {
    if (path.startsWith('file://')) return path;
    return Uri.file(path).toString();
  }
}

class AlongStyleException implements Exception {
  AlongStyleException(this.message);
  final String message;

  @override
  String toString() => 'AlongStyleException: $message';
}
