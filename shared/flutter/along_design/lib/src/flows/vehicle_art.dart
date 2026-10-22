import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../elevation.dart';

/// Shared vehicle set. Rows use one 3/4 studio angle. Map pins are top-down.
/// Lighting is the same on every vehicle: key light from the upper left,
/// ink or keke yellow body, one accent, glass highlight, ground shadow.
enum AlongVehicleKind { keke, okada, car, danfo, bus }

/// 3/4 product render. Same camera for every kind.
class AlongVehicleMark extends StatelessWidget {
  const AlongVehicleMark({
    super.key,
    required this.kind,
    this.width = 112,
    this.height,
  });

  final AlongVehicleKind kind;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? width * 9 / 16,
      child: CustomPaint(painter: _SidePainter(kind)),
    );
  }
}

/// Top-down marker. Nose points up before [heading] is applied.
/// The car shows a 2+2 cabin (four seats). Keke, okada, danfo, and bus
/// use the same light and palette.
class AlongTopDownMark extends StatelessWidget {
  const AlongTopDownMark({
    super.key,
    required this.kind,
    this.heading = 0,
    this.size = 36,
  });

  final AlongVehicleKind kind;
  final double heading;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, size * 0.08),
            child: Container(
              width: size * 0.46,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1F).withValues(alpha: 0.22),
                borderRadius: BorderRadius.all(Radius.elliptical(size, size)),
                boxShadow: AlongElevation.float(const Color(0xFF1C1C1F)),
              ),
            ),
          ),
          Transform.rotate(
            angle: heading,
            child: CustomPaint(
              size: Size.square(size),
              painter: _TopDownPainter(kind),
            ),
          ),
        ],
      ),
    );
  }
}

/// Studio colors. Fixed so a marker reads on both map themes.
abstract final class _Ink {
  static const hi = Color(0xFF3A3E46);
  static const mid = Color(0xFF1C1C1F);
  static const lo = Color(0xFF101114);
  static const accent = Color(0xFFF7D117);
  static const accentHi = Color(0xFFFFE978);
  static const accentLo = Color(0xFFC9A40C);
  static const glass = Color(0xFF8FA3B3);
  static const glassHi = Color(0xFFD7E6F0);
  static const glassLo = Color(0xFF5E7384);
  static const tire = Color(0xFF141416);
  static const rim = Color(0xFFE4E7EC);
  static const lamp = Color(0xFFF7F4E8);
}

class _SidePainter extends CustomPainter {
  _SidePainter(this.kind);

  final AlongVehicleKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final rig = _Iso(canvas, size);
    switch (kind) {
      case AlongVehicleKind.keke:
        rig.keke();
      case AlongVehicleKind.okada:
        rig.okada();
      case AlongVehicleKind.car:
        rig.car();
      case AlongVehicleKind.danfo:
        rig.danfo();
      case AlongVehicleKind.bus:
        rig.bus();
    }
  }

  @override
  bool shouldRepaint(covariant _SidePainter oldDelegate) =>
      oldDelegate.kind != kind;
}

/// One camera: front-left, slightly above. x runs to the rear, y to the
/// near side, z up. Every vehicle is built in this frame.
class _Iso {
  _Iso(Canvas canvas, Size size) : _canvas = canvas {
    // Vehicles sit in logical x 2..120 and y 28..76. Fit that box so the
    // body fills the widget instead of floating in the lower half.
    const left = 2.0;
    const top = 28.0;
    const contentW = 118.0;
    const contentH = 48.0;
    final sx = size.width / contentW;
    final sy = size.height / contentH;
    _scale = math.min(sx, sy);
    _ox = (size.width - contentW * _scale) / 2 - left * _scale;
    _oy = (size.height - contentH * _scale) / 2 - top * _scale;
  }

  final Canvas _canvas;
  late final double _scale;
  late final double _ox;
  late final double _oy;

