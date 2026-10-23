import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../craft.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import 'delights.dart';
import 'demo_adapter.dart';
import 'driver_portrait.dart';
import 'vehicle_art.dart';

/// How the Abuja map is dressed.
enum AlongCityMapMode {
  browse,
  trip,
  online,
  routeHero,
  search,
  completed,
  nav,
}

/// How sure the fix is. Approximate and stale are hollow and grey, and
/// they carry a word. Precise is a filled rider dot plus "You".
enum AlongFix { precise, approximate, stale, hidden }

/// Muted Abuja maps.
///
/// Tiles are pre-rendered at 3× from the vector styles in
/// `tool/map/style-light.json` and `style-dark.json` (land `#E6E7EA` /
/// `#16171A`, parks `#E4EEE4` / `#1A2620`, water `#D4E2EE` / `#1A2A36`,
/// white or `#C9CCD2` roads). They are drawn as baked, with no color matrix.
/// The daily planet stops at z15; neighborhood frames are the z16 slippy
/// grid, drawn by overzooming that z15 vector so building footprints stay
/// sharp. Nav locks zoom 17, rotated so the street runs up the screen, with
/// footprints and side streets beside a 6dp ink route. The corridor uses
/// native zoom-12 tiles. Online demand is a lattice of small hex outlines.
/// Stroke alpha steps with demand. Only the three hottest cells are filled
/// yellow.
class AlongCityMap extends StatelessWidget {
  const AlongCityMap({
    super.key,
    this.mode = AlongCityMapMode.browse,
    this.progress = 1,
    this.liveMarker = false,
    this.sheetInset = 0.46,
    this.bare = false,
    this.fix = AlongFix.precise,
    this.demoLabel = true,
    this.controller,
    this.center,
    this.zoom,
    this.nearby = false,
    this.approach = false,
    this.place = false,
  });

  final AlongCityMapMode mode;
  final double progress;

  /// Drops a rider dot on the corridor. Guardian and Safety use this.
  final bool liveMarker;

  /// Fraction of the map kept clear under a sheet, so a route can sit above it.
  final double sheetInset;

  /// Tiles only, plus the fix marker. Pickup and search use this so the
  /// decorative pins do not cover the place label.
  final bool bare;

  final AlongFix fix;

  /// Debug builds label simulated positions. Screens that already show a
  /// Demo mark pass false.
  final bool demoLabel;

  /// When set, the screen owns the camera. Pickup pans this under a fixed pin.
  final MapController? controller;

  /// Replaces the mode's default center. The value is the first camera only.
  final LatLng? center;

  /// Locks min, max, and the initial zoom. Nav ignores this and stays at 18.
  final double? zoom;

  /// Pulsing pickup plus nearby drivers. Matching and recovery use this so
  /// the bare map is not an empty street.
  final bool nearby;

  /// A short drive toward a pickup. The rider PIN map uses this.
  final bool approach;

  /// Building footprints, street names, and a walk to the pin. Pickup uses
  /// this. The screen pin stays fixed; these layers move with the map.
  final bool place;

  /// Lane zoom, inside 17–18. z16 tiles overzoom. Negative rotation puts
  /// east at the top: a positive bearing rotates the map clockwise, which
  /// would point the street down the screen.
  static const navZoom = 17.0;
  static const navRotation = -90.0;

  /// Sits about one tile south of Wuse Market, so the market stays in the
  /// strip above a full-screen sheet on both 360×800 and 320×640.
  static const neighborhoodCenter = LatLng(9.063022, 7.465938);
  static const corridorCenter = LatLng(9.0460, 7.5183);

  /// A neighborhood street inside the z16 extract, clear of the tile edge
  /// so a short map at zoom 16 can keep a one-tile buffer.
  static const approachCenter = LatLng(9.06185, 7.46690);
  static const approachZoom = 16.0;
  static const approachRoute = <LatLng>[
    LatLng(9.06017, 7.46588),
    LatLng(9.06068, 7.46616),
    LatLng(9.06119, 7.46647),
    LatLng(9.06170, 7.46678),
    LatLng(9.06221, 7.46683),
    LatLng(9.06271, 7.46715),
    LatLng(9.06322, 7.46748),
    LatLng(9.06339, 7.46759),
  ];

  /// South of the busy cores so the GO button sits on quiet map.
  static const cityCenter = LatLng(9.012, 7.490);
  static const wuseMarket = LatLng(9.068555, 7.465938);
  static const nyanya = LatLng(9.023418, 7.570635);

  /// The white east-west road on tile 16_34126_31112. The line sits on the
  /// road pixels (lat 9.05826), and the span is the continuous white run.
  static const neighborhoodRoute = <LatLng>[
    LatLng(9.05826, 7.45980),
    LatLng(9.05826, 7.46090),
    LatLng(9.05826, 7.46200),
    LatLng(9.05826, 7.46310),
    LatLng(9.05826, 7.46420),
    LatLng(9.05826, 7.46515),
  ];

