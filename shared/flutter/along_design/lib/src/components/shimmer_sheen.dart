import 'package:flutter/widgets.dart';

import '../craft.dart';
import '../palette.dart';

/// A faint diagonal light band that drifts across a hero card as the page
/// scrolls, like a polished surface catching the room light.
///
/// Dark mode only. It paints one static gradient on the foreground layer and
/// repaints only that layer from the scroll position, so it never rebuilds
/// the card. It is off under reduce-motion. Peak alpha is 5% and travel is
/// tied to the finger, never to a timer, so it cannot flash.
class AlongShimmer extends StatefulWidget {
  const AlongShimmer({
    super.key,
    required this.child,
    this.corner = 16,
    this.rim = false,
  });

  final Widget child;
  final double corner;

  /// Also paint the specular rim, for heroes that bring their own fill.
  final bool rim;

  @override
  State<AlongShimmer> createState() => _AlongShimmerState();
}

class _AlongShimmerState extends State<AlongShimmer> {
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position = Scrollable.maybeOf(context)?.position;
  }

  @override
  Widget build(BuildContext context) {
    final dark = AlongPalette.of(context).brightness == Brightness.dark;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!dark) return widget.child;
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _SheenPainter(
          position: still ? null : _position,
          corner: widget.corner,
          rim: widget.rim,
        ),
        child: widget.child,
      ),
    );
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter({this.position, required this.corner, required this.rim})
    : super(repaint: position);

  final ScrollPosition? position;
  final double corner;
  final bool rim;

  @override
  void paint(Canvas canvas, Size size) {
    final pixels = position?.hasPixels == true ? position!.pixels : 0.0;
    // Band centre walks from -0.2 to 1.2 across 600 px of scroll.
    final t = (-0.2 + (pixels % 600) / 600 * 1.4);
    const white = Color(0xFFFFFFFF);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [
        (t - 0.18).clamp(0.0, 1.0),
        t.clamp(0.0, 1.0),
        (t + 0.18).clamp(0.0, 1.0),
      ],
      colors: [
        white.withValues(alpha: 0),
        white.withValues(alpha: 0.05),
        white.withValues(alpha: 0),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawPath(
      AlongCraft.path(Offset.zero & size, corner),
      Paint()..shader = shader,
    );
    if (rim) {
      AlongSpecularBorder(AlongCraft.border(corner))
          .paint(canvas, Offset.zero & size);
    }
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.position != position;
}
