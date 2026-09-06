import 'dart:async';
import 'dart:math' as math;

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';

/// Map placeholder with a heading-rotated vehicle marker (Tier B, doc 06 R-11).
class VehicleMarkerPanel extends StatelessWidget {
  const VehicleMarkerPanel({
    super.key,
    this.headingDegrees,
    this.showWalkingLine = true,
  });

  final int? headingDegrees;
  final bool showWalkingLine;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: AlongColors.surface100),
        if (showWalkingLine)
          CustomPaint(
            size: Size.infinite,
            painter: _WalkingLinePainter(),
          ),
        Transform.rotate(
          angle: (headingDegrees ?? 0) * math.pi / 180,
          child: CustomPaint(
            key: const Key('vehicle_direction_arrow'),
            size: const Size(48, 48),
            painter: _VehicleArrowPainter(),
          ),
        ),
      ],
    );
  }
}

class _VehicleArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AlongColors.brandYellow;
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..moveTo(center.dx, center.dy - size.height / 2)
      ..lineTo(center.dx + size.width / 3, center.dy + size.height / 4)
      ..lineTo(center.dx, center.dy + size.height / 6)
      ..lineTo(center.dx - size.width / 3, center.dy + size.height / 4)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, 6, Paint()..color = AlongColors.ink900);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WalkingLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AlongColors.modeCar
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final start = Offset(size.width * 0.3, size.height * 0.7);
    final end = Offset(size.width * 0.55, size.height * 0.45);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