  /// Wuse Market to Nyanya, snapped to the white roads on the z12 tiles.
  /// The line bends with the highway instead of a single straight street.
  static const corridorRoute = <LatLng>[
    LatLng(9.068704, 7.465725),
    LatLng(9.051074, 7.461262),
    LatLng(9.048022, 7.463322),
    LatLng(9.045649, 7.478771),
    LatLng(9.048700, 7.483921),
    LatLng(9.051074, 7.505894),
    LatLng(9.041580, 7.522373),
    LatLng(9.040224, 7.538853),
    LatLng(9.042258, 7.544346),
    LatLng(9.034121, 7.558422),
    LatLng(9.036494, 7.570438),
    LatLng(9.026661, 7.575932),
  ];

  bool get _wide =>
      mode == AlongCityMapMode.routeHero ||
      mode == AlongCityMapMode.trip ||
      mode == AlongCityMapMode.completed;

  bool get _nav => mode == AlongCityMapMode.nav;

  /// Car on the street. East is up, so the camera sits ahead of the car and
  /// the car rests above the speed bar.
  LatLng _navFocus(double progress) {
    final at = _along(neighborhoodRoute, progress);
    // Zoom 17 packs half as many pixels per degree as 18, so the eastward
    // shift is larger and the car still sits above the speed bar.
    return LatLng(at.point.latitude, at.point.longitude + 0.00128);
  }

  @override
  Widget build(BuildContext context) {
    return _HeldProgress(
      progress: progress,
      builder: (context, shown) => _frame(context, shown),
    );
  }

