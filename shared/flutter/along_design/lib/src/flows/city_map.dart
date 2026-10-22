import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../elevation.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import 'driver_portrait.dart';
import 'vehicle_art.dart';

/// How the Abuja map is dressed.
enum AlongCityMapMode { browse, trip, online, routeHero, search }

/// Muted Abuja maps.
///
/// Tiles are pre-rendered at 3× from a Protomaps basemap extract of Abuja
/// (FCT bbox, see tool/extract_abuja_pmtiles.sh). The daily planet stops at
/// z15; neighborhood frames are the z16 slippy grid, drawn by overzooming
/// that z15 vector so building footprints stay sharp. Grey land, white roads,
/// soft parks and water, few labels. The corridor uses native zoom-12 tiles,
/// displayed at 11.6 so both ends fit without scaling a lower zoom up.
/// Demand is a separate alpha tile, not a blob overlay.
class AlongCityMap extends StatelessWidget {
  const AlongCityMap({
    super.key,
    this.mode = AlongCityMapMode.browse,
    this.progress = 1,
    this.liveMarker = false,
  });

  final AlongCityMapMode mode;
  final double progress;

  /// Drops a vehicle on the corridor. Guardian uses this for the live fix.
  final bool liveMarker;

  /// Sits about one tile south of Wuse Market, so the market stays in the
  /// strip above a full-screen sheet on both 360×800 and 320×640.
  static const neighborhoodCenter = LatLng(9.063022, 7.465938);
  static const corridorCenter = LatLng(9.0460, 7.5183);
  static const wuseMarket = LatLng(9.068555, 7.465938);
  static const nyanya = LatLng(9.023418, 7.570635);

