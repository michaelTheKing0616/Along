import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// Hold-to-fire button types (doc 05 §9 `HoldButton`).
enum HoldButtonType { sos, naMe }

/// Snapshot states for golden tests.
enum HoldButtonVisualState { idle, holding, fired }

/// Hold-to-fire button — SOS requires hold; Na Me fires on tap or hold.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    this.type = HoldButtonType.sos,
    this.onFired,
    this.visualState = HoldButtonVisualState.idle,
    this.holdProgress,
  });

  final HoldButtonType type;
  final VoidCallback? onFired;
  final HoldButtonVisualState visualState;

  /// 0–1 radial progress while holding (defaults to 0.5 in holding state).
  final double? holdProgress;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton>
    with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(milliseconds: 600);

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _holdDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.type == HoldButtonType.naMe) {
      widget.onFired?.call();
      return;
    }
    _controller.forward(from: 0);
  }

  void _onTapUp(TapUpDetails _) => _controller.stop();

  void _onTapCancel() => _controller.stop();

  void _onLongPressEnd(LongPressEndDetails _) {
    if (_controller.value >= 1) {
      widget.onFired?.call();
    }
    _controller.reset();
  }

  double get _displayProgress {
    if (widget.visualState == HoldButtonVisualState.holding) {
      return widget.holdProgress ?? 0.5;
    }
    if (widget.visualState == HoldButtonVisualState.fired) {
      return 1;
    }
    return _controller.value;
  }

  @override
  Widget build(BuildContext context) {
    final isSos = widget.type == HoldButtonType.sos;
    final bg = isSos ? AlongColors.semanticDangerFill : AlongColors.ink900;
    final fg = AlongColors.surface0;
    final label = isSos ? 'Hold for SOS' : 'Na Me';

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTapDown: widget.visualState == HoldButtonVisualState.idle
            ? _onTapDown
            : null,
        onTapUp: widget.visualState == HoldButtonVisualState.idle
            ? _onTapUp
            : null,
        onTapCancel: widget.visualState == HoldButtonVisualState.idle
            ? _onTapCancel
            : null,
        onLongPressEnd: widget.visualState == HoldButtonVisualState.idle
            ? _onLongPressEnd
            : null,
        child: SizedBox(
          width: AlongSpace.sizeCtaPrimary,
          height: AlongSpace.sizeCtaPrimary,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(AlongSpace.sizeCtaPrimary),
                painter: _HoldProgressPainter(
                  progress: _displayProgress,
                  trackColor: bg.withValues(alpha: 0.25),
                  progressColor: bg,
                ),
              ),
              Container(
                width: AlongSpace.s48,
                height: AlongSpace.s48,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(
                  isSos ? Icons.sos_rounded : Icons.flashlight_on_rounded,
                  color: fg,
                ),
              ),
              if (widget.visualState == HoldButtonVisualState.fired)
                Positioned(
                  bottom: -AlongSpace.s20,
                  child: Text(
                    'Fired',
                    style: AlongText.caption.copyWith(
                      color: AlongColors.semanticDanger,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoldProgressPainter extends CustomPainter {
  _HoldProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final arc = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _HoldProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