  Widget _frame(BuildContext context, double shown) {
    final palette = AlongPalette.of(context);
    final dark = palette.brightness == Brightness.dark;
    final drawn = AlongMotionPolicy.reduced(context)
        ? 1.0
        : shown.clamp(0.0, 1.0);
    final route = _nav
        ? neighborhoodRoute
        : _wide
        ? corridorRoute
        : neighborhoodRoute;
    final showRoute =
        mode == AlongCityMapMode.trip ||
        mode == AlongCityMapMode.routeHero ||
        mode == AlongCityMapMode.completed ||
        _nav;
    return LayoutBuilder(
      builder: (context, constraints) {
        final trip = mode == AlongCityMapMode.trip;
        final completed = mode == AlongCityMapMode.completed;
        final city = mode == AlongCityMapMode.online;
        final locked = zoom;
        // Nav stays on the z16 extract. Fitting the corridor would drop to z12.
        // A locked zoom is a header or a pickup camera. Fitting the corridor
        // would pull in tiles outside the extract.
        final fit = showRoute && !_nav && locked == null
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(route),
                padding: trip
                    ? EdgeInsets.fromLTRB(
                        28,
                        72,
                        28,
                        constraints.maxHeight * sheetInset + 36,
                      )
                    : completed
                    ? const EdgeInsets.fromLTRB(32, 28, 40, 64)
                    : const EdgeInsets.fromLTRB(36, 36, 36, 36),
                // z12 tiles scale down when the corridor needs a wider frame.
                minZoom: trip || completed ? 10 : 12,
                maxZoom: trip || completed ? 12 : 12.4,
              )
            : null;
        final initialZoom = _nav
            ? navZoom
            : locked ?? (city ? 11.15 : (_wide ? 12.0 : 16.0));
        return FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter:
                center ??
                (city
                    ? cityCenter
                    : _nav
                    ? _navFocus(shown)
                    : _wide
                    ? corridorCenter
                    : neighborhoodCenter),
            initialZoom: initialZoom,
            initialRotation: _nav ? navRotation : 0,
            initialCameraFit: fit,
            minZoom: _nav
                ? navZoom
                : locked ??
                      (city
                          ? 11.15
                          : _wide
                          ? (trip || completed ? 10 : 12)
                          : 16),
            maxZoom: _nav
                ? navZoom
                : locked ??
                      (city
                          ? 11.15
                          : _wide
                          ? (trip || completed ? 12 : 12.4)
                          : 16),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
            backgroundColor: dark
                ? const Color(0xFF16171A)
                : const Color(0xFFE6E7EA),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'assets/map/tiles/${dark ? 'dark' : 'light'}/{z}_{x}_{y}.png',
              tileProvider: AssetTileProvider(),
              userAgentPackageName: 'app.along.design',
              tileDisplay: const TileDisplay.instantaneous(),
              retinaMode: false,
              minNativeZoom: 12,
              maxNativeZoom: 16,
              // Zoom 17 sits on the edge of the extract. An extra tile ring
              // asks for files that were never baked.
              keepBuffer: initialZoom >= 17 ? 0 : 1,
              panBuffer: 0,
            ),
            if (mode == AlongCityMapMode.online) ...[
              PolygonLayer(polygons: _demandOutlines(palette)),
              Positioned.fill(
                child: _DemandBreath(
                  rings: _demandHotRings(),
                  palette: palette,
                ),
              ),
            ],
            if (_nav) ...[
              PolygonLayer(polygons: _navBlocks(palette)),
              PolylineLayer(polylines: _navStreets(palette)),
            ],
            if (place) ...[
              PolygonLayer(polygons: _placeBlocks(palette)),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _pickupWalk,
                    strokeWidth: 4,
                    color: palette.ink,
                    strokeCap: StrokeCap.round,
                    pattern: StrokePattern.dashed(segments: [8, 6]),
                  ),
                ],
              ),
            ],
            if (approach)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: approachRoute,
                    strokeWidth: 5,
                    color: palette.ink.withValues(alpha: 0.88),
                    strokeCap: StrokeCap.round,
                  ),
                ],
              ),
            if (showRoute)
              Positioned.fill(
                child: _RouteOverlay(
                  route: route,
                  progress: drawn,
                  palette: palette,
                  lane: _nav,
                ),
              ),
            MarkerLayer(
              rotate: true,
              markers: _markers(context, palette, drawn),
            ),
            if (kDebugMode && demoLabel && !_positionCarriesDemo)
              const Positioned(top: 8, right: 8, child: AlongDemoMark()),
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(child: _Attribution(palette: palette)),
            ),
            const Positioned.fill(child: AlongVignette()),
          ],
        );
      },
    );
  }

  /// A puck or a stale car already says Demo, so the corner chip stays off.
  bool get _positionCarriesDemo {
    if (bare) return fix != AlongFix.hidden;
    return mode == AlongCityMapMode.browse ||
        mode == AlongCityMapMode.online ||
        mode == AlongCityMapMode.search ||
        (mode == AlongCityMapMode.trip && fix == AlongFix.stale);
  }

  double _typeScale(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (scale < 1) return 1;
    if (scale > 2.5) return 2.5;
    return scale;
  }

  List<Marker> _markers(
    BuildContext context,
    AlongPalette palette,
    double drawn,
  ) {
    final markers = <Marker>[];
    if (bare) {
      if (approach) {
        final at = _along(approachRoute, drawn);
        markers.add(
          _vehicle(
            context,
            at.point,
            AlongVehicleKind.car,
            null,
            at.heading,
            palette,
            emphasized: true,
          ),
        );
        markers.add(_approachStop(approachRoute.last, palette));
        return markers;
      }
      if (place) {
        markers.add(_walker(_pickupWalk.first, palette));
        markers.add(
          _street(const LatLng(9.07842, 7.46279), 'Sani Abacha Way', palette),
        );
        markers.add(
          _street(const LatLng(9.07455, 7.46455), 'Wuse Market Rd', palette),
        );
        return markers;
      }
      if (nearby) {
        final pickup = center ?? wuseMarket;
        markers.add(_radar(pickup, palette));
        markers.add(
          _driver(
            context,
            const LatLng(9.06755, 7.46715),
            '4 min',
            false,
            palette,
          ),
        );
        markers.add(
          _driver(
            context,
            const LatLng(9.06715, 7.46455),
            '6 min',
            true,
            palette,
          ),
        );
        markers.add(
          _driver(
            context,
            const LatLng(9.06905, 7.46490),
            '8 min',
            false,
            palette,
          ),
        );
      }
      if (fix != AlongFix.hidden) {
        markers.add(_puck(context, center ?? wuseMarket, palette));
      }
      return markers;
    }
    if (mode == AlongCityMapMode.routeHero ||
        mode == AlongCityMapMode.completed) {
      markers.add(_endpoint(context, wuseMarket, 'Wuse', true, palette));
      markers.add(_endpoint(context, nyanya, 'Nyanya', false, palette));
      if (liveMarker) {
        markers.add(
          _riderDot(context, _along(corridorRoute, 0.62).point, palette),
        );
      }
      return markers;
    }
    if (mode == AlongCityMapMode.nav) {
      final at = _along(neighborhoodRoute, drawn);
      // The marker stays upright, so heading 0 points the nose up the street.
      markers.add(
        _vehicle(
          context,
          at.point,
          AlongVehicleKind.car,
          null,
          0,
          palette,
          emphasized: true,
        ),
      );
      return markers;
    }
    if (mode == AlongCityMapMode.trip) {
      markers.add(
        _endpoint(context, corridorRoute.first, 'Wuse', true, palette),
      );
      markers.add(
        _endpoint(context, corridorRoute.last, 'Nyanya', false, palette),
      );
      // A quote is the route before a car exists.
      if (drawn > 0.02) {
        final at = _along(corridorRoute, drawn);
        markers.add(
          _vehicle(
            context,
            at.point,
            AlongVehicleKind.car,
            null,
            at.heading,
            palette,
            emphasized: true,
          ),
        );
      }
      return markers;
    }
    if (mode == AlongCityMapMode.browse) {
      markers.add(_pin(context, wuseMarket, 'Wuse', false, palette));
      markers.add(
        _pin(context, const LatLng(9.06905, 7.46485), 'Park', true, palette),
      );
    }
    if (mode == AlongCityMapMode.search) {
      markers.add(_radar(wuseMarket, palette));
      markers.add(
        _driver(
          context,
          const LatLng(9.06902, 7.46662),
          '4 min',
          false,
          palette,
        ),
      );
      markers.add(
        _driver(
          context,
          const LatLng(9.06805, 7.46515),
          '6 min',
          true,
          palette,
        ),
      );
      markers.add(
        _driver(
          context,
          const LatLng(9.06928, 7.46470),
          '8 min',
          false,
          palette,
        ),
      );
    }
    if (mode == AlongCityMapMode.online) {
      markers.add(
        _vehicle(
          context,
          const LatLng(9.06842, 7.46505),
          AlongVehicleKind.keke,
          2,
          -0.4,
          palette,
        ),
      );
      markers.add(
        _vehicle(
          context,
          const LatLng(9.06878, 7.46670),
          AlongVehicleKind.danfo,
          6,
          0.8,
          palette,
        ),
      );
    } else if (mode == AlongCityMapMode.browse) {
      markers.add(
        _cluster(context, const LatLng(9.06848, 7.46515), 3, palette),
      );
      markers.add(
        _cluster(context, const LatLng(9.06922, 7.46585), 2, palette),
      );
    }
    if (mode == AlongCityMapMode.browse ||
        mode == AlongCityMapMode.online ||
        mode == AlongCityMapMode.search) {
      markers.add(_puck(context, const LatLng(9.06812, 7.46525), palette));
    }
    return markers;
  }

  Marker _approachStop(LatLng at, AlongPalette palette) {
    return Marker(
      point: at,
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.accent,
          shape: BoxShape.circle,
          border: Border.all(color: palette.surface, width: 2),
        ),
      ),
    );
  }

  Marker _walker(LatLng at, AlongPalette palette) {
    return Marker(
      point: at,
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.ink,
          shape: BoxShape.circle,
          border: Border.all(color: palette.surface, width: 2),
        ),
      ),
    );
  }

  Marker _street(LatLng at, String name, AlongPalette palette) {
    final dark = palette.brightness == Brightness.dark;
    return Marker(
      point: at,
      width: 148,
      height: 16,
      child: Text(
        name,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: AlongType.caption(palette).copyWith(
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w600,
          color: dark ? const Color(0xFFE7E2D8) : const Color(0xFF3A342C),
          shadows: [
            Shadow(color: palette.mapLand, blurRadius: 2),
            Shadow(color: palette.mapLand, offset: const Offset(0, 1)),
          ],
        ),
      ),
    );
  }

  Marker _endpoint(
    BuildContext context,
    LatLng at,
    String label,
    bool pickup,
    AlongPalette palette,
  ) {
    final roles = palette.roles;
    final color = pickup ? roles.pickup : roles.dropoff;
    final word = pickup ? 'Pickup' : 'Drop';
    final s = _typeScale(context);
    return Marker(
      point: at,
      width: 96 * s,
      height: 48 * s,
      alignment: Alignment.bottomCenter,
      child: AlongPinDrop(
        child: Semantics(
          label: '$word $label',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pickup ? AlongIcons.locate : AlongIcons.path,
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.caption(palette).copyWith(
                          fontSize: 10,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: pickup ? 12 : 10,
                height: pickup ? 12 : 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: pickup ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: pickup ? null : BorderRadius.circular(2),
                  border: Border.all(color: palette.surface, width: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Marker _pin(
    BuildContext context,
    LatLng at,
    String label,
    bool park,
    AlongPalette palette,
  ) {
    final s = _typeScale(context);
    return Marker(
      point: at,
      width: 72 * s,
      height: 42 * s,
      alignment: Alignment.bottomCenter,
      child: AlongPinDrop(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: park ? palette.mapPark : palette.surface,
                shape: BoxShape.circle,
                border: Border.all(color: palette.ink, width: 2),
                boxShadow: AlongElevation.float(palette.ink),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette).copyWith(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _vehicle(
    BuildContext context,
    LatLng at,
    AlongVehicleKind kind,
    int? seats,
    double heading,
    AlongPalette palette, {
    bool emphasized = false,
  }) {
    final s = _typeScale(context);
    final stale = emphasized && fix == AlongFix.stale;
    final plate = (emphasized ? 58.0 : 52.0) * s;
    final width = stale ? math.max(plate, 156 * s) : plate;
    final height = stale ? plate + 44 * s : plate;
    return Marker(
      point: at,
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: plate,
            height: plate,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 8,
                  child: Container(
                    width: emphasized ? 28 : 22,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (emphasized)
                  Container(
                    width: plate,
                    height: plate,
                    decoration: BoxDecoration(
                      color: stale
                          ? palette.roles.stale.withValues(alpha: 0.18)
                          : palette.surface,
                      shape: BoxShape.circle,
                      border: stale
                          ? Border.all(color: palette.roles.stale, width: 2)
                          : null,
                      boxShadow: AlongElevation.float(palette.ink),
                    ),
                  ),
                AlongTopDownMark(
                  kind: kind,
                  heading: heading,
                  size: (emphasized ? 40 : 36) * (s > 1.15 ? s : 1),
                ),
                if (seats != null)
                  Positioned(
                    right: 0,
                    top: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.accentInk, width: 1),
                      ),
                      child: Text(
                        '$seats',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.numeric(palette).copyWith(
                          fontSize: 11,
                          height: 1,
                          color: palette.accentInk,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (stale)
            _FixCaption(
              palette: palette,
              label: DemoAdapter.gps.ageLabel,
              demo: kDebugMode && demoLabel,
            ),
        ],
      ),
    );
  }

  Marker _riderDot(BuildContext context, LatLng at, AlongPalette palette) {
    final s = _typeScale(context);
    return Marker(
      point: at,
      width: 48 * s,
      height: 40 * s,
      alignment: Alignment.bottomCenter,
      child: Semantics(
        label: 'You',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'You',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette).copyWith(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: palette.roles.riderDot,
                shape: BoxShape.circle,
                border: Border.all(color: palette.surface, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _radar(LatLng at, AlongPalette palette) {
    return Marker(
      point: at,
      width: 96,
      height: 96,
      alignment: Alignment.center,
      child: _PulseRadar(palette: palette),
    );
  }

  Marker _driver(
    BuildContext context,
    LatLng at,
    String eta,
    bool rider,
    AlongPalette palette,
  ) {
    final s = _typeScale(context);
    return Marker(
      point: at,
      width: 74 * s,
      height: 58 * s,
      alignment: Alignment.bottomCenter,
      child: Column(
        children: [
          AlongDriverPortrait(
            size: 36,
            asset: rider
                ? AlongDriverPortrait.adaeze
                : AlongDriverPortrait.chinedu,
            verified: true,
          ),
          const SizedBox(height: 2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: AlongElevation.float(palette.ink),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              child: Text(
                eta,
                maxLines: 1,
                softWrap: false,
                style: AlongType.caption(palette).copyWith(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _cluster(
    BuildContext context,
    LatLng at,
    int count,
    AlongPalette palette,
  ) {
    final s = _typeScale(context);
    return Marker(
      point: at,
      width: 36 * s,
      height: 36 * s,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
          border: Border.all(color: palette.ink, width: 1.5),
          boxShadow: AlongElevation.rest(palette.ink),
        ),
        child: Text(
          '$count',
          maxLines: 1,
          softWrap: false,
          style: AlongType.title(palette).copyWith(fontSize: 15, height: 1),
        ),
      ),
    );
  }

  Marker _puck(BuildContext context, LatLng at, AlongPalette palette) {
    final scale = _typeScale(context);
    final hollow = fix == AlongFix.approximate || fix == AlongFix.stale;
    final showDemo = kDebugMode && demoLabel;
    final word = switch (fix) {
      AlongFix.precise => 'You',
      AlongFix.approximate => 'Approx',
      AlongFix.stale => 'Stale',
      AlongFix.hidden => '',
    };
    final fill = hollow ? palette.roles.stale : palette.roles.riderDot;
    final caption = [
      if (showDemo) 'Demo',
      word,
      if (hollow) DemoAdapter.gps.ageLabel,
    ].join(' ');
    return Marker(
      point: at,
      width: (hollow ? 156 : 72) * scale,
      height: ((showDemo ? 16 : 0) + 16 + (hollow ? 16 : 0) + 20) * scale,
      alignment: Alignment.bottomCenter,
      child: Semantics(
        label: caption,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDemo) _SolidWord(palette: palette, text: 'Demo'),
            _SolidWord(palette: palette, text: word),
            if (hollow)
              _SolidWord(palette: palette, text: DemoAdapter.gps.ageLabel),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: hollow ? const Color(0x00000000) : fill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: hollow ? palette.roles.stale : palette.surface,
                  width: hollow ? 2 : 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolidWord extends StatelessWidget {
  const _SolidWord({required this.palette, required this.text});

  final AlongPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(
            fontSize: 10,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
      ),
    );
  }
}

class _FixCaption extends StatelessWidget {
  const _FixCaption({
    required this.palette,
    required this.label,
    required this.demo,
  });

  final AlongPalette palette;
  final String label;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: demo ? 'Demo $label' : label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (demo) _SolidWord(palette: palette, text: 'Demo'),
          _SolidWord(palette: palette, text: label),
        ],
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.palette});

  final AlongPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '© OpenStreetMap',
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(
            fontSize: 10,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
      ),
    );
  }
}

class _PulseRadar extends StatefulWidget {
  const _PulseRadar({required this.palette});

  final AlongPalette palette;

  @override
  State<_PulseRadar> createState() => _PulseRadarState();
}

class _PulseRadarState extends State<_PulseRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulse.value = 0.42;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return CustomPaint(
          painter: _PulsePainter(
            t: _pulse.value,
            color: widget.palette.accent,
            ink: widget.palette.ink,
          ),
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.t, required this.color, required this.ink});

  final double t;
  final Color color;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 - 2;
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = 18 + phase * (maxR - 18);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: (1 - phase) * 0.55),
      );
    }
    canvas.drawCircle(
      center,
      16,
      Paint()..color = color.withValues(alpha: 0.22),
    );
    canvas.drawCircle(center, 7, Paint()..color = ink);
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) => oldDelegate.t != t;
}

class _HeldProgress extends StatefulWidget {
  const _HeldProgress({required this.progress, required this.builder});

  final double progress;
  final Widget Function(BuildContext context, double shown) builder;

  @override
  State<_HeldProgress> createState() => _HeldProgressState();
}

class _HeldProgressState extends State<_HeldProgress>
    with SingleTickerProviderStateMixin {
  late double _shown;
  late final AnimationController _move;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _shown = widget.progress;
    _move =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addListener(() {
          final t = Curves.easeInOut.transform(_move.value);
          setState(() => _shown = _from + (widget.progress - _from) * t);
        });
  }

  @override
  void didUpdateWidget(covariant _HeldProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress == widget.progress) return;
    if (!AlongMotionPolicy.play(context)) {
      _move.stop();
      setState(() => _shown = widget.progress);
      return;
    }
    _from = _shown;
    _move.forward(from: 0);
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _shown);
}

class _RoutePoint {
  const _RoutePoint(this.point, this.heading);

  final LatLng point;
  final double heading;
}

_RoutePoint _along(List<LatLng> route, double progress) {
  if (route.length < 2) {
    return _RoutePoint(route.first, 0);
  }
  final last = route.length - 1;
  final scaled = progress.clamp(0.0, 1.0) * last;
  final index = scaled.floor().clamp(0, last - 1);
  final t = scaled - index;
  final a = route[index];
  final b = route[index + 1];
  final point = LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );
  final heading = math.atan2(
    b.longitude - a.longitude,
    b.latitude - a.latitude,
  );
  return _RoutePoint(point, heading);
}

/// Sidewalk from a nearby corner to Gate 2. The screen pin sits on the end.
const _pickupWalk = <LatLng>[
  LatLng(9.07570, 7.46255),
  LatLng(9.07588, 7.46295),
  LatLng(9.07610, 7.46340),
];

/// Footprints on the land around Gate 2. Each pair is north-west then
/// south-east, kept off the white roads in the z16 extract.
const _placeRects = <(double, double, double, double)>[
  (9.07974, 7.46209, 9.07955, 7.46236),
  (9.07924, 7.46377, 9.07906, 7.46404),
  (9.07875, 7.46153, 9.07856, 7.46181),
  (9.07825, 7.46432, 9.07807, 7.46460),
  (9.07776, 7.46209, 9.07758, 7.46236),
  (9.07726, 7.46377, 9.07708, 7.46404),
  (9.07677, 7.46488, 9.07659, 7.46515),
  (9.07628, 7.46153, 9.07609, 7.46181),
  (9.07578, 7.46432, 9.07560, 7.46460),
  (9.07529, 7.46153, 9.07510, 7.46181),
  (9.07481, 7.46321, 9.07462, 7.46348),
  (9.07431, 7.46488, 9.07413, 7.46515),
  (9.07382, 7.46377, 9.07363, 7.46404),
  (9.07332, 7.46153, 9.07314, 7.46181),
  (9.07283, 7.46432, 9.07265, 7.46460),
  (9.07233, 7.46209, 9.07215, 7.46236),
];

List<Polygon> _placeBlocks(AlongPalette palette) {
  final dark = palette.brightness == Brightness.dark;
  final fill = dark ? const Color(0xFF2C2A26) : const Color(0xFFF4F0E6);
  final edge = dark ? const Color(0xFFB7AFA4) : const Color(0xFF6A5C48);
  return [
    for (final rect in _placeRects)
      Polygon(
        points: [
          LatLng(rect.$1, rect.$2),
          LatLng(rect.$1, rect.$4),
          LatLng(rect.$3, rect.$4),
          LatLng(rect.$3, rect.$2),
        ],
        color: fill,
        borderColor: edge,
        borderStrokeWidth: 1,
      ),
  ];
}

/// Lattice spacing. The drawn outline is smaller, so the cells stay apart
/// and the map shows through the middle.
const _hexRadius = 880.0;
const _hexDraw = 0.70;

class _HexCell {
  const _HexCell(this.lat, this.lon, this.demand);

  final double lat;
  final double lon;
  final double demand;
}

List<_HexCell> _hexCells() {
  const radius = _hexRadius;
  const mPerLat = 111320.0;
  final mPerLon = mPerLat * math.cos(9.05 * math.pi / 180);
  final dx = radius * math.sqrt(3);
  final dy = radius * 1.5;
  const originLat = 9.04;
  const originLon = 7.49;
  const hotspots = <(double, double)>[(9.12, 7.45), (9.16, 7.56), (9.00, 7.50)];
  final cells = <_HexCell>[];
  for (var r = -20; r <= 20; r++) {
    for (var q = -14; q <= 14; q++) {
      final x = dx * (q + r / 2);
      final y = dy * r;
      final lat = originLat + y / mPerLat;
      final lon = originLon + x / mPerLon;
      if (lat < 8.86 || lat > 9.23 || lon < 7.37 || lon > 7.61) continue;
      var demand = 0.0;
      for (final spot in hotspots) {
        final sLat = (lat - spot.$1) * mPerLat;
        final sLon = (lon - spot.$2) * mPerLon;
        final dist = math.sqrt(sLat * sLat + sLon * sLon);
        demand = math.max(demand, 1 - dist / 8500);
      }
      cells.add(_HexCell(lat, lon, demand));
    }
  }
  return cells;
}

List<_HexCell> _hotCells(List<_HexCell> cells) {
  const mPerLat = 111320.0;
  final mPerLon = mPerLat * math.cos(9.05 * math.pi / 180);
  final ranked = [...cells]..sort((a, b) => b.demand.compareTo(a.demand));
  final hot = <_HexCell>[];
  for (final cell in ranked) {
    if (hot.length == 3) break;
    final separated = hot.every((other) {
      final dLat = (cell.lat - other.lat) * mPerLat;
      final dLon = (cell.lon - other.lon) * mPerLon;
      return math.sqrt(dLat * dLat + dLon * dLon) > _hexRadius * 2.6;
    });
    if (separated) hot.add(cell);
  }
  return hot;
}

bool _sameCell(_HexCell a, _HexCell b) {
  return (a.lat - b.lat).abs() < 1e-6 && (a.lon - b.lon).abs() < 1e-6;
}

/// Outlines only. Stroke alpha is 6, 12, or 20 percent ink. The three hot
/// cells are left to the breath layer so they can glow.
List<Polygon> _demandOutlines(AlongPalette palette) {
  const mPerLat = 111320.0;
  final mPerLon = mPerLat * math.cos(9.05 * math.pi / 180);
  const stroke = <double>[0.06, 0.12, 0.20];
  final cells = _hexCells();
  final hot = _hotCells(cells);
  final polygons = <Polygon>[];
  for (final cell in cells) {
    if (hot.any((mark) => _sameCell(cell, mark))) continue;
    final step = cell.demand < 0.34
        ? 0
        : cell.demand < 0.62
        ? 1
        : 2;
    polygons.add(
      Polygon(
        points: _hexRing(
          LatLng(cell.lat, cell.lon),
          _hexRadius * _hexDraw,
          mPerLat,
          mPerLon,
        ),
        color: const Color(0x00000000),
        borderColor: palette.ink.withValues(alpha: stroke[step]),
        borderStrokeWidth: 1.15,
      ),
    );
  }
  return polygons;
}

List<List<LatLng>> _demandHotRings() {
  const mPerLat = 111320.0;
  final mPerLon = mPerLat * math.cos(9.05 * math.pi / 180);
  return [
    for (final cell in _hotCells(_hexCells()))
      _hexRing(
        LatLng(cell.lat, cell.lon),
        _hexRadius * _hexDraw,
        mPerLat,
        mPerLon,
      ),
  ];
}

/// Yellow fill at 85 percent, a soft glow, and a 2.4s breath. The controller
/// stays stopped when motion does not play, so a golden is the rest glow.
class _DemandBreath extends StatefulWidget {
  const _DemandBreath({required this.rings, required this.palette});

  final List<List<LatLng>> rings;
  final AlongPalette palette;

  @override
  State<_DemandBreath> createState() => _DemandBreathState();
}

class _DemandBreathState extends State<_DemandBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(vsync: this, duration: AlongDurations.breath);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = AlongMotionPolicy.play(context);
    if (animate && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!animate && _breath.isAnimating) {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) {
          final t = AlongMotionPolicy.play(context)
              ? Curves.easeInOut.transform(_breath.value)
              : 0.0;
          return CustomPaint(
            painter: _DemandGlowPainter(
              camera: camera,
              rings: widget.rings,
              palette: widget.palette,
              breath: t,
            ),
          );
        },
      ),
    );
  }
}

