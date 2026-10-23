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
    this.snaps,
    this.title,
  }) : assert(restingHeight != null || fraction != null || snaps != null);

  final Widget child;
  final double? restingHeight;
  final double? fraction;

  /// Resting fractions, collapsed first. A flick on the handle moves one snap.
  /// Tests and the gallery stay on the first snap.
  final List<double>? snaps;
  final String? title;

  @override
  State<AlongSpringSheet> createState() => _AlongSpringSheetState();
}

class _AlongSpringSheetState extends State<AlongSpringSheet>
    with TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _lift;

  @override
  void initState() {
    super.initState();
    final skip = AlongMotionPolicy.inWidgetTest;
    _motion = AnimationController.unbounded(vsync: this, value: skip ? 1 : 0);
    _lift = AnimationController.unbounded(vsync: this, value: 0)
      ..addListener(_reportExtent);
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
    _lift.removeListener(_reportExtent);
    _lift.dispose();
    _motion.dispose();
    super.dispose();
  }

  void _reportExtent() {
    final scope = AlongMapMotion.maybeOf(context);
    if (scope == null) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final maxH = box.size.height;
    final snaps = widget.snaps;
    final maxExtra = (snaps != null && snaps.length > 1)
        ? maxH * (snaps.last - snaps.first)
        : maxH * 0.2;
    final extent = maxExtra <= 0
        ? 0.0
        : (_lift.value / maxExtra).clamp(0.0, 1.0);
    scope.setExtent(extent);
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
        final snaps = widget.snaps;
        final baseFraction = (snaps != null && snaps.isNotEmpty)
            ? snaps.first
            : widget.fraction;
        final rest =
            widget.restingHeight ??
            constraints.maxHeight * (baseFraction ?? 0.42);
        final maxExtra = (snaps != null && snaps.length > 1)
            ? constraints.maxHeight * (snaps.last - snaps.first)
            : 0.0;
        return AnimatedBuilder(
          animation: Listenable.merge([_motion, _lift]),
          builder: (context, _) {
            final t = _motion.value.clamp(0.0, 1.15);
            final lifted =
                rest * (0.90 + 0.10 * t.clamp(0.0, 1.0)) + _lift.value;
            final height = lifted.clamp(96.0, constraints.maxHeight);
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
                        key: const Key('sheet_panel'),
                        height: height,
                        width: double.infinity,
                        child: Column(
                          children: [
                            GestureDetector(
                              key: const Key('sheet_handle'),
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragUpdate: (details) {
                                var delta = -details.delta.dy;
                                final next = _lift.value + delta;
                                if (next < 0 || next > maxExtra) delta *= 0.22;
                                _lift.value += delta;
                              },
                              onVerticalDragEnd: (details) {
                                final velocity =
                                    -(details.primaryVelocity ?? 0);
                                var target = 0.0;
                                if (maxExtra > 0) {
                                  if (velocity > 700) {
                                    target = maxExtra;
                                  } else if (velocity < -700) {
                                    target = 0;
                                  } else {
                                    target = _lift.value > maxExtra / 2
                                        ? maxExtra
                                        : 0;
                                  }
                                }
                                if (!AlongMotionPolicy.play(context)) {
                                  _lift.value = target;
                                  return;
                                }
                                _lift.animateWith(
                                  SpringSimulation(
                                    AlongSprings.sheet,
                                    _lift.value,
                                    target,
                                    velocity,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Center(
                                  child: Container(
                                    width: 36,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: palette.ink.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
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

/// Shares how far a map sheet has risen so the map can dim and parallax.
class AlongMapMotion extends StatefulWidget {
  const AlongMapMotion({super.key, required this.builder});

  final Widget Function(BuildContext context, double extent) builder;

  static _AlongMapMotionState? maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<_AlongMapScope>()?.state;
  }

  @override
  State<AlongMapMotion> createState() => _AlongMapMotionState();
}

class _AlongMapMotionState extends State<AlongMapMotion> {
  double _extent = 0;

  void setExtent(double value) {
    final next = value.clamp(0.0, 1.0);
    if ((next - _extent).abs() < 0.004) return;
    setState(() => _extent = next);
  }

  @override
  Widget build(BuildContext context) {
    return _AlongMapScope(state: this, child: widget.builder(context, _extent));
  }
}

class _AlongMapScope extends InheritedWidget {
  const _AlongMapScope({required this.state, required super.child});

  final _AlongMapMotionState state;

  @override
  bool updateShouldNotify(covariant _AlongMapScope oldWidget) =>
      oldWidget.state._extent != state._extent;
}
