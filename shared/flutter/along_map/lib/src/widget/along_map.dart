import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:along_map/src/cache/tile_cache_manager.dart';
import 'package:along_map/src/camera/map_camera.dart';
import 'package:along_map/src/layers/layer_ids.dart';
import 'package:along_map/src/layers/map_layer_controller.dart';
import 'package:along_map/src/style/along_map_colors.dart';
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
    this.allowDemoStyleFallback = true,
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

  /// When style URL / offline JSON are missing, fall back to MapLibre demotiles
  /// instead of the historical `tiles-staging.along.ng` default (often DNS-dead
  /// → black map). Disable on prod builds that must show a hard empty-state.
  final bool allowDemoStyleFallback;

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
  bool _styleLoaded = false;

  @override
  void didUpdateWidget(covariant AlongMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.styleUrl != widget.styleUrl ||
        oldWidget.offlineStyleJson != widget.offlineStyleJson) {
      _styleLoaded = false;
    }
  }

  String? _resolveStyleString() {
    final offline = widget.offlineStyleJson;
    if (offline != null && offline.isNotEmpty) return offline;
    final remote = widget.styleUrl;
    if (remote != null && remote.isNotEmpty) return remote;
    if (widget.allowDemoStyleFallback) {
      return AlongStyleLoader.demoStyleUrl;
    }
    return null;
  }

  /// Widget tests must not mount a MapLibre platform view.
  /// `bool.fromEnvironment('FLUTTER_TEST')` is not set by current `flutter test`.
  static bool get inFlutterTest {
    if (const bool.fromEnvironment('FLUTTER_TEST')) return true;
    try {
      return Platform.environment['FLUTTER_TEST'] == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (inFlutterTest) {
      return const ColoredBox(color: AlongMapColors.land);
    }

    final styleString = _resolveStyleString();
    if (styleString == null) {
      return const _AlongMapUnavailablePlaceholder();
    }

    final usingDemo = AlongStyleLoader.isDemoStyle(styleString);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Land colour behind MapLibre so a failed/slow style never paints black.
        const ColoredBox(color: AlongMapColors.land),
        MapLibreMap(
          styleString: styleString,
          initialCameraPosition:
              widget.initialCameraPosition ??
              MapCamera.forCenter(lat: 0, lng: 0, zoom: 2),
          myLocationEnabled: widget.myLocationEnabled,
          attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          attributionButtonMargins: const math.Point(8, 96),
          logoViewMargins: const math.Point(8, 96),
          minMaxZoomPreference: MinMaxZoomPreference(0, widget.maxZoom ?? 22),
          gestureRecognizers: widget.gestureRecognizers,
          onMapClick: widget.onMapClick,
          onMapCreated: (controller) {
            if (!_controllerCompleter.isCompleted) {
              _controllerCompleter.complete(controller);
            }
            widget.onMapCreated?.call(controller);
          },
          onStyleLoadedCallback: () {
            if (mounted) {
              setState(() => _styleLoaded = true);
            }
            _controllerCompleter.future.then((controller) {
              _layerController = MapLayerController(controller);
              widget.onLayerControllerReady?.call(_layerController!);
            });
            widget.onStyleLoaded?.call();
          },
        ),
        if (!_styleLoaded)
          const ColoredBox(
            color: AlongMapColors.land,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
        if (usingDemo)
          const Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: _AlongMapDemoBanner(),
          ),
      ],
    );
  }
}

class _AlongMapUnavailablePlaceholder extends StatelessWidget {
  const _AlongMapUnavailablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AlongMapColors.land,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Color(0xFF6B6B6B)),
              SizedBox(height: 12),
              Text(
                'Map unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'TILES_BASE_URL is not configured for this build. '
                'Set it via --dart-define-from-file (env/staging.json) '
                'or env/staging.json TILES_BASE then re-run wire_staging.sh.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlongMapDemoBanner extends StatelessWidget {
  const _AlongMapDemoBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: const Color(0xE6FFF8E1),
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'Demo basemap — set TILES_BASE_URL (or TILES_BASE) to load Along tiles.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
        ),
      ),
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
