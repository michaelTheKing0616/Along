import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../elevation.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import 'vehicle_art.dart';

/// How the painted Wuse map is dressed. The city is vector paint, not a photo.
enum AlongCityMapMode { browse, trip, online, routeHero }

/// A drawn Abuja neighborhood: blocks, streets, parks, and the Wuse–Nyanya road.
/// Widget tests paint this directly so frames stay stable without a tile server.
class AlongCityMap extends StatelessWidget {
  const AlongCityMap({
    super.key,
    this.mode = AlongCityMapMode.browse,
    this.progress = 1,
  });

  final AlongCityMapMode mode;
  final double progress;

  /// Fractions of the painted city. The trip follows Accra Street.
  static const route = <Offset>[
    Offset(0.14, 0.16),
    Offset(0.26, 0.18),
    Offset(0.38, 0.15),
    Offset(0.50, 0.13),
    Offset(0.62, 0.15),
    Offset(0.74, 0.12),
    Offset(0.88, 0.10),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final drawn = AlongMotionPolicy.reduced(context)
        ? 1.0
        : progress.clamp(0.0, 1.0);
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
              Positioned.fill(
                child: CustomPaint(
                  painter: _VectorCityPainter(frame: frame, palette: palette),
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
      _Pin(Offset(0.20, 0.24), 'Wuse', false),
      _Pin(Offset(0.72, 0.22), 'Nyanya', false),
      _Pin(Offset(0.16, 0.40), 'Park', true),
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
        _Marker(Offset(0.36, 0.22), AlongVehicleKind.keke, 2, -0.4),
        _Marker(Offset(0.58, 0.18), AlongVehicleKind.danfo, 6, 0.8),
      ];
    }
    return const [
      _Marker(Offset(0.30, 0.22), AlongVehicleKind.keke, 2, -0.5),
      _Marker(Offset(0.48, 0.28), AlongVehicleKind.car, 3, 0.3),
      _Marker(Offset(0.66, 0.20), AlongVehicleKind.danfo, 8, 1.0),
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
    final trip = mode == AlongCityMapMode.trip;
    final plate = trip ? 58.0 : 52.0;
    return Positioned(
      left: at.dx - plate / 2,
      top: at.dy - plate / 2,
      child: SizedBox(
        width: plate,
        height: plate,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (trip)
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
              kind: marker.kind,
              heading: marker.heading,
              size: trip ? 40 : 36,
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
    final at = frame.project(const Offset(0.40, 0.20));
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

class _MapFrame {
  _MapFrame(this.size, {this.fitRoute = false});

  final Size size;
  final bool fitRoute;

  static const routeMinX = 0.14;
  static const routeMaxX = 0.88;
  static const routeMinY = 0.10;
  static const routeMaxY = 0.18;

  Offset project(Offset fraction) {
    if (!fitRoute) {
      return Offset(fraction.dx * size.width, fraction.dy * size.height);
    }
    const pad = 24.0;
    final spanX = routeMaxX - routeMinX;
    final spanY = routeMaxY - routeMinY;
    final sx = (size.width - pad * 2) / spanX;
    final sy = (size.height - pad * 2) / spanY;
    final scale = math.min(sx, sy);
    final origin = Offset(
      size.width / 2 - (routeMinX + routeMaxX) / 2 * scale,
      size.height / 2 - (routeMinY + routeMaxY) / 2 * scale,
    );
    return Offset(
      origin.dx + fraction.dx * scale,
      origin.dy + fraction.dy * scale,
    );
  }
}

class _VectorCityPainter extends CustomPainter {
  _VectorCityPainter({required this.frame, required this.palette});

  final _MapFrame frame;
  final AlongPalette palette;

  static const _avenues = <double>[
    0.07,
    0.15,
    0.26,
    0.35,
    0.47,
    0.56,
    0.68,
    0.81,
    0.93,
  ];
  static const _streets = <double>[
    0.05,
    0.17,
    0.28,
    0.40,
    0.54,
    0.66,
    0.78,
    0.92,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final dark = palette.brightness == Brightness.dark;
    final land = dark ? const Color(0xFF16181C) : const Color(0xFFE7E4DC);
    final block = dark ? const Color(0xFF22262C) : const Color(0xFFF7F6F2);
    final park = dark ? const Color(0xFF1C3328) : const Color(0xFFD5E6D0);
    final water = dark ? const Color(0xFF1A3344) : const Color(0xFFC5D8E8);
    final minor = dark ? const Color(0xFF3A4048) : const Color(0xFFFFFFFF);
    final major = dark ? const Color(0xFF4A525C) : const Color(0xFFFFFDF8);
    final casing = dark ? const Color(0xFF0E1014) : const Color(0xFFD4D0C8);

    canvas.drawRect(Offset.zero & size, Paint()..color = land);

    _poly(canvas, water, const [
      Offset(0.00, 0.00),
      Offset(0.10, 0.00),
      Offset(0.07, 0.22),
      Offset(0.12, 0.40),
      Offset(0.06, 0.62),
      Offset(0.11, 1.00),
      Offset(0.00, 1.00),
    ]);

    _round(canvas, park, const Offset(0.10, 0.50), const Offset(0.24, 0.70));
    _round(canvas, park, const Offset(0.66, 0.58), const Offset(0.90, 0.78));
    _round(canvas, water, const Offset(0.78, 0.08), const Offset(0.94, 0.16));

    for (var r = 0; r < _avenues.length - 1; r++) {
      for (var c = 0; c < _streets.length - 1; c++) {
        if ((c == 0 && r >= 3 && r <= 4) || (c >= 4 && r >= 4 && r <= 5)) {
          continue;
        }
        final x0 = _streets[c] + 0.015;
        final y0 = _avenues[r] + 0.012;
        final x1 = _streets[c + 1] - 0.015;
        final y1 = _avenues[r + 1] - 0.012;
        final mid = (x0 + x1) / 2;
        _building(canvas, block, x0, y0, mid - 0.008, y1 - 0.004, c + r);
        _building(canvas, block, mid + 0.008, y0 + 0.008, x1, y1, c * 3 + r);
      }
    }

    final minorPaint = Paint()
      ..color = minor
      ..strokeWidth = dark ? 3 : 4
      ..strokeCap = StrokeCap.round;
    final casePaint = Paint()
      ..color = casing
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final majorPaint = Paint()
      ..color = major
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (final y in _avenues) {
      _line(canvas, casePaint, Offset(0.08, y), Offset(0.96, y));
      _line(canvas, minorPaint, Offset(0.08, y), Offset(0.96, y));
    }
    for (final x in _streets) {
      _line(canvas, casePaint, Offset(x, 0.06), Offset(x, 0.96));
      _line(canvas, minorPaint, Offset(x, 0.06), Offset(x, 0.96));
    }
    for (var i = 1; i < AlongCityMap.route.length; i++) {
      _line(
        canvas,
        casePaint,
        AlongCityMap.route[i - 1],
        AlongCityMap.route[i],
      );
    }
    for (var i = 1; i < AlongCityMap.route.length; i++) {
      _line(
        canvas,
        majorPaint,
        AlongCityMap.route[i - 1],
        AlongCityMap.route[i],
      );
    }
    final bend = Path()
      ..moveTo(
        _at(const Offset(0.18, 0.47)).dx,
        _at(const Offset(0.18, 0.47)).dy,
      )
      ..quadraticBezierTo(
        _at(const Offset(0.42, 0.62)).dx,
        _at(const Offset(0.42, 0.62)).dy,
        _at(const Offset(0.78, 0.52)).dx,
        _at(const Offset(0.78, 0.52)).dy,
      );
    canvas.drawPath(bend, casePaint);
    canvas.drawPath(bend, majorPaint);

    final label = dark ? const Color(0xFFB7BCC6) : const Color(0xFF5E6570);
    _label(canvas, 'Wuse', const Offset(0.24, 0.28), label);
    _label(canvas, 'Accra St', const Offset(0.48, 0.22), label);
    _label(canvas, 'Nyanya Rd', const Offset(0.74, 0.26), label);
    _label(canvas, 'Park', const Offset(0.16, 0.58), label);
  }

  void _poly(Canvas canvas, Color color, List<Offset> points) {
    final path = Path()..moveTo(_at(points.first).dx, _at(points.first).dy);
    for (final point in points.skip(1)) {
      final at = _at(point);
      path.lineTo(at.dx, at.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _round(Canvas canvas, Color color, Offset a, Offset b) {
    final start = _at(a);
    final end = _at(b);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(start, end),
        const Radius.circular(12),
      ),
      Paint()..color = color,
    );
  }

  void _building(
    Canvas canvas,
    Color color,
    double x0,
    double y0,
    double x1,
    double y1,
    int salt,
  ) {
    final inset = (salt % 3) * 0.004;
    final start = _at(Offset(x0 + inset, y0));
    final end = _at(Offset(x1 - inset, y1));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(start, end),
        const Radius.circular(2),
      ),
      Paint()..color = color,
    );
  }

  void _line(Canvas canvas, Paint paint, Offset a, Offset b) {
    final start = _at(a);
    final end = _at(b);
    canvas.drawLine(start, end, paint);
  }

  void _label(Canvas canvas, String text, Offset at, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'Satoshi',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final point = _at(at);
    painter.paint(
      canvas,
      point - Offset(painter.width / 2, painter.height / 2),
    );
  }

  Offset _at(Offset fraction) => frame.project(fraction);

  @override
  bool shouldRepaint(covariant _VectorCityPainter oldDelegate) {
    return oldDelegate.palette.brightness != palette.brightness ||
        oldDelegate.frame.size != frame.size ||
        oldDelegate.frame.fitRoute != frame.fitRoute;
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
    final path = _smooth(_points());
    final casing = palette.brightness == Brightness.dark
        ? const Color(0xFF0B0D10)
        : const Color(0xFF243040);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = casing,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = palette.surface,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = palette.accent,
    );
  }

  List<Offset> _points() {
    final count = AlongCityMap.route.length;
    final last = ((count - 1) * progress).floor().clamp(0, count - 1);
    final points = <Offset>[
      for (var i = 0; i <= last; i++) frame.project(AlongCityMap.route[i]),
    ];
    if (last < count - 1) {
      final start = AlongCityMap.route[last];
      final end = AlongCityMap.route[last + 1];
      final t = (count - 1) * progress - last;
      points.add(
        frame.project(
          Offset(
            start.dx + (end.dx - start.dx) * t,
            start.dy + (end.dy - start.dy) * t,
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
        oldDelegate.showRoute != showRoute ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}

/// Soft demand sitting on junctions, not a cell grid or a flat wash.
class _DemandPainter extends CustomPainter {
  _DemandPainter({required this.frame, required this.palette});

  final _MapFrame frame;
  final AlongPalette palette;

  static const _blobs = <(Offset, double, double)>[
    (Offset(0.32, 0.18), 0.18, 0.55),
    (Offset(0.48, 0.24), 0.22, 1),
    (Offset(0.64, 0.16), 0.16, 0.78),
    (Offset(0.40, 0.32), 0.14, 0.35),
    (Offset(0.58, 0.30), 0.15, 0.48),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final blob in _blobs) {
      final center = frame.project(blob.$1);
      final radius = blob.$2 * size.shortestSide;
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
            color.withValues(alpha: 0.42),
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
