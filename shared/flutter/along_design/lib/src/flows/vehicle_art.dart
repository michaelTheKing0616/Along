import 'package:flutter/material.dart';

import '../palette.dart';

/// Shared vehicle set. One geometric drawing language for cards and the map.
enum AlongVehicleKind { keke, okada, car, danfo, bus }

/// Side-view mark. Drawn in a 100 by 72 box and scaled to [width].
class AlongVehicleMark extends StatelessWidget {
  const AlongVehicleMark({super.key, required this.kind, this.width = 44});

  final AlongVehicleKind kind;
  final double width;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: width,
      height: width * 0.72,
      child: CustomPaint(
        painter: _VehicleSidePainter(
          kind: kind,
          ink: palette.ink,
          accent: palette.accent,
          surface: palette.surface,
          glass: palette.brightness == Brightness.dark
              ? const Color(0xFF3A342C)
              : const Color(0xFFD5E4E4),
        ),
      ),
    );
  }
}

class _VehicleSidePainter extends CustomPainter {
  _VehicleSidePainter({
    required this.kind,
    required this.ink,
    required this.accent,
    required this.surface,
    required this.glass,
  });

  final AlongVehicleKind kind;
  final Color ink;
  final Color accent;
  final Color surface;
  final Color glass;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 72);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = ink
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..style = PaintingStyle.fill;
    switch (kind) {
      case AlongVehicleKind.keke:
        _keke(canvas, fill, stroke);
      case AlongVehicleKind.okada:
        _okada(canvas, fill, stroke);
      case AlongVehicleKind.car:
        _car(canvas, fill, stroke);
      case AlongVehicleKind.danfo:
        _danfo(canvas, fill, stroke);
      case AlongVehicleKind.bus:
        _bus(canvas, fill, stroke);
    }
    canvas.restore();
  }

  void _wheel(Canvas canvas, Paint fill, Offset center, double radius) {
    canvas.drawCircle(center, radius, fill..color = ink);
    canvas.drawCircle(center, radius * 0.42, fill..color = surface);
  }

  void _keke(Canvas canvas, Paint fill, Paint stroke) {
    final canopy = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 8, 58, 30),
      const Radius.circular(12),
    );
    canvas.drawRRect(canopy, fill..color = accent);
    canvas.drawRRect(canopy, stroke);
    final cabin = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 28, 46, 20),
      const Radius.circular(5),
    );
    canvas.drawRRect(cabin, fill..color = surface);
    canvas.drawRRect(cabin, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 14, 20, 12),
        const Radius.circular(3),
      ),
      fill..color = glass,
    );
    _wheel(canvas, fill, const Offset(32, 56), 8);
    _wheel(canvas, fill, const Offset(58, 56), 8);
    _wheel(canvas, fill, const Offset(80, 50), 6);
  }

  void _okada(Canvas canvas, Paint fill, Paint stroke) {
    canvas.drawCircle(const Offset(24, 50), 12, stroke);
    canvas.drawCircle(const Offset(78, 50), 12, stroke);
    canvas.drawLine(const Offset(24, 50), const Offset(78, 50), stroke);
    canvas.drawLine(const Offset(36, 50), const Offset(48, 30), stroke);
    canvas.drawLine(const Offset(48, 30), const Offset(66, 30), stroke);
    canvas.drawLine(const Offset(66, 30), const Offset(78, 46), stroke);
    final seat = RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 32, 22, 8),
      const Radius.circular(3),
    );
    canvas.drawRRect(seat, fill..color = ink);
    canvas.drawCircle(const Offset(86, 34), 4, fill..color = accent);
  }

  void _car(Canvas canvas, Paint fill, Paint stroke) {
    final body = Path()
      ..moveTo(14, 48)
      ..lineTo(26, 48)
      ..lineTo(34, 34)
      ..lineTo(46, 26)
      ..lineTo(70, 26)
      ..lineTo(82, 36)
      ..lineTo(92, 36)
      ..lineTo(92, 48)
      ..lineTo(80, 48)
      ..close();
    canvas.drawPath(body, fill..color = surface);
    canvas.drawPath(body, stroke);
    final glassPath = Path()
      ..moveTo(40, 34)
      ..lineTo(48, 28)
      ..lineTo(68, 28)
      ..lineTo(76, 36)
      ..close();
    canvas.drawPath(glassPath, fill..color = glass);
    canvas.drawLine(const Offset(58, 28), const Offset(58, 36), stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 40, 10, 6),
        const Radius.circular(2),
      ),
      fill..color = accent,
    );
    _wheel(canvas, fill, const Offset(32, 50), 8);
    _wheel(canvas, fill, const Offset(74, 50), 8);
  }

  void _danfo(Canvas canvas, Paint fill, Paint stroke) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(6, 20, 88, 30),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, fill..color = surface);
    canvas.drawRRect(body, stroke);
    canvas.drawRect(const Rect.fromLTWH(6, 32, 88, 7), fill..color = accent);
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(14 + i * 18, 24, 12, 8),
          const Radius.circular(2),
        ),
        fill..color = glass,
      );
    }
    _wheel(canvas, fill, const Offset(24, 54), 8);
    _wheel(canvas, fill, const Offset(78, 54), 8);
  }

  void _bus(Canvas canvas, Paint fill, Paint stroke) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 12, 84, 40),
      const Radius.circular(8),
    );
    canvas.drawRRect(body, fill..color = surface);
    canvas.drawRRect(body, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14, 18, 16, 16),
        const Radius.circular(2),
      ),
      fill..color = glass,
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(36 + i * 16, 18, 12, 10),
          const Radius.circular(2),
        ),
        fill..color = glass,
      );
    }
    canvas.drawLine(const Offset(32, 18), const Offset(32, 52), stroke);
    _wheel(canvas, fill, const Offset(26, 56), 8);
    _wheel(canvas, fill, const Offset(74, 56), 8);
  }

  @override
  bool shouldRepaint(covariant _VehicleSidePainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.ink != ink ||
        oldDelegate.accent != accent ||
        oldDelegate.surface != surface;
  }
}