  Offset p(double x, double y, double z) {
    return Offset(
      _ox + (6 + x + y * 0.52) * _scale,
      _oy + (64 - z * 0.92 + y * 0.34) * _scale,
    );
  }

  void face(List<(double, double, double)> pts, Color color) {
    final path = Path()
      ..moveTo(
        p(pts[0].$1, pts[0].$2, pts[0].$3).dx,
        p(pts[0].$1, pts[0].$2, pts[0].$3).dy,
      );
    for (final pt in pts.skip(1)) {
      final o = p(pt.$1, pt.$2, pt.$3);
      path.lineTo(o.dx, o.dy);
    }
    path.close();
    _canvas.drawPath(path, Paint()..color = color);
  }

  void shadow(double x0, double x1, double y0, double y1) {
    final a = p(x0, y0, 0);
    final b = p(x1, y1, 0);
    _canvas.drawOval(
      Rect.fromCenter(
        center: Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + 2 * _scale),
        width: (b.dx - a.dx).abs() * 0.92,
        height: math.max(6 * _scale, (b.dy - a.dy).abs() * 0.55),
      ),
      Paint()..color = const Color(0x330F1014),
    );
  }

  void wheel(double x, double y, {double r = 5.4}) {
    final c = p(x, y, 5);
    final radius = r * _scale * (1 + y * 0.004);
    _canvas.drawCircle(
      c.translate(0, 0.8 * _scale),
      radius,
      Paint()..color = _Ink.tire,
    );
    _canvas.drawCircle(
      c,
      radius * 0.62,
      Paint()..color = const Color(0xFF2C2E33),
    );
    _canvas.drawCircle(
      c.translate(-radius * 0.18, -radius * 0.2),
      radius * 0.28,
      Paint()..color = _Ink.rim,
    );
  }

  void streak(List<(double, double, double)> pts) {
    face(pts, const Color(0x55FFFFFF));
  }

  void car() {
    // 4-door sedan, 2+2. Nose at x = 0.
    shadow(2, 86, 0, 24);
    face([(2, 1, 7), (2, 23, 7), (2, 23, 18), (2, 1, 18)], _Ink.lo);
    face([(2, 23, 7), (84, 23, 7), (84, 23, 18), (2, 23, 18)], _Ink.mid);
    face([(2, 1, 18), (30, 1, 18), (30, 23, 18), (2, 23, 18)], _Ink.hi);
    face([(62, 1, 18), (84, 1, 18), (84, 23, 18), (62, 23, 18)], _Ink.hi);
    face([(30, 3, 18), (30, 21, 18), (30, 21, 33), (30, 3, 33)], _Ink.glassLo);
    face([(32, 23, 18), (60, 23, 18), (60, 23, 32), (32, 23, 32)], _Ink.glass);
    face([(32, 4, 33), (58, 4, 33), (58, 21, 33), (32, 21, 33)], _Ink.hi);
    streak([(34, 6, 32.2), (52, 6, 32.2), (50, 10, 31.2), (34, 10, 31.2)]);
    face([
      (2, 23, 15.5),
      (80, 23, 15.5),
      (80, 23, 17.2),
      (2, 23, 17.2),
    ], _Ink.accent);
    face([(4, 16, 14), (4, 21, 14), (4, 21, 16.5), (4, 16, 16.5)], _Ink.lamp);
    // Two door cuts on the near side: this is the 4-door.
    _seam(28, 23, 8, 17.5);
    _seam(48, 23, 8, 17.5);
    _seam(66, 23, 8, 17.5);
    face([
      (36, 23, 24),
      (46, 23, 24),
      (46, 23, 30),
      (36, 23, 30),
    ], _Ink.glassHi);
    wheel(16, 25);
    wheel(70, 25);
  }

  void keke() {
    shadow(8, 78, 0, 26);
    wheel(18, 12, r: 4.6);
    wheel(62, 26, r: 6.2);
    wheel(70, 6, r: 4.2);
    face([(28, 2, 8), (28, 24, 8), (28, 24, 28), (28, 2, 28)], _Ink.lo);
    face([(28, 24, 8), (76, 24, 8), (76, 24, 30), (28, 24, 30)], _Ink.accent);
    face([(30, 3, 30), (74, 3, 30), (74, 23, 30), (30, 23, 30)], _Ink.accentHi);
    face([(30, 4, 30), (30, 22, 30), (30, 22, 40), (30, 4, 40)], _Ink.glass);
    face([(32, 24, 30), (70, 24, 30), (70, 24, 42), (32, 24, 42)], _Ink.glass);
    face([(32, 5, 42), (68, 5, 42), (68, 22, 42), (32, 22, 42)], _Ink.mid);
    streak([(36, 8, 41), (58, 8, 41), (56, 12, 40), (36, 12, 40)]);
    face([(28, 24, 8), (22, 14, 6), (22, 14, 10), (28, 24, 12)], _Ink.lo);
    face([(36, 24, 16), (70, 24, 16), (70, 24, 18), (36, 24, 18)], _Ink.mid);
  }

  void okada() {
    shadow(6, 90, 4, 18);
    wheel(16, 14, r: 7.2);
    wheel(74, 14, r: 7.2);
    face([(20, 12, 8), (70, 12, 8), (70, 16, 12), (22, 16, 12)], _Ink.lo);
    face([(28, 10, 14), (48, 10, 16), (48, 18, 20), (28, 18, 18)], _Ink.accent);
    face([(46, 11, 16), (68, 11, 18), (66, 17, 22), (46, 17, 20)], _Ink.mid);
    streak([(32, 12, 18), (44, 12, 19), (42, 14, 18), (32, 14, 17)]);
    face([(12, 12, 16), (24, 10, 22), (26, 14, 22), (16, 16, 16)], _Ink.hi);
    face([(18, 14, 20), (30, 13, 24), (30, 15, 24), (20, 16, 20)], _Ink.rim);
    face([(62, 15, 10), (78, 16, 8), (78, 17, 9), (64, 16, 11)], _Ink.lo);
  }

  void danfo() {
    shadow(2, 92, 0, 26);
    wheel(18, 27, r: 6);
    wheel(74, 27, r: 6);
    face([(2, 1, 8), (2, 24, 8), (2, 24, 34), (2, 1, 34)], _Ink.accentLo);
    face([(2, 24, 8), (90, 24, 8), (90, 24, 36), (2, 24, 36)], _Ink.accent);
    face([(4, 2, 36), (88, 2, 36), (88, 23, 36), (4, 23, 36)], _Ink.accentHi);
    face([(8, 24, 22), (24, 24, 22), (24, 24, 32), (8, 24, 32)], _Ink.glass);
    face([(28, 24, 22), (44, 24, 22), (44, 24, 32), (28, 24, 32)], _Ink.glass);
    face([(48, 24, 22), (64, 24, 22), (64, 24, 32), (48, 24, 32)], _Ink.glass);
    face([
      (68, 24, 22),
      (82, 24, 22),
      (82, 24, 32),
      (68, 24, 32),
    ], _Ink.glassHi);
    streak([(10, 6, 35), (40, 6, 35), (38, 10, 34), (10, 10, 34)]);
    face([(2, 24, 12), (86, 24, 12), (86, 24, 15), (2, 24, 15)], _Ink.mid);
    face([(6, 18, 24), (6, 22, 24), (6, 22, 30), (6, 18, 30)], _Ink.lamp);
    _seam(26, 24, 10, 34);
    _seam(66, 24, 10, 34);
  }

  void bus() {
    shadow(0, 100, 0, 26);
    wheel(16, 27, r: 6.2);
    wheel(84, 27, r: 6.2);
    face([(0, 1, 8), (0, 24, 8), (0, 24, 32), (0, 1, 32)], _Ink.lo);
    face([(0, 24, 8), (98, 24, 8), (98, 24, 34), (0, 24, 34)], _Ink.mid);
    face([(2, 2, 34), (96, 2, 34), (96, 23, 34), (2, 23, 34)], _Ink.hi);
    for (var i = 0; i < 5; i++) {
      final x = 8.0 + i * 16;
      face([
        (x, 24, 20),
        (x + 12, 24, 20),
        (x + 12, 24, 30),
        (x, 24, 30),
      ], i == 4 ? _Ink.glassHi : _Ink.glass);
    }
    streak([(6, 5, 33), (36, 5, 33), (34, 9, 32), (6, 9, 32)]);
    face([(0, 24, 14), (94, 24, 14), (94, 24, 17), (0, 24, 17)], _Ink.accent);
    face([(2, 16, 22), (2, 22, 22), (2, 22, 28), (2, 16, 28)], _Ink.lamp);
    face([(4, 3, 28), (22, 3, 28), (22, 8, 32), (4, 8, 32)], _Ink.glassHi);
  }

  void _seam(double x, double y, double z0, double z1) {
    final a = p(x, y, z0);
    final b = p(x, y, z1);
    _canvas.drawLine(
      a,
      b,
      Paint()
        ..color = const Color(0x66101114)
        ..strokeWidth = math.max(1, _scale),
    );
  }
}

