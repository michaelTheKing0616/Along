import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../elevation.dart';
import '../palette.dart';

/// Shared vehicle set. Cards use one studio product render. Map pins are top-down.
enum AlongVehicleKind { keke, okada, car, danfo, bus }

/// Side product shot. Same camera and lighting for every vehicle.
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

  static const _asset = <AlongVehicleKind, String>{
    AlongVehicleKind.keke: 'assets/vehicles/keke_product.png',
    AlongVehicleKind.okada: 'assets/vehicles/okada_product.png',
    AlongVehicleKind.car: 'assets/vehicles/car_product.png',
    AlongVehicleKind.danfo: 'assets/vehicles/danfo_product.png',
    AlongVehicleKind.bus: 'assets/vehicles/bus_product.png',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? width * 9 / 16,
      child: Image.asset(
        _asset[kind]!,
        package: 'along_design',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Crisp top-down marker. Nose points up before [heading] is applied.
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
    final palette = AlongPalette.of(context);
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
                color: palette.ink.withValues(alpha: 0.22),
                borderRadius: BorderRadius.all(Radius.elliptical(size, size)),
                boxShadow: AlongElevation.float(palette.ink),
              ),
            ),
          ),
          Transform.rotate(
            angle: heading,
            child: CustomPaint(
              size: Size.square(size),
              painter: _TopDownPainter(
                kind: kind,
                ink: palette.ink,
                accent: palette.accent,
                glass: palette.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopDownPainter extends CustomPainter {
  _TopDownPainter({
    required this.kind,
    required this.ink,
    required this.accent,
    required this.glass,
  });

  final AlongVehicleKind kind;
  final Color ink;
  final Color accent;
  final Color glass;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    canvas.save();
    canvas.scale(s, s);
    final fill = Paint()..style = PaintingStyle.fill;
    switch (kind) {
      case AlongVehicleKind.keke:
        _keke(canvas, fill);
      case AlongVehicleKind.okada:
        _okada(canvas, fill);
      case AlongVehicleKind.car:
        _car(canvas, fill);
      case AlongVehicleKind.danfo:
        _van(canvas, fill, long: false);
      case AlongVehicleKind.bus:
        _van(canvas, fill, long: true);
    }
    canvas.restore();
  }

  void _car(Canvas canvas, Paint fill) {
    canvas.drawRRect(
      RRect.fromLTRBR(11, 3, 29, 37, const Radius.circular(8)),
      fill..color = ink,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(13.5, 9, 26.5, 17, const Radius.circular(3)),
      fill..color = glass,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(13.5, 24, 26.5, 31, const Radius.circular(2)),
      fill..color = glass.withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(12, 18.5, 28, 21.5, const Radius.circular(1)),
      fill..color = accent,
    );
  }

  void _keke(Canvas canvas, Paint fill) {
    canvas.drawCircle(const Offset(20, 7), 3.2, fill..color = ink);
    canvas.drawCircle(const Offset(9, 33), 3.4, fill..color = ink);
    canvas.drawCircle(const Offset(31, 33), 3.4, fill..color = ink);
    canvas.drawRRect(
      RRect.fromLTRBR(10, 12, 30, 32, const Radius.circular(6)),
      fill..color = accent,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(13, 16, 27, 24, const Radius.circular(3)),
      fill..color = glass,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(12, 26, 28, 34, const Radius.circular(3)),
      fill..color = ink,
    );
  }

  void _okada(Canvas canvas, Paint fill) {
    canvas.drawCircle(const Offset(20, 8), 4.2, fill..color = ink);
    canvas.drawCircle(const Offset(20, 8), 2.1, fill..color = glass);
    canvas.drawCircle(const Offset(20, 32), 4.4, fill..color = ink);
    canvas.drawCircle(const Offset(20, 32), 2.2, fill..color = glass);
    canvas.drawRRect(
      RRect.fromLTRBR(16.5, 10, 23.5, 30, const Radius.circular(3)),
      fill..color = ink,
    );
    canvas.drawOval(const Rect.fromLTWH(14, 16, 12, 10), fill..color = accent);
  }

  void _van(Canvas canvas, Paint fill, {required bool long}) {
    final top = long ? 2.0 : 4.0;
    final bottom = long ? 38.0 : 36.0;
    canvas.drawRRect(
      RRect.fromLTRBR(9, top, 31, bottom, const Radius.circular(6)),
      fill..color = ink,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        17.5,
        top + 3,
        22.5,
        bottom - 3,
        const Radius.circular(2),
      ),
      fill..color = accent,
    );
    final windows = long ? 5 : 4;
    final span = bottom - top - 12;
    for (var i = 0; i < windows; i++) {
      final y = top + 6 + span * i / windows;
      canvas.drawRRect(
        RRect.fromLTRBR(11.5, y, 16.2, y + 3.2, const Radius.circular(1)),
        fill..color = glass,
      );
      canvas.drawRRect(
        RRect.fromLTRBR(23.8, y, 28.5, y + 3.2, const Radius.circular(1)),
        fill..color = glass,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TopDownPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.ink != ink ||
        oldDelegate.accent != accent;
  }
}

/// Heading from one map fraction toward the next. Zero points up.
double alongHeading(Offset from, Offset to) {
  return math.atan2(to.dx - from.dx, -(to.dy - from.dy));
}