  /// East-west street in the cached Wuse grid, south of the reservoir.
  /// Long enough that the drawn portion fills the band above the sheet.
  static const neighborhoodRoute = <LatLng>[
    LatLng(9.058278, 7.462292),
    LatLng(9.058278, 7.462871),
    LatLng(9.058278, 7.463450),
    LatLng(9.058278, 7.464030),
    LatLng(9.058278, 7.464609),
    LatLng(9.058278, 7.465189),
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
      mode == AlongCityMapMode.routeHero || mode == AlongCityMapMode.trip;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final dark = palette.brightness == Brightness.dark;
    final drawn = AlongMotionPolicy.reduced(context)
        ? 1.0
        : progress.clamp(0.0, 1.0);
    final route = _wide ? corridorRoute : neighborhoodRoute;
    final showRoute =
        mode == AlongCityMapMode.trip || mode == AlongCityMapMode.routeHero;
    return LayoutBuilder(
      builder: (context, constraints) {
        final trip = mode == AlongCityMapMode.trip;
        final fit = showRoute
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(_drawnRoute(route, drawn)),
                padding: trip
                    ? EdgeInsets.fromLTRB(
                        48,
                        72,
                        56,
                        constraints.maxHeight * 0.46 + 28,
                      )
                    : const EdgeInsets.fromLTRB(36, 36, 36, 36),
                // z12 tiles scale down when the corridor needs a wider frame.
                minZoom: trip ? 10 : 12,
                maxZoom: trip ? 12 : 12.4,
              )
            : null;
        return FlutterMap(
          options: MapOptions(
            initialCenter: _wide ? corridorCenter : neighborhoodCenter,
            initialZoom: _wide ? 12 : 16,
            initialCameraFit: fit,
            minZoom: _wide ? (trip ? 10 : 12) : 16,
            maxZoom: _wide ? (trip ? 12 : 12.4) : 16,
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
              keepBuffer: 1,
              panBuffer: 0,
            ),
            if (mode == AlongCityMapMode.online) _HeatWash(),
            if (showRoute)
              Positioned.fill(
                child: _RouteOverlay(
                  route: route,
                  progress: drawn,
                  palette: palette,
                ),
              ),
            MarkerLayer(rotate: true, markers: _markers(palette, drawn)),
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(child: _Attribution(palette: palette)),
            ),
          ],
        );
      },
    );
  }

  List<Marker> _markers(AlongPalette palette, double drawn) {
    final markers = <Marker>[];
    if (mode == AlongCityMapMode.routeHero) {
      markers.add(_endpoint(wuseMarket, 'Wuse', true, palette));
      markers.add(_endpoint(nyanya, 'Nyanya', false, palette));
      if (liveMarker) {
        final at = _along(corridorRoute, 0.62);
        markers.add(
          _vehicle(
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
    if (mode == AlongCityMapMode.trip) {
      final at = _along(corridorRoute, drawn);
      markers.add(
        _vehicle(
          at.point,
          AlongVehicleKind.car,
          null,
          at.heading,
          palette,
          emphasized: true,
        ),
      );
      return markers;
    }
    if (mode == AlongCityMapMode.browse) {
      markers.add(_pin(wuseMarket, 'Wuse', false, palette));
      markers.add(_pin(const LatLng(9.06905, 7.46485), 'Park', true, palette));
    }
    if (mode == AlongCityMapMode.search) {
      markers.add(_radar(wuseMarket, palette));
      markers.add(
        _driver(const LatLng(9.06902, 7.46662), '4 min', false, palette),
      );
      markers.add(
        _driver(const LatLng(9.06805, 7.46515), '6 min', true, palette),
      );
    }
    if (mode == AlongCityMapMode.online) {
      markers.add(
        _vehicle(
          const LatLng(9.06842, 7.46505),
          AlongVehicleKind.keke,
          2,
          -0.4,
          palette,
        ),
      );
      markers.add(
        _vehicle(
          const LatLng(9.06878, 7.46670),
          AlongVehicleKind.danfo,
          6,
          0.8,
          palette,
        ),
      );
    } else if (mode == AlongCityMapMode.browse) {
      markers.add(
        _vehicle(
          const LatLng(9.06840, 7.46495),
          AlongVehicleKind.keke,
          2,
          -0.5,
          palette,
        ),
      );
      markers.add(
        _vehicle(
          const LatLng(9.06862, 7.46615),
          AlongVehicleKind.car,
          3,
          0.3,
          palette,
        ),
      );
      markers.add(
        _vehicle(
          const LatLng(9.06822, 7.46555),
          AlongVehicleKind.danfo,
          8,
          1.0,
          palette,
        ),
      );
    }
    if (mode == AlongCityMapMode.browse ||
        mode == AlongCityMapMode.online ||
        mode == AlongCityMapMode.search) {
      markers.add(_puck(const LatLng(9.06812, 7.46525), palette));
    }
    return markers;
  }

  Marker _endpoint(LatLng at, String label, bool pickup, AlongPalette palette) {
    return Marker(
      point: at,
      width: 72,
      height: 34,
      alignment: Alignment.bottomCenter,
      child: Column(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: pickup ? palette.accent : palette.ink,
              shape: BoxShape.circle,
              border: Border.all(color: palette.surface, width: 2),
              boxShadow: AlongElevation.float(palette.ink),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette).copyWith(
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: palette.ink,
              backgroundColor: palette.surface.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Marker _pin(LatLng at, String label, bool park, AlongPalette palette) {
    return Marker(
      point: at,
      width: 64,
      height: 36,
      alignment: Alignment.bottomCenter,
      child: Column(
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
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette).copyWith(
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: palette.ink,
              backgroundColor: palette.surface.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Marker _vehicle(
    LatLng at,
    AlongVehicleKind kind,
    int? seats,
    double heading,
    AlongPalette palette, {
    bool emphasized = false,
  }) {
    final plate = emphasized ? 58.0 : 52.0;
    return Marker(
      point: at,
      width: plate,
      height: plate,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (emphasized)
            Container(
              width: plate,
              height: plate,
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
                boxShadow: AlongElevation.float(palette.ink),
              ),
            ),
          AlongTopDownMark(
            kind: kind,
            heading: heading,
            size: emphasized ? 40 : 36,
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
                  style: AlongType.numeric(
                    palette,
                  ).copyWith(fontSize: 11, height: 1, color: palette.accentInk),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Marker _radar(LatLng at, AlongPalette palette) {
    return Marker(
      point: at,
      width: 210,
      height: 210,
      alignment: Alignment.center,
      child: _PulseRadar(palette: palette),
    );
  }

  Marker _driver(LatLng at, String eta, bool rider, AlongPalette palette) {
    return Marker(
      point: at,
      width: 74,
      height: 58,
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
                  fontWeight: FontWeight.w700,
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

  Marker _puck(LatLng at, AlongPalette palette) {
    return Marker(
      point: at,
      width: 18,
      height: 18,
      child: Container(
        decoration: BoxDecoration(
          color: palette.accent,
          shape: BoxShape.circle,
          border: Border.all(color: palette.surface, width: 3),
          boxShadow: AlongElevation.float(palette.ink),
        ),
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
        color: palette.surface.withValues(alpha: 0.92),
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
    if (AlongMotionPolicy.inWidgetTest) {
      _pulse.value = 0.42;
    } else {
      _pulse.repeat();
    }
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

class _RoutePoint {
  const _RoutePoint(this.point, this.heading);

  final LatLng point;
  final double heading;
}

/// The part of [route] the painter has actually stroked. Fitting the full
/// line leaves the undrawn tail as empty map.
List<LatLng> _drawnRoute(List<LatLng> route, double progress) {
  if (route.length < 2 || progress >= 0.999) return route;
  final segments = route.length - 1;
  final scaled = (segments * progress).clamp(0.0, segments.toDouble());
  if (scaled < 0.05) return route;
  final last = scaled.floor().clamp(0, segments - 1);
  final t = scaled - last;
  final a = route[last];
  final b = route[last + 1];
  return [
    ...route.take(last + 1),
    LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    ),
  ];
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

/// Demand as a soft wash. The heat tiles recolor roads orange; this keeps
/// the muted basemap and lets only the warm demand through.
class _HeatWash extends StatelessWidget {
  const _HeatWash();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.72,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0,
              0,
              0,
              0,
              232,
              0,
              0,
              0,
              0,
              132,
              0,
              0,
              0,
              0,
              28,
              0.85,
              -0.22,
              -0.62,
              0,
              -12,
            ]),
            child: TileLayer(
              urlTemplate: 'assets/map/tiles/heat/{z}_{x}_{y}.png',
              tileProvider: AssetTileProvider(),
              userAgentPackageName: 'app.along.design',
              tileDisplay: const TileDisplay.instantaneous(),
              retinaMode: false,
              minNativeZoom: 12,
              maxNativeZoom: 16,
              keepBuffer: 1,
              panBuffer: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteOverlay extends StatelessWidget {
  const _RouteOverlay({
    required this.route,
    required this.progress,
    required this.palette,
  });

  final List<LatLng> route;
  final double progress;
  final AlongPalette palette;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return IgnorePointer(
      child: CustomPaint(
        painter: _RoutePainter(
          camera: camera,
          route: route,
          progress: progress,
          palette: palette,
        ),
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
  });

  final MapCamera camera;
  final List<LatLng> route;
  final double progress;
  final AlongPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _smooth(_points());
    final casing = palette.brightness == Brightness.dark
        ? const Color(0xFF0B0D10)
        : const Color(0xFF243040);
    canvas.drawPath(path, _stroke(10, casing));
    canvas.drawPath(path, _stroke(5, palette.surface));
    canvas.drawPath(path, _stroke(2.5, palette.accent));
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
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}
