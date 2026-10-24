import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../craft.dart';
import '../elevation.dart';
import '../motion.dart';
import '../palette.dart';
import '../tokens.g.dart';

/// Bottom sheet snap sizes (doc 05 §9 `BottomSheet`).
enum AlongBottomSheetSize { collapsed, half, full }

/// Along bottom sheet shell. Snap heights stay fixed. The entrance is a
/// short spring (skipped in tests and when motion is reduced). [emil]
class AlongBottomSheet extends StatefulWidget {
  const AlongBottomSheet({
    super.key,
    required this.child,
    this.size = AlongBottomSheetSize.half,
    this.title,
  });

  final Widget child;
  final AlongBottomSheetSize size;
  final String? title;

  @override
  State<AlongBottomSheet> createState() => _AlongBottomSheetState();
}

class _AlongBottomSheetState extends State<AlongBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  double _heightFactor() => switch (widget.size) {
    AlongBottomSheetSize.collapsed => 168 / 640,
    AlongBottomSheetSize.half => 0.5,
    AlongBottomSheetSize.full => 0.92,
  };

  @override
  void initState() {
    super.initState();
    final skip = AlongMotionPolicy.inWidgetTest;
    _motion = AnimationController.unbounded(vsync: this, value: skip ? 1 : 0);
    if (!skip) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (AlongMotionPolicy.reduced(context)) {
          _motion.value = 1;
          return;
        }
        _motion.animateWith(
          SpringSimulation(AlongSprings.sheet, _motion.value, 1, 0),
        );
      });
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

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, _) {
        final travel = (1 - _motion.value.clamp(0.0, 1.0)) * 16;
        return Transform.translate(
          offset: Offset(0, travel),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: AlongCraft.fill(
                palette.surface,
                corner: AlongRadius.sheet.x,
                shadow: AlongElevation.sheet(palette.ink),
                top: true,
              ),
              child: AlongCraft.clip(
                corner: AlongRadius.sheet.x,
                top: true,
                child: SizedBox(
                  height: 640 * _heightFactor(),
                  width: double.infinity,
                  child: Column(
                  children: [
                    const SizedBox(height: AlongSpace.s8),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: AlongCraft.fill(
                        palette.line,
                        corner: AlongRadius.xs.x,
                      ),
                    ),
                    if (widget.title != null)
                      Padding(
                        padding: const EdgeInsets.all(AlongSpace.s16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.title!,
                            style: AlongText.heading2.copyWith(
                              color: palette.ink,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: widget.size == AlongBottomSheetSize.full
                          ? SingleChildScrollView(
                              primary: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AlongSpace.s16,
                              ),
                              child: widget.child,
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AlongSpace.s16,
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
        );
      },
    );
  }
}
