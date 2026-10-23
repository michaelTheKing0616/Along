import 'package:flutter/material.dart';

import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import 'city_map.dart';
import 'delights.dart';

/// Painted stand-in for the brand basemap. Widget tests must not mount MapLibre.
class AlongMapSketch extends StatelessWidget {
  const AlongMapSketch({
    super.key,
    this.progress = 1,
    this.showVehicle = false,
    this.showRoute = false,
  });

  /// 0 to 1 along the active route. Deterministic for goldens.
  final double progress;
  final bool showVehicle;
  final bool showRoute;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final drawn = AlongMotionPolicy.reduced(context) ? 1.0 : progress;
    return CustomPaint(
      painter: _MapSketchPainter(
        palette: palette,
        progress: drawn.clamp(0.0, 1.0),
        showVehicle: showVehicle,
        showRoute: showRoute,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _MapSketchPainter extends CustomPainter {
  _MapSketchPainter({
    required this.palette,
    required this.progress,
    required this.showVehicle,
    required this.showRoute,
  });

  final AlongPalette palette;
  final double progress;
  final bool showVehicle;
  final bool showRoute;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.mapLand);
    final water = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.58,
        size.width * 0.42,
        size.height * 0.78,
      )
      ..lineTo(0, size.height);
    canvas.drawPath(water, Paint()..color = palette.mapWater);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.28),
        width: size.width * 0.28,
        height: size.height * 0.16,
      ),
      Paint()..color = palette.mapPark,
    );
    final road = Paint()
      ..color = palette.mapRoad
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final spine = Path()
      ..moveTo(size.width * 0.08, size.height * 0.62)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.48,
        size.width * 0.55,
        size.height * 0.7,
        size.width * 0.92,
        size.height * 0.36,
      );
    canvas.drawPath(spine, road);
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.7, size.height * 0.42),
      road..strokeWidth = 6,
    );

    if (showRoute) {
      final metric = spine.computeMetrics().first;
      final extract = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(
        extract,
        Paint()
          ..color = palette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      if (showVehicle) {
        final tangent = metric.getTangentForOffset(metric.length * progress);
        if (tangent != null) {
          final center = tangent.position;
          canvas.drawCircle(center, 11, Paint()..color = palette.ink);
          canvas.drawCircle(center, 7, Paint()..color = palette.accent);
        }
      }
    }

    final puck = Offset(size.width * 0.5, size.height * 0.46);
    canvas.drawCircle(
      puck,
      16,
      Paint()..color = palette.ink.withValues(alpha: 0.18),
    );
    canvas.drawCircle(puck, 8, Paint()..color = palette.accent);
    canvas.drawCircle(
      puck,
      8,
      Paint()
        ..color = palette.accentInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MapSketchPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.palette.brightness != palette.brightness ||
        oldDelegate.showRoute != showRoute ||
        oldDelegate.showVehicle != showVehicle;
  }
}

/// 48dp map control. Shadow only, no border. [jk-accessibility]
class AlongMapButton extends StatelessWidget {
  const AlongMapButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return AlongPressable(
      child: Tooltip(
        message: tooltip ?? '',
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AlongElevation.float(palette.ink),
          ),
          child: AlongFrost(
            circle: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: AlongIcon(icon, color: palette.ink, size: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Route and vehicle motion used on the live-trip stage.
class AlongRouteMotion extends StatelessWidget {
  const AlongRouteMotion({super.key, this.progress = 0.62});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return AlongCityMap(mode: AlongCityMapMode.trip, progress: progress);
  }
}
