import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../elevation.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import 'vehicle_art.dart';

/// How the Abuja map is dressed. Tiles are cached OSM rasters, not painted blocks.
enum AlongCityMapMode { browse, trip, online, routeHero }

/// Real Wuse and Wuse–Nyanya maps.
///
/// Light tiles are OSM France rasters (© OpenStreetMap). Dark tiles are the
/// same roads and labels restyled in the package so tests stay offline.
/// They live under `assets/map/tiles`. Zoom 16 is the neighborhood camera.
/// The corridor camera is 11.5 so both ends fit a phone and the layer still
/// samples the zoom-12 cache.
class AlongCityMap extends StatelessWidget {
  const AlongCityMap({
    super.key,
    this.mode = AlongCityMapMode.browse,
    this.progress = 1,
  });

  final AlongCityMapMode mode;
  final double progress;

  /// Sits about one tile south of Wuse Market, so the market stays in the
  /// strip above a full-screen sheet on both 360×800 and 320×640.
  static const neighborhoodCenter = LatLng(9.063022, 7.465938);
  static const corridorCenter = LatLng(9.0460, 7.5183);
  static const wuseMarket = LatLng(9.068555, 7.465938);
  static const nyanya = LatLng(9.023418, 7.570635);

  /// Short run along the streets by Wuse Market. Visible above the ride sheet.
  static const neighborhoodRoute = <LatLng>[
    LatLng(9.06832, 7.46470),
    LatLng(9.06846, 7.46530),
    LatLng(9.068555, 7.465938),
    LatLng(9.06864, 7.46655),
    LatLng(9.06874, 7.46720),
  ];

  /// Driving trace from Wuse Market to Nyanya bus station (OSRM, simplified).
  static const corridorRoute = <LatLng>[
    LatLng(9.068635, 7.465950),
    LatLng(9.067955, 7.478710),
    LatLng(9.049603, 7.494781),
    LatLng(9.054443, 7.510700),
    LatLng(9.050663, 7.528593),
    LatLng(9.033038, 7.544055),
    LatLng(9.026961, 7.555911),
    LatLng(9.023418, 7.570635),
  ];

  bool get _corridor => mode == AlongCityMapMode.routeHero;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final dark = palette.brightness == Brightness.dark;
    final drawn = AlongMotionPolicy.reduced(context)
        ? 1.0
        : progress.clamp(0.0, 1.0);
    final route = _corridor ? corridorRoute : neighborhoodRoute;
    final showRoute =
        mode == AlongCityMapMode.trip || mode == AlongCityMapMode.routeHero;
    return FlutterMap(
      options: MapOptions(
        initialCenter: _corridor ? corridorCenter : neighborhoodCenter,
        initialZoom: _corridor ? 11.5 : 16,
        minZoom: _corridor ? 11.5 : 16,
        maxZoom: _corridor ? 11.5 : 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
        backgroundColor: dark ? const Color(0xFF1C1E22) : const Color(0xFFF2EFE9),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'assets/map/tiles/${dark ? 'dark' : 'light'}/{z}_{x}_{y}.png',
          tileProvider: AssetTileProvider(),
          userAgentPackageName: 'app.along.design',
          tileDisplay: const TileDisplay.instantaneous(),
          retinaMode: false,
          keepBuffer: 1,
          panBuffer: 0,
        ),
        if (mode == AlongCityMapMode.online)
          Positioned.fill(child: _DemandOverlay(palette: palette)),
        if (showRoute)
          Positioned.fill(
            child: _RouteOverlay(
              route: route,
              progress: drawn,
              palette: palette,
            ),
          ),
        MarkerLayer(
          rotate: true,
          markers: _markers(palette, drawn),
        ),
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(child: _Attribution(palette: palette)),
        ),
      ],
    );
  }

  List<Marker> _markers(AlongPalette palette, double drawn) {
    final markers = <Marker>[];
    if (mode == AlongCityMapMode.routeHero) {
      markers.add(_endpoint(wuseMarket, 'Wuse', true, palette));
      markers.add(_endpoint(nyanya, 'Nyanya', false, palette));
      return markers;
    }
    if (mode == AlongCityMapMode.trip) {
      final at = _along(neighborhoodRoute, drawn);
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
    if (mode == AlongCityMapMode.browse || mode == AlongCityMapMode.online) {
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

class _DemandOverlay extends StatelessWidget {
  const _DemandOverlay({required this.palette});

  final AlongPalette palette;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DemandPainter(
          camera: MapCamera.of(context),
          palette: palette,
        ),
      ),
    );
  }
}

/// Soft demand on real junctions, not a cell grid.
class _DemandPainter extends CustomPainter {
  _DemandPainter({required this.camera, required this.palette});

  final MapCamera camera;
  final AlongPalette palette;

  static const _blobs = <(LatLng, double, double)>[
    (LatLng(9.06870, 7.46540), 78, 0.55),
    (LatLng(9.06820, 7.46640), 96, 1),
    (LatLng(9.06910, 7.46690), 70, 0.78),
    (LatLng(9.06770, 7.46510), 64, 0.35),
    (LatLng(9.06790, 7.46690), 72, 0.48),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final blob in _blobs) {
      final center = camera.latLngToScreenOffset(blob.$1);
      final radius = blob.$2;
      final t = blob.$3;
      final color = t < 0.55
          ? Color.lerp(
              const Color(0xFF2F6F8F),
              const Color(0xFFE39B2B),
              t / 0.55,
            )!
          : Color.lerp(
              const Color(0xFFE39B2B),
              const Color(0xFFB93815),
              (t - 0.55) / 0.45,
            )!;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.45),
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DemandPainter oldDelegate) {
    return oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}
