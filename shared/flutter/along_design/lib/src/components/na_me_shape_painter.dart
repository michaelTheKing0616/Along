import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/name_signal.dart';

/// Shared Na Me shape glyph painter (doc 05 §6 — 24 dp chip / 240 dp screen).
class NaMeShapePainter extends CustomPainter {
  NaMeShapePainter({required this.shape, required this.color});

  final NaMeShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    switch (shape) {
      case NaMeShape.circle:
        canvas.drawCircle(center, r, paint);
      case NaMeShape.square:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: r * 2, height: r * 2),
          paint,
        );
      case NaMeShape.triangle:
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy + r)
          ..lineTo(center.dx - r, center.dy + r)
          ..close();
        canvas.drawPath(path, paint);
      case NaMeShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r, center.dy)
          ..close();
        canvas.drawPath(path, paint);
      case NaMeShape.star:
        _drawStar(canvas, center, r, paint);
      case NaMeShape.hexagon:
        _drawPolygon(canvas, center, r, 6, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final radius = i.isEven ? r : r * 0.45;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPolygon(
    Canvas canvas,
    Offset center,
    double r,
    int sides,
    Paint paint,
  ) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = (2 * math.pi * i / sides) - math.pi / 2;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant NaMeShapePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
