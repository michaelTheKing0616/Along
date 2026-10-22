import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../elevation.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import 'vehicle_art.dart';

/// How the Abuja snapshot is dressed. Widget tests paint this asset, not MapLibre.
enum AlongCityMapMode { browse, trip, online, routeHero }

/// Pre-rendered along-paper / along-dusk tiles for Wuse, with the Accra Street
/// route projected from the same camera.
class AlongCityMap extends StatelessWidget {
  const AlongCityMap({
    super.key,
    this.mode = AlongCityMapMode.browse,
    this.progress = 1,
  });

  final AlongCityMapMode mode;
  final double progress;

  static const imageWidth = 800.0;
  static const imageHeight = 1400.0;

  /// Image fractions for Accra Street, zoom 15.15, from the render camera.
  static const route = <Offset>[
    Offset(0.2806, 0.3233),
    Offset(0.3027, 0.3338),
    Offset(0.3114, 0.3383),
    Offset(0.3190, 0.3442),
    Offset(0.3686, 0.4049),
    Offset(0.3932, 0.4338),
    Offset(0.4019, 0.4435),
    Offset(0.4123, 0.4531),
    Offset(0.4213, 0.4604),
    Offset(0.4314, 0.4675),
    Offset(0.4498, 0.4780),
    Offset(0.4692, 0.4881),
    Offset(0.4855, 0.4948),
    Offset(0.5000, 0.5000),
    Offset(0.5354, 0.5117),
    Offset(0.5763, 0.5238),
    Offset(0.6308, 0.5377),
    Offset(0.6994, 0.5537),
    Offset(0.7157, 0.5571),
    Offset(0.7996, 0.5725),
    Offset(0.8100, 0.5741),
    Offset(0.8222, 0.5745),
    Offset(0.8339, 0.5733),
    Offset(0.8437, 0.5709),
    Offset(0.8589, 0.5648),
    Offset(0.9477, 0.5212),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final drawn = AlongMotionPolicy.reduced(context)
        ? 1.0
        : progress.clamp(0.0, 1.0);
    final asset = palette.brightness == Brightness.dark
        ? 'assets/map/abuja_dusk.png'
        : 'assets/map/abuja_paper.png';
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final frame = _MapFrame(
          size,
          fitRoute: mode == AlongCityMapMode.routeHero,
        );
        final markers = _markers(drawn);
        final showBrowsePins =
            mode != AlongCityMapMode.online &&
            mode != AlongCityMapMode.routeHero;
        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: frame.origin.dx,
                top: frame.origin.dy,
                width: frame.drawnSize.width,
                height: frame.drawnSize.height,
                child: _MapRaster(
                  asset: asset,
                  cool: palette.brightness == Brightness.light,
                ),
              ),
              if (mode == AlongCityMapMode.online)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DemandPainter(frame: frame, palette: palette),
                  ),
                ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoutePainter(
                    frame: frame,
                    palette: palette,
                    progress: drawn,
                    showRoute:
                        mode == AlongCityMapMode.trip ||
                        mode == AlongCityMapMode.routeHero,
                  ),
                ),
              ),
              for (final pin in _pins())
                if (showBrowsePins) _pinWidget(frame, pin, palette),
              if (mode == AlongCityMapMode.routeHero) ...[
                _endpoint(
                  frame,
                  AlongCityMap.route.first,
                  'Wuse Market',
                  true,
                  palette,
                ),
                _endpoint(
                  frame,
                  AlongCityMap.route.last,
                  'Nyanya',
                  false,
                  palette,
                ),
              ],
              for (final marker in markers)
                _markerWidget(frame, marker, palette),
              if (mode == AlongCityMapMode.browse ||
                  mode == AlongCityMapMode.online)
                _puck(frame, palette),
            ],
          ),
        );
      },
    );
  }

  List<_Pin> _pins() {
    return const [
      _Pin(Offset(0.1831, 0.6171), 'Sky Memorial', false),
      _Pin(Offset(0.6966, 0.6054), 'Wuse Stn', false),
      _Pin(Offset(0.1634, 0.6783), 'Park', true),
    ];
  }

  List<_Marker> _markers(double drawn) {
    if (mode == AlongCityMapMode.routeHero) return const [];
    if (mode == AlongCityMapMode.trip) {
      final index = _indexFor(drawn);
      return [
        _Marker(route[index], AlongVehicleKind.car, null, _heading(index)),
      ];
    }
    if (mode == AlongCityMapMode.online) {
      return const [
        _Marker(Offset(0.4019, 0.4435), AlongVehicleKind.keke, 2, -0.4),
        _Marker(Offset(0.5354, 0.5117), AlongVehicleKind.danfo, 6, 0.9),
      ];
    }
    return const [
      _Marker(Offset(0.4019, 0.4435), AlongVehicleKind.keke, 2, -0.7),
      _Marker(Offset(0.4855, 0.4948), AlongVehicleKind.car, 3, 0.35),
      _Marker(Offset(0.7157, 0.5571), AlongVehicleKind.danfo, 8, 1.15),
    ];
  }

  double _heading(int index) {
    final i = index.clamp(1, route.length - 1);
    return alongHeading(route[i - 1], route[i]);
  }

  int _indexFor(double drawn) {
    final last = route.length - 1;
    return (drawn * last).round().clamp(0, last);
  }

  Widget _pinWidget(_MapFrame frame, _Pin pin, AlongPalette palette) {
    final at = frame.project(pin.at);
    return Positioned(
      left: at.dx - 8,
      top: at.dy - 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: pin.park ? palette.mapPark : palette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: palette.ink, width: 2),
              boxShadow: AlongElevation.float(palette.ink),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: AlongElevation.float(palette.ink),
            ),
            child: Text(
              pin.label,
              style: AlongType.caption(palette).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _markerWidget(_MapFrame frame, _Marker marker, AlongPalette palette) {
    final at = frame.project(marker.at);
    return Positioned(
      left: at.dx - 22,
      top: at.dy - 22,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AlongTopDownMark(
              kind: marker.kind,
              heading: marker.heading,
              size: 40,
            ),
            if (marker.seats != null)
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
                    '${marker.seats}',
                    style: AlongType.numeric(palette)
                        .copyWith(fontSize: 11, color: palette.accentInk),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _endpoint(
    _MapFrame frame,
    Offset at,
    String label,
    bool pickup,
    AlongPalette palette,
  ) {
    final point = frame.project(at);
    return Positioned(
      left: point.dx - 52,
      top: point.dy - 7,
      width: 104,
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
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AlongType.caption(palette).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.ink,
              backgroundColor: palette.surface.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _puck(_MapFrame frame, AlongPalette palette) {
    final at = frame.project(const Offset(0.3686, 0.4049));
    return Positioned(
      left: at.dx - 9,
      top: at.dy - 9,
      child: Container(
        width: 18,
        height: 18,
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

class _MapRaster extends StatelessWidget {
  const _MapRaster({required this.asset, required this.cool});

  final String asset;
  final bool cool;

  static const _cool = ColorFilter.matrix(<double>[
    0.78,
    0.12,
    0.06,
    0,
    8,
    0.04,
    0.86,
    0.08,
    0,
    8,
    0.00,
    0.08,
    1.12,
    0,
    16,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      package: 'along_design',
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
    if (!cool) return image;
    return ColorFiltered(colorFilter: _cool, child: image);
  }
}

class _MapFrame {
  _MapFrame(this.size, {this.fitRoute = false});

  final Size size;
  final bool fitRoute;

  static const zoom = 1.15;
  static const focal = Offset(0.48, 0.50);
  static const anchor = Offset(0.50, 0.18);

  /// Accra Street bbox in image fractions, including the southward bulge.
  static const routeMinX = 0.2806;
  static const routeMaxX = 0.9477;
  static const routeMinY = 0.3233;
  static const routeMaxY = 0.5745;

  double get scale {
    if (!fitRoute) return size.height * zoom / AlongCityMap.imageHeight;
    const pad = 36.0;
    final spanX = (routeMaxX - routeMinX) * AlongCityMap.imageWidth;
    final spanY = (routeMaxY - routeMinY) * AlongCityMap.imageHeight;
    final sx = (size.width - pad * 2) / spanX;
    final sy = (size.height - pad * 2) / spanY;
    return math.min(sx, sy);
  }

  Size get drawnSize =>
      Size(AlongCityMap.imageWidth * scale, AlongCityMap.imageHeight * scale);

  Offset get origin {
    if (!fitRoute) {
      return Offset(
        size.width * anchor.dx - focal.dx * drawnSize.width,
        size.height * anchor.dy - focal.dy * drawnSize.height,
      );
    }
    return Offset(
      size.width / 2 - (routeMinX + routeMaxX) / 2 * drawnSize.width,
      size.height / 2 - (routeMinY + routeMaxY) / 2 * drawnSize.height,
    );
  }

  Offset project(Offset fraction) {
    return Offset(
      origin.dx + fraction.dx * drawnSize.width,
      origin.dy + fraction.dy * drawnSize.height,
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.frame,
    required this.palette,
    required this.progress,
    required this.showRoute,
  });

  final _MapFrame frame;
  final AlongPalette palette;
  final double progress;
  final bool showRoute;

  @override
  void paint(Canvas canvas, Size size) {
    if (!showRoute) return;
    final last = ((AlongCityMap.route.length - 1) * progress).floor();
    final path = Path();
    final first = frame.project(AlongCityMap.route.first);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i <= last; i++) {
      final point = frame.project(AlongCityMap.route[i]);
      path.lineTo(point.dx, point.dy);
    }
    if (last < AlongCityMap.route.length - 1) {
      final start = AlongCityMap.route[last];
      final end = AlongCityMap.route[last + 1];
      final t = (AlongCityMap.route.length - 1) * progress - last;
      final mid = Offset(
        start.dx + (end.dx - start.dx) * t,
        start.dy + (end.dy - start.dy) * t,
      );
      final point = frame.project(mid);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = palette.accent.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = palette.ink,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showRoute != showRoute ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}

/// Soft seat-demand wash. Warm amber over the tiles, not a hex grid.
class _DemandPainter extends CustomPainter {
  _DemandPainter({required this.frame, required this.palette});

  final _MapFrame frame;
  final AlongPalette palette;

  static const _spots = <(Offset, double, double)>[
    (Offset(0.42, 0.46), 0.24, 0.28),
    (Offset(0.55, 0.51), 0.28, 0.20),
    (Offset(0.68, 0.56), 0.20, 0.16),
    (Offset(0.36, 0.40), 0.18, 0.12),
    (Offset(0.62, 0.44), 0.16, 0.14),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const warm = Color(0xFFE8A23A);
    for (final spot in _spots) {
      final center = frame.project(spot.$1);
      final radius = spot.$2 * frame.drawnSize.width;
      final alpha = spot.$3;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            palette.accent.withValues(alpha: alpha),
            warm.withValues(alpha: alpha * 0.45),
            palette.accent.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DemandPainter oldDelegate) {
    return oldDelegate.palette.brightness != palette.brightness ||
        oldDelegate.frame.size != frame.size;
  }
}

class _Pin {
  const _Pin(this.at, this.label, this.park);

  final Offset at;
  final String label;
  final bool park;
}

class _Marker {
  const _Marker(this.at, this.kind, this.seats, this.heading);

  final Offset at;
  final AlongVehicleKind kind;
  final int? seats;
  final double heading;
}
