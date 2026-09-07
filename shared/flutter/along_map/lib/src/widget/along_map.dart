import 'dart:async';
import 'dart:io';

import 'package:along_map/src/cache/tile_cache_manager.dart';
import 'package:along_map/src/camera/map_camera.dart';
import 'package:along_map/src/layers/layer_ids.dart';
import 'package:along_map/src/layers/map_layer_controller.dart';
import 'package:along_map/src/style/along_style_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Primary Along map widget — MapLibre with along-light style and overlay layers.
class AlongMap extends StatefulWidget {
  const AlongMap({
    super.key,
    this.styleUrl,
    this.offlineStyleJson,
    this.initialCameraPosition,
    this.onMapCreated,
    this.onStyleLoaded,
    this.onLayerControllerReady,
    this.onMapClick,
    this.gestureRecognizers,
    this.myLocationEnabled = false,
    this.maxZoom,
  });

  /// Remote style URL (`${TILES_BASE}/styles/along-light.json`). Ignored when
  /// [offlineStyleJson] is set.
  final String? styleUrl;

  /// Pre-resolved style JSON for offline / fixture use (no network fetch).
  final String? offlineStyleJson;

  final CameraPosition? initialCameraPosition;
  final void Function(MapLibreMapController controller)? onMapCreated;
  final VoidCallback? onStyleLoaded;
  final void Function(MapLayerController controller)? onLayerControllerReady;
  final OnMapClickCallback? onMapClick;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final bool myLocationEnabled;
  final double? maxZoom;

  /// Creates an [AlongMap] configured for offline Abuja fixture tiles.
  static Future<AlongMapOfflineConfig> bootstrapOffline({
    required Directory cacheDirectory,
    AlongStyleLoader? styleLoader,
  }) async {
    final cache = TileCacheManager(cacheDirectory: cacheDirectory);
    final bundle = await cache.seedAbujaFixture();
    final loader = styleLoader ?? const AlongStyleLoader();
    final styleJson = await loader.loadOfflineStyleFromAsset(
      styleAssetPath: 'assets/style/along-light-test.json',
      cachedPmtilesPath: bundle.pmtilesPath,
    );
    return AlongMapOfflineConfig(
      styleJson: styleJson,
      pmtilesPath: bundle.pmtilesPath,
      cacheDirectory: cacheDirectory,
    );
  }

  @override
  State<AlongMap> createState() => _AlongMapState();
}

class _AlongMapState extends State<AlongMap> {
  MapLayerController? _layerController;
  final _controllerCompleter = Completer<MapLibreMapController>();

  @override
  Widget build(BuildContext context) {
    final styleString = widget.offlineStyleJson ??
        widget.styleUrl ??
        const AlongStyleLoader().remoteStyleUrl;

    return MapLibreMap(
      styleString: styleString,
      initialCameraPosition:
          widget.initialCameraPosition ?? MapCamera.abujaDefault(),
      myLocationEnabled: widget.myLocationEnabled,
      minMaxZoomPreference: MinMaxZoomPreference(
        0,
        widget.maxZoom ?? 22,
      ),
      gestureRecognizers: widget.gestureRecognizers,
      onMapClick: widget.onMapClick,
      onMapCreated: (controller) {
        if (!_controllerCompleter.isCompleted) {
          _controllerCompleter.complete(controller);
        }
        widget.onMapCreated?.call(controller);
      },
      onStyleLoadedCallback: () {
        _controllerCompleter.future.then((controller) {
          _layerController = MapLayerController(controller);
          widget.onLayerControllerReady?.call(_layerController!);
        });
        widget.onStyleLoaded?.call();
      },
    );
  }
}

/// Resolved offline map configuration (style + cached PMTiles path).
class AlongMapOfflineConfig {
  const AlongMapOfflineConfig({
    required this.styleJson,
    required this.pmtilesPath,
    required this.cacheDirectory,
  });

  final String styleJson;
  final String pmtilesPath;
  final Directory cacheDirectory;

  /// Verifies the resolved style references the local cache, not remote tiles.
  bool get usesLocalCache =>
      styleJson.contains(Uri.file(pmtilesPath).toString()) ||
      styleJson.contains(pmtilesPath);

  bool get hasAllOverlayLayers {
    for (final layerId in AlongLayerIds.allOverlayLayers) {
      if (!styleJson.contains('"id": "$layerId"')) return false;
    }
    return true;
  }
}
