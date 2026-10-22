import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../elevation.dart';
import '../motion.dart';
import '../palette.dart';

/// Physics sheet. Resting height is either a fixed dp or a fraction of the
/// parent. Tests and reduced motion jump to rest so layout stays stable.
/// The entrance itself is a short spring, interruptible by a new snap. [emil]
class AlongSpringSheet extends StatefulWidget {
  const AlongSpringSheet({
    super.key,
    required this.child,
    this.restingHeight,
    this.fraction,
    this.title,
  }) : assert(restingHeight != null || fraction != null);

  final Widget child;
  final double? restingHeight;
  final double? fraction;
  final String? title;

  @override
  State<AlongSpringSheet> createState() => _AlongSpringSheetState();
}

class _AlongSpringSheetState extends State<AlongSpringSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    final skip = AlongMotionPolicy.inWidgetTest;
    _motion = AnimationController.unbounded(vsync: this, value: skip ? 1 : 0);
    if (!skip) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _springTo(1));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AlongMotionPolicy.reduced(context)) {
      _motion.value = 1;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _springTo(double target) {
    if (!mounted) return;
    if (AlongMotionPolicy.reduced(context) || AlongMotionPolicy.inWidgetTest) {
      _motion.value = target;
      return;
    }
    _motion.animateWith(
      SpringSimulation(AlongSprings.sheet, _motion.value, target, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final rest =
            widget.restingHeight ??
            constraints.maxHeight * (widget.fraction ?? 0.42);
        return AnimatedBuilder(
          animation: _motion,
          builder: (context, _) {
            final t = _motion.value.clamp(0.0, 1.15);
            final height = rest * (0.90 + 0.10 * t.clamp(0.0, 1.0));
            final reduce = AlongMotionPolicy.reduced(context);
            final veil = reduce
                ? palette.surface
                : palette.surface.withValues(alpha: 0.90);
            return Align(
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: AlongElevation.sheet(palette.ink),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: reduce ? 0 : 16,
                      sigmaY: reduce ? 0 : 16,
                    ),
                    child: ColoredBox(
                      color: veil,
                      child: SizedBox(
                        height: height,
                        width: double.infinity,
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: palette.ink.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            if (widget.title != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    widget.title!,
                                    style: TextStyle(
                                      fontFamily: palette.fontFamily,
                                      fontFamilyFallback: const ['Inter'],
                                      fontSize: 20,
                                      height: 1.25,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.4,
                                      color: palette.ink,
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  12,
                                ),
                                child: widget.child,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