class _DemandGlowPainter extends CustomPainter {
  _DemandGlowPainter({
    required this.camera,
    required this.rings,
    required this.palette,
    required this.breath,
  });

  final MapCamera camera;
  final List<List<LatLng>> rings;
  final AlongPalette palette;
  final double breath;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = palette.accent.withValues(alpha: 0.22 + 0.16 * breath);
    final blur = 8 + 5 * breath;
    for (final ring in rings) {
      final path = Path();
      for (var i = 0; i < ring.length; i++) {
        final at = camera.latLngToScreenOffset(ring[i]);
        if (i == 0) {
          path.moveTo(at.dx, at.dy);
        } else {
          path.lineTo(at.dx, at.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = glow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
      canvas.drawPath(
        path,
        Paint()..color = palette.accent.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DemandGlowPainter oldDelegate) {
    return oldDelegate.breath != breath ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}

/// Blocks and crossing streets around the nav road, inside the z16 extract.
const _navRects = <(double, double, double, double)>[
  (9.05891, 7.46030, 9.05876, 7.46055),
  (9.05891, 7.46168, 9.05876, 7.46192),
  (9.05931, 7.46122, 9.05915, 7.46146),
  (9.05931, 7.46259, 9.05915, 7.46284),
  (9.05970, 7.46351, 9.05955, 7.46375),
  (9.05970, 7.46488, 9.05955, 7.46512),
  (9.05891, 7.46442, 9.05876, 7.46467),
  (9.05784, 7.46030, 9.05768, 7.46055),
  (9.05784, 7.46168, 9.05768, 7.46192),
  (9.05744, 7.46122, 9.05729, 7.46146),
  (9.05744, 7.46305, 9.05729, 7.46329),
  (9.05705, 7.46259, 9.05689, 7.46284),
  (9.05705, 7.46442, 9.05689, 7.46467),
  (9.05784, 7.46488, 9.05768, 7.46512),
  (9.05665, 7.46122, 9.05650, 7.46146),
  (9.05784, 7.45985, 9.05768, 7.46009),
];

List<Polygon> _navBlocks(AlongPalette palette) {
  final dark = palette.brightness == Brightness.dark;
  final fill = dark ? const Color(0xFF2C2A26) : const Color(0xFFF4F0E6);
  final edge = dark ? const Color(0xFFB7AFA4) : const Color(0xFF6A5C48);
  return [
    for (final rect in _navRects)
      Polygon(
        points: [
          LatLng(rect.$1, rect.$2),
          LatLng(rect.$1, rect.$4),
          LatLng(rect.$3, rect.$4),
          LatLng(rect.$3, rect.$2),
        ],
        color: fill,
        borderColor: edge,
        borderStrokeWidth: 1,
      ),
  ];
}

List<Polyline> _navStreets(AlongPalette palette) {
  final dark = palette.brightness == Brightness.dark;
  const lines = <List<LatLng>>[
    [LatLng(9.05640, 7.46073), LatLng(9.05995, 7.46073)],
    [LatLng(9.05650, 7.46230), LatLng(9.06010, 7.46230)],
    [LatLng(9.05660, 7.46374), LatLng(9.06005, 7.46374)],
    [LatLng(9.05670, 7.46491), LatLng(9.05985, 7.46491)],
    [LatLng(9.05695, 7.45920), LatLng(9.05695, 7.46580)],
  ];
  return [
    for (final line in lines)
      Polyline(
        points: line,
        strokeWidth: 11,
        color: palette.mapRoad,
        borderStrokeWidth: 2,
        borderColor: dark ? const Color(0xFF3A3C44) : const Color(0xFFC5C7CE),
        strokeCap: StrokeCap.round,
      ),
  ];
}

List<LatLng> _hexRing(
  LatLng center,
  double radius,
  double mPerLat,
  double mPerLon,
) {
  return [
    for (var i = 0; i < 6; i++)
      LatLng(
        center.latitude +
            radius * math.cos(math.pi / 6 + i * math.pi / 3) / mPerLat,
        center.longitude +
            radius * math.sin(math.pi / 6 + i * math.pi / 3) / mPerLon,
      ),
  ];
}

class _RouteOverlay extends StatefulWidget {
  const _RouteOverlay({
    required this.route,
    required this.progress,
    required this.palette,
    this.lane = false,
  });

  final List<LatLng> route;
  final double progress;
  final AlongPalette palette;

  /// Lane-level nav. The ink stroke is 6dp on a casing.
  final bool lane;

  @override
  State<_RouteOverlay> createState() => _RouteOverlayState();
}

class _RouteOverlayState extends State<_RouteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: AlongDurations.routeDraw,
    );
    // The traveled stroke is the selected route. A looping pulse is decoration.
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final pulse = AlongMotionPolicy.play(context) ? _pulse.value : 0.0;
          return CustomPaint(
            painter: _RoutePainter(
              camera: camera,
              route: widget.route,
              progress: widget.progress,
              palette: widget.palette,
              pulse: pulse,
              lane: widget.lane,
            ),
          );
        },
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.camera,
    required this.route,
    required this.progress,
    required this.palette,
    this.pulse = 0,
    this.lane = false,
  });

