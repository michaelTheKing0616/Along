import 'dart:math' as math;

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import 'palette.dart';

/// Continuous corners, photo grade, grain, and the money lockup.
///
/// Cards, sheets, and buttons use [surface] (figma_squircle, smoothing 0.6).
/// Pills and circles stay round. [photoGrade] is the one grade for photographs.
abstract final class AlongCraft {
  static const smoothing = 0.6;

  static SmoothBorderRadius radius(double corner) {
    return SmoothBorderRadius(cornerRadius: corner, cornerSmoothing: smoothing);
  }

  static SmoothBorderRadius radiusVertical({
    double top = 0,
    double bottom = 0,
  }) {
    return SmoothBorderRadius.vertical(
      top: SmoothRadius(cornerRadius: top, cornerSmoothing: smoothing),
      bottom: SmoothRadius(cornerRadius: bottom, cornerSmoothing: smoothing),
    );
  }

  static SmoothRectangleBorder border(
    double corner, {
    BorderSide side = BorderSide.none,
  }) {
    return SmoothRectangleBorder(side: side, borderRadius: radius(corner));
  }

  static SmoothRectangleBorder borderVertical({
    double top = 28,
    BorderSide side = BorderSide.none,
  }) {
    return SmoothRectangleBorder(
      side: side,
      borderRadius: radiusVertical(top: top),
    );
  }

  static Path path(Rect rect, double corner) => radius(corner).toPath(rect);

  static ShapeDecoration surface(
    AlongPalette palette, {
    double radius = 16,
    Color? color,
    bool hairline = false,
    List<BoxShadow>? shadow,
    Gradient? gradient,
  }) {
    return ShapeDecoration(
      color: gradient == null ? (color ?? palette.surface) : null,
      gradient: gradient,
      shadows: shadow,
      shape: border(radius, side: hairline ? _hair(palette) : BorderSide.none),
    );
  }

  static BorderSide _hair(AlongPalette palette) {
    return BorderSide(color: palette.ink.withValues(alpha: 0.14), width: 0.5);
  }

  /// Two or three percent of lightness, top to bottom.
  static LinearGradient cta(Color color) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [shift(color, 0.03), shift(color, -0.02)],
    );
  }

  static Color shift(Color color, double lightness) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + lightness).clamp(0.0, 1.0))
        .toColor();
  }

  /// Warm, slightly lifted. One matrix for every photograph.
  static const ColorFilter photoGrade = ColorFilter.matrix(<double>[
    1.04,
    0.02,
    0.00,
    0,
    8,
    0.01,
    1.01,
    0.00,
    0,
    6,
    0.00,
    0.00,
    0.94,
    0,
    3,
    0,
    0,
    0,
    1,
    0,
  ]);
}

/// 1px top highlight and a faint bottom shade, clipped by the caller.
class AlongSheen extends StatelessWidget {
  const AlongSheen({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1,
            child: ColoredBox(color: Color(0x38FFFFFF)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 1,
            child: ColoredBox(color: Color(0x140E0F12)),
          ),
        ],
      ),
    );
  }
}

class AlongGrade extends StatelessWidget {
  const AlongGrade({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(colorFilter: AlongCraft.photoGrade, child: child);
  }
}

/// Film grain at about 2.5% so large gradients do not band. Deterministic.
class AlongNoise extends StatelessWidget {
  const AlongNoise({super.key, this.opacity = 0.025});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _NoisePainter(opacity),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const step = 3.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        final h = _hash(x.toInt(), y.toInt());
        if (h % 4 != 0) continue;
        final alpha = opacity * (0.45 + (h % 17) / 34);
        paint.color = Color.fromRGBO(20, 16, 12, alpha);
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
    }
  }

  static int _hash(int x, int y) {
    var n = x * 374761393 + y * 668265263;
    n = (n ^ (n >> 13)) * 1274126177;
    return n & 0x7fffffff;
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

/// Map dissolves into the sheet. Sits in the margin above the panel.
class AlongSheetFade extends StatelessWidget {
  const AlongSheetFade({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    final surface = AlongPalette.of(context).surface;
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                surface.withValues(alpha: 0),
                surface.withValues(alpha: 0.72),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet edge darkening so a full-bleed map does not end in a hard cut.
class AlongVignette extends StatelessWidget {
  const AlongVignette({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = AlongPalette.of(context).ink;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.08,
            colors: [const Color(0x00000000), ink.withValues(alpha: 0.045)],
            stops: const [0.68, 1],
          ),
        ),
      ),
    );
  }
}

/// Soft fade over a hard scroll clip. [color] is the surface underneath.
class AlongEdgeFade extends StatelessWidget {
  const AlongEdgeFade({super.key, required this.color, this.height = 20});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0), color],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero fare. The naira hangs off the digit block and sits on Inter.
class AlongMoney extends StatelessWidget {
  const AlongMoney({super.key, required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 32;
    final digits = _grouped(value.abs());
    final mark = style.copyWith(
      fontFamily: 'Inter',
      fontSize: size * 0.68,
      height: 1,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (value < 0) Text('−', maxLines: 1, softWrap: false, style: style),
        Transform.translate(
          offset: Offset(-1, -size * 0.04),
          child: Text('₦', maxLines: 1, softWrap: false, style: mark),
        ),
        Text(digits, maxLines: 1, softWrap: false, style: style),
      ],
    );
  }

  static String _grouped(int value) {
    final raw = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
      buf.write(raw[i]);
    }
    return buf.toString();
  }
}

enum AlongSpotKind { route, ticket, offline }

/// One illustration language: ink line, one yellow note, no stock set.
class AlongSpot extends StatelessWidget {
  const AlongSpot({super.key, required this.kind, this.size = 72});

  final AlongSpotKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpotPainter(kind: kind, palette: palette),
      ),
    );
  }
}

class _SpotPainter extends CustomPainter {
  const _SpotPainter({required this.kind, required this.palette});

  final AlongSpotKind kind;
  final AlongPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = palette.ink;
    final fill = Paint()..color = palette.accent;
    final s = size.shortestSide;
    canvas.drawCircle(Offset(s * 0.72, s * 0.28), s * 0.08, fill);
    switch (kind) {
      case AlongSpotKind.route:
        final path = Path()
          ..moveTo(s * 0.18, s * 0.72)
          ..quadraticBezierTo(s * 0.40, s * 0.22, s * 0.62, s * 0.48)
          ..quadraticBezierTo(s * 0.74, s * 0.62, s * 0.84, s * 0.36);
        canvas.drawPath(path, ink);
        canvas.drawCircle(
          Offset(s * 0.18, s * 0.72),
          3,
          ink..style = PaintingStyle.fill,
        );
        ink.style = PaintingStyle.stroke;
      case AlongSpotKind.ticket:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.16, s * 0.30, s * 0.68, s * 0.40),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, ink);
        canvas.drawLine(
          Offset(s * 0.28, s * 0.50),
          Offset(s * 0.70, s * 0.50),
          ink,
        );
      case AlongSpotKind.offline:
        canvas.drawArc(
          Rect.fromCircle(center: Offset(s * 0.50, s * 0.58), radius: s * 0.22),
          math.pi,
          math.pi,
          false,
          ink,
        );
        canvas.drawLine(
          Offset(s * 0.34, s * 0.36),
          Offset(s * 0.66, s * 0.68),
          ink,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}
