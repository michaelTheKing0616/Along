import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion.dart';
import '../palette.dart';
import '../type.dart';

/// Press-and-hold ring for emergency actions (SOS, call 112).
///
/// A brief tap does nothing, so a pocket press cannot fire it. The ring
/// fills while held; letting go early drains it. Haptics: a tick on press,
/// a confirm when it fires. Screen readers fire it with a long press.
class AlongHoldRing extends StatefulWidget {
  const AlongHoldRing({
    super.key,
    required this.label,
    required this.onFired,
    this.hint,
    this.size = 160,
    this.holdDuration = AlongDurations.sos,
    this.progress,
  });

  final String label;

  /// Screen-reader hint, e.g. "Hold to call".
  final String? hint;
  final VoidCallback? onFired;
  final double size;
  final Duration holdDuration;

  /// Fixed fill for goldens. Null means live.
  final double? progress;

  @override
  State<AlongHoldRing> createState() => _AlongHoldRingState();
}

class _AlongHoldRingState extends State<AlongHoldRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener(_onStatus);

  @override
  void didUpdateWidget(covariant AlongHoldRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fill.duration = widget.holdDuration;
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onFired != null;

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _fire();
  }

  void _fire() {
    AlongHaptics.confirm(context);
    widget.onFired?.call();
    _fill.value = 0;
  }

  void _down(PointerDownEvent _) {
    if (!_enabled) return;
    AlongHaptics.tick(context);
    _fill.forward(from: 0);
  }

  void _up(PointerEvent _) {
    if (_fill.isCompleted) return;
    // Drain quickly and without spring: under 300 ms, ease-out.
    _fill.animateBack(
      0,
      duration: AlongMotionPolicy.reduced(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      hint: widget.hint,
      onLongPress: _enabled ? _fire : null,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: AnimatedBuilder(
          animation: _fill,
          builder: (context, _) {
            return SizedBox.square(
              dimension: widget.size,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: widget.progress ?? _fill.value,
                  fill: _enabled ? palette.ink : palette.muted,
                  arc: palette.accent,
                  track: palette.onInk,
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.size * 0.18,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: AlongType.body(palette).copyWith(
                          color: palette.onInk,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.fill,
    required this.arc,
    required this.track,
  });

  final double progress;
  final Color fill;
  final Color arc;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 14;
    canvas.drawCircle(center, radius, Paint()..color = fill);
    final ring = Rect.fromCircle(center: center, radius: radius - 8);
    canvas.drawCircle(
      center,
      radius - 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = track.withValues(alpha: 0.22),
    );
    final p = progress.clamp(0.0, 1.0);
    if (p == 0) return;
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi * 2 * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.fill != fill || old.arc != arc;
}
