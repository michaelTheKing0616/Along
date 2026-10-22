import 'package:flutter/material.dart';

import '../palette.dart';

/// Original geometric portrait. Not a photograph of a real person.
class AlongDriverPortrait extends StatelessWidget {
  const AlongDriverPortrait({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PortraitPainter(
          ink: palette.ink,
          accent: palette.accent,
          surface: palette.surface,
        ),
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter({
    required this.ink,
    required this.accent,
    required this.surface,
  });

  final Color ink;
  final Color accent;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;
    canvas.save();
    canvas.scale(s, s);
    final fill = Paint()..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(32, 32),
      32,
      fill..color = const Color(0xFFE7D3C0),
    );
    canvas.drawCircle(
      const Offset(32, 28),
      16,
      fill..color = const Color(0xFFC48862),
    );
    final hair = Path()
      ..moveTo(16, 28)
      ..quadraticBezierTo(18, 8, 32, 8)
      ..quadraticBezierTo(48, 8, 48, 28)
      ..quadraticBezierTo(40, 18, 32, 18)
      ..quadraticBezierTo(22, 18, 16, 28)
      ..close();
    canvas.drawPath(hair, fill..color = ink);
    canvas.drawCircle(const Offset(26, 28), 1.6, fill..color = ink);
    canvas.drawCircle(const Offset(38, 28), 1.6, fill..color = ink);
    canvas.drawArc(
      const Rect.fromLTWH(27, 32, 10, 6),
      0.2,
      2.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = ink
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRect(const Rect.fromLTWH(0, 46, 64, 18), fill..color = ink);
    canvas.drawRect(const Rect.fromLTWH(26, 46, 12, 8), fill..color = accent);
    canvas.restore();
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = surface,
    );
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter oldDelegate) {
    return oldDelegate.ink != ink || oldDelegate.accent != accent;
  }
}