  final MapCamera camera;
  final List<LatLng> route;
  final double progress;
  final AlongPalette palette;
  final double pulse;
  final bool lane;

  @override
  void paint(Canvas canvas, Size size) {
    final roles = palette.roles;
    final casing = roles.routeCasing;
    final full = _smooth(_screen(route));
    final grey = roles.stale.withValues(alpha: 0.55);
    // Nav is a 6dp ink line on a casing. The wider lane stroke read as a
    // fat white road on the beige extract.
    final casingW = lane ? 10.0 : 11.0;
    final restW = lane ? 6.0 : 6.5;
    final traveledCasing = lane ? 10.0 : 12.0;
    final traveledW = lane ? 6.0 : 7.0;
    final restColor = lane ? palette.ink.withValues(alpha: 0.45) : grey;
    canvas.drawPath(full, _stroke(casingW, casing));
    canvas.drawPath(full, _stroke(restW, restColor));
    if (progress > 0.02) {
      final traveled = _smooth(_points());
      canvas.drawPath(traveled, _stroke(traveledCasing, casing));
      canvas.drawPath(traveled, _stroke(traveledW, palette.ink));
      if (pulse > 0) {
        alongPaintRoutePulse(
          canvas,
          traveled,
          pulse,
          palette.ink.withValues(alpha: 0.55),
        );
      }
    }
  }

  List<Offset> _screen(List<LatLng> points) {
    return [for (final point in points) camera.latLngToScreenOffset(point)];
  }

  Paint _stroke(double width, Color color) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
  }

  List<Offset> _points() {
    final count = route.length;
    final last = ((count - 1) * progress).floor().clamp(0, count - 1);
    final points = <Offset>[
      for (var i = 0; i <= last; i++) camera.latLngToScreenOffset(route[i]),
    ];
    if (last < count - 1) {
      final start = route[last];
      final end = route[last + 1];
      final t = (count - 1) * progress - last;
      points.add(
        camera.latLngToScreenOffset(
          LatLng(
            start.latitude + (end.latitude - start.latitude) * t,
            start.longitude + (end.longitude - start.longitude) * t,
          ),
        ),
      );
    }
    return points;
  }

  Path _smooth(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    if (points.length < 3) {
      if (points.length == 2) path.lineTo(points.last.dx, points.last.dy);
      return path;
    }
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.lane != lane ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.rotation != camera.rotation ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}