class _TopDownPainter extends CustomPainter {
  _TopDownPainter(this.kind);

  final AlongVehicleKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    canvas.save();
    canvas.scale(s, s);
    switch (kind) {
      case AlongVehicleKind.keke:
        _keke(canvas);
      case AlongVehicleKind.okada:
        _okada(canvas);
      case AlongVehicleKind.car:
        _car(canvas);
      case AlongVehicleKind.danfo:
        _coach(canvas, long: false);
      case AlongVehicleKind.bus:
        _coach(canvas, long: true);
    }
    canvas.restore();
  }

  void _body(Canvas canvas, RRect rect, Color top, Color edge) {
    canvas.drawRRect(
      rect.shift(const Offset(0.6, 0.8)),
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.outerRect.topLeft,
          rect.outerRect.bottomRight,
          [top, edge],
        ),
    );
  }

  void _glass(Canvas canvas, RRect rect) {
    canvas.drawRRect(rect, Paint()..color = _Ink.glass);
    final box = rect.outerRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          box.left + 1,
          box.top + 1,
          box.width * 0.45,
          box.height * 0.35,
        ),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0x88FFFFFF),
    );
  }

  void _wheel(Canvas canvas, Offset at) {
    canvas.drawCircle(at, 3.1, Paint()..color = _Ink.tire);
    canvas.drawCircle(at, 1.5, Paint()..color = const Color(0xFF3A3D44));
    canvas.drawCircle(
      at.translate(-0.4, -0.45),
      0.7,
      Paint()..color = _Ink.rim,
    );
  }

  void _car(Canvas canvas) {
    _wheel(canvas, const Offset(8, 10));
    _wheel(canvas, const Offset(32, 10));
    _wheel(canvas, const Offset(8, 31));
    _wheel(canvas, const Offset(32, 31));
    _body(
      canvas,
      RRect.fromLTRBR(10, 4, 30, 37, const Radius.circular(7)),
      _Ink.hi,
      _Ink.mid,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(12, 5.5, 28, 12, const Radius.circular(3)),
      Paint()..color = _Ink.lo,
    );
    _glass(
      canvas,
      RRect.fromLTRBR(12.5, 13, 27.5, 20, const Radius.circular(2)),
    );
    _glass(
      canvas,
      RRect.fromLTRBR(12.5, 24, 27.5, 31, const Radius.circular(2)),
    );
    // 2+2 headrests, so the cabin reads as four seats.
    for (final seat in const [
      Offset(16, 16.2),
      Offset(24, 16.2),
      Offset(16, 27),
      Offset(24, 27),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: seat, width: 4.2, height: 2.4),
          const Radius.circular(1),
        ),
        Paint()..color = const Color(0xFF2A2418),
      );
    }
    canvas.drawRRect(
      RRect.fromLTRBR(11.5, 20.4, 28.5, 23.2, const Radius.circular(1)),
      Paint()..color = _Ink.accent,
    );
    canvas.drawCircle(const Offset(14, 7.2), 1.1, Paint()..color = _Ink.lamp);
    canvas.drawCircle(const Offset(26, 7.2), 1.1, Paint()..color = _Ink.lamp);
  }

  void _keke(Canvas canvas) {
    _wheel(canvas, const Offset(20, 6.5));
    _wheel(canvas, const Offset(9, 33));
    _wheel(canvas, const Offset(31, 33));
    _body(
      canvas,
      RRect.fromLTRBR(10, 10, 30, 33, const Radius.circular(5)),
      _Ink.accentHi,
      _Ink.accent,
    );
    _glass(canvas, RRect.fromLTRBR(13, 13, 27, 20, const Radius.circular(2)));
    canvas.drawRRect(
      RRect.fromLTRBR(12, 24, 28, 31, const Radius.circular(2)),
      Paint()..color = _Ink.mid,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(14, 8, 26, 12, const Radius.circular(2)),
      Paint()..color = _Ink.lo,
    );
  }

  void _okada(Canvas canvas) {
    _wheel(canvas, const Offset(20, 7));
    _wheel(canvas, const Offset(20, 33));
    canvas.drawRRect(
      RRect.fromLTRBR(17, 10, 23, 30, const Radius.circular(3)),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(17, 10),
          const Offset(23, 30),
          [_Ink.hi, _Ink.mid],
        ),
    );
    canvas.drawOval(
      const Rect.fromLTWH(13.5, 15, 13, 10),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(14, 15),
          const Offset(26, 25),
          [_Ink.accentHi, _Ink.accentLo],
        ),
    );
    canvas.drawOval(
      const Rect.fromLTWH(16, 17, 5, 3),
      Paint()..color = const Color(0x66FFFFFF),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(16.5, 24, 23.5, 29, const Radius.circular(2)),
      Paint()..color = _Ink.lo,
    );
  }

  void _coach(Canvas canvas, {required bool long}) {
    final top = long ? 2.0 : 4.0;
    final bottom = long ? 38.0 : 36.0;
    _wheel(canvas, Offset(9, top + 8));
    _wheel(canvas, Offset(31, top + 8));
    _wheel(canvas, Offset(9, bottom - 6));
    _wheel(canvas, Offset(31, bottom - 6));
    _body(
      canvas,
      RRect.fromLTRBR(10, top, 30, bottom, const Radius.circular(5)),
      long ? _Ink.hi : _Ink.accentHi,
      long ? _Ink.mid : _Ink.accent,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        17.2,
        top + 3,
        22.8,
        bottom - 3,
        const Radius.circular(1.5),
      ),
      Paint()..color = long ? _Ink.accent : _Ink.mid,
    );
    final windows = long ? 5 : 4;
    final span = bottom - top - 12;
    for (var i = 0; i < windows; i++) {
      final y = top + 6 + span * i / windows;
      _glass(
        canvas,
        RRect.fromLTRBR(12, y, 16.2, y + 3.4, const Radius.circular(1)),
      );
      _glass(
        canvas,
        RRect.fromLTRBR(23.8, y, 28, y + 3.4, const Radius.circular(1)),
      );
    }
    canvas.drawCircle(Offset(16, top + 2.2), 0.9, Paint()..color = _Ink.lamp);
    canvas.drawCircle(Offset(24, top + 2.2), 0.9, Paint()..color = _Ink.lamp);
  }

  @override
  bool shouldRepaint(covariant _TopDownPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

/// Heading from one map fraction toward the next. Zero points up.
double alongHeading(Offset from, Offset to) {
  return math.atan2(to.dx - from.dx, -(to.dy - from.dy));
}
