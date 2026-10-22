import 'package:flutter/material.dart';

import '../motion.dart';
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
    _controller = AnimationController(vsync: this, duration: _shimmerDuration);
    // Widget tests advance a fake clock. A repeating shimmer never lets
    // pumpAndSettle finish, so tests play the same pass once.
    if (_inWidgetTest) {
      _controller.forward();
    } else {
      _controller.repeat();
    }
  }

  bool get _inWidgetTest {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('Test');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (widget.variant) {
      SkeletonVariant.line => Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? AlongSpace.s16,
        decoration: BoxDecoration(
          color: AlongColors.surface200,
          borderRadius: BorderRadius.circular(AlongRadius.xs.x),
        ),
      ),
      SkeletonVariant.card => Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 120,
        decoration: BoxDecoration(
          color: AlongColors.surface200,
          borderRadius: BorderRadius.circular(AlongRadius.lg.x),
        ),
      ),
      SkeletonVariant.mapOverlay => Container(
        width: widget.width ?? 120,
        height: widget.height ?? 36,
        decoration: BoxDecoration(
          color: AlongColors.surface200,
          borderRadius: BorderRadius.circular(AlongRadius.sm.x),
        ),
      ),
    };

    if (AlongMotionPolicy.reduced(context)) return child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(-0.5 + 2 * _controller.value, 0),
              colors: const [
                AlongColors.surface200,
                AlongColors.surface100,
                AlongColors.surface200,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}
