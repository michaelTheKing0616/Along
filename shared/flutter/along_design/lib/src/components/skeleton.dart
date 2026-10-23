import 'package:flutter/material.dart';

import '../craft.dart';
import '../motion.dart';
import '../palette.dart';
import '../tokens.g.dart';

/// Skeleton placeholder variants (doc 05 §9 `Skeleton`).
enum SkeletonVariant { line, card, mapOverlay }

/// Shimmer skeleton for network waits > 300 ms.
class AlongSkeleton extends StatefulWidget {
  const AlongSkeleton({
    super.key,
    this.variant = SkeletonVariant.line,
    this.width,
    this.height,
  });

  final SkeletonVariant variant;
  final double? width;
  final double? height;

  @override
  State<AlongSkeleton> createState() => _AlongSkeletonState();
}

class _AlongSkeletonState extends State<AlongSkeleton>
    with SingleTickerProviderStateMixin {
  static const _shimmerDuration = Duration(milliseconds: 1200);

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _shimmerDuration,
      value: 0.42,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = AlongMotionPolicy.reduced(context);
    final play = AlongMotionPolicy.play(context) && !reduced;
    if (play) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = reduced ? 0 : 0.42;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bone(
    AlongPalette palette,
    double width,
    double height,
    double radius,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: AlongCraft.surface(
        palette,
        radius: radius,
        color: palette.recessed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final child = switch (widget.variant) {
      SkeletonVariant.line => _bone(
        palette,
        widget.width ?? double.infinity,
        widget.height ?? AlongSpace.s16,
        AlongRadius.xs.x,
      ),
      SkeletonVariant.card => _bone(
        palette,
        widget.width ?? double.infinity,
        widget.height ?? 120,
        AlongRadius.lg.x,
      ),
      SkeletonVariant.mapOverlay => _bone(
        palette,
        widget.width ?? 120,
        widget.height ?? 36,
        AlongRadius.sm.x,
      ),
    };

    if (AlongMotionPolicy.reduced(context)) return child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final highlight = Color.alphaBlend(
          const Color(0x66FFFFFF),
          palette.surface,
        );
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.2 + 2.4 * t, 0),
              end: Alignment(-0.15 + 2.4 * t, 0),
              colors: [palette.recessed, highlight, palette.recessed],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}
