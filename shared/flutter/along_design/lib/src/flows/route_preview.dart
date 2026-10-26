import 'package:flutter/material.dart';

import '../palette.dart';

/// A drawn street grid with an optional pickup-to-drop route.
///
/// Needs no tiles or network, so it renders the same in every host app
/// and in goldens. Use it where a live map is not worth the cost, such as
/// the trip options header, or as a stand-in while the map loads.
class AlongRoutePreview extends StatelessWidget {
  const AlongRoutePreview({super.key, this.route = true, this.semanticLabel});

  /// Draws the route, pickup dot and drop pin. False leaves only streets.
  final bool route;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: CustomPaint(
        painter: _StreetsPainter(palette, AlongRoles.of(palette), route),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StreetsPainter extends CustomPainter {
  _StreetsPainter(this.p, this.r, this.route);

  final AlongPalette p;
  final AlongRoles r;
  final bool route;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(Offset.zero & s, Paint()..color = p.mapLand);
    // Park and water blocks, placed in fractions so any size reads well.
    final rr = Radius.circular(w * 0.04);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .62, h * .08, w * .3, h * .2),
        rr,
      ),
      Paint()..color = p.mapPark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .06, h * .6, w * .22, h * .3),
        rr,
      ),
      Paint()..color = p.mapPark,
    );
    final water = Path()
      ..moveTo(0, h * .34)
      ..cubicTo(w * .2, h * .3, w * .3, h * .46, w * .52, h * .44)
      ..lineTo(w * .52, h * .5)
      ..cubicTo(w * .3, h * .52, w * .2, h * .37, 0, h * .41)
      ..close();
    canvas.drawPath(water, Paint()..color = p.mapWater);

    final dark =
        ThemeData.estimateBrightnessForColor(p.mapLand) == Brightness.dark;
    // Dark roads are pale; dim them so the route stays the brightest line.
    final road = dark ? p.mapRoad.withValues(alpha: 0.35) : p.mapRoad;
    final minor = Paint()
      ..color = road
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final x in [.14, .38, .86]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * (x + .06), h), minor);
    }
    for (final y in [.16, .56, .8]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * (y - .04)), minor);
    }
    final major = Paint()
      ..color = road
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * .7), Offset(w, h * .22), major);
    canvas.drawLine(Offset(w * .56, 0), Offset(w * .6, h), major);

    if (!route) return;
    // Kept in the lower band, clear of the buttons that sit on top.
    final a = Offset(w * .22, h * .78);
    final b = Offset(w * .78, h * .42);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(w * .22, h * .64)
      ..lineTo(w * .58, h * .5)
      ..lineTo(w * .58, h * .42)
      ..lineTo(b.dx, b.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = r.routeCasing
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = r.route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(a, 9, Paint()..color = p.surface);
    canvas.drawCircle(a, 6, Paint()..color = r.pickup);
    // Drop: a squared marker, so it reads apart from the round pickup.
    final drop = RRect.fromRectAndRadius(
      Rect.fromCenter(center: b, width: 18, height: 18),
      const Radius.circular(6),
    );
    canvas.drawRRect(drop.inflate(3), Paint()..color = p.surface);
    canvas.drawRRect(drop, Paint()..color = r.dropoff);
  }

  @override
  bool shouldRepaint(_StreetsPainter old) => old.p != p || old.route != route;
}
