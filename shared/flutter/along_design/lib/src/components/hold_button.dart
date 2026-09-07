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
    this.holdDuration,
    this.label,
  });

  final HoldButtonType type;
  final VoidCallback? onFired;
  final HoldButtonVisualState visualState;

  /// 0–1 radial progress while holding (defaults to 0.5 in holding state).
  final double? holdProgress;

  /// Hold duration — defaults to design token when null (doc 05 §9).
  final Duration? holdDuration;

  /// Optional override for accessibility label (e.g. "Hold to cancel").
  final String? label;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton>
    with SingleTickerProviderStateMixin {
  static const _defaultHoldDuration = Duration(milliseconds: 600);

  late AnimationController _controller;

  Duration get _holdDuration => widget.holdDuration ?? _defaultHoldDuration;

  bool get _isSos => widget.type == HoldButtonType.sos;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _holdDuration);
  }

  @override
  void didUpdateWidget(covariant HoldButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holdDuration != widget.holdDuration) {
      _controller.duration = _holdDuration;
    }
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
    final isHolding = widget.visualState == HoldButtonVisualState.holding ||
        (_displayProgress > 0 && widget.visualState == HoldButtonVisualState.idle);
    final isFired = widget.visualState == HoldButtonVisualState.fired;

    final bg = _isSos ? AlongColors.semanticDangerFill : AlongColors.ink900;
    final fg = AlongColors.surface0;
    final trackColor = _isSos
        ? (isHolding || isFired
            ? AlongColors.semanticDangerTint
            : bg.withValues(alpha: 0.25))
        : bg.withValues(alpha: 0.25);
    final progressColor = _isSos ? AlongColors.semanticDanger : bg;
    final label = widget.label ?? (_isSos ? 'Hold for SOS' : 'Na Me');
    final firedLabel = _isSos ? 'SOS sent' : 'Fired';
    final firedLabelColor =
        _isSos ? AlongColors.semanticDanger : AlongColors.ink700;

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
          height: AlongSpace.sizeCtaPrimary + AlongSpace.s24,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (_isSos && (isHolding || isFired))
                Container(
                  width: AlongSpace.sizeCtaPrimary + AlongSpace.s8,
                  height: AlongSpace.sizeCtaPrimary + AlongSpace.s8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AlongColors.semanticDangerTint,
                  ),
                ),
              CustomPaint(
                size: const Size.square(AlongSpace.sizeCtaPrimary),
                painter: _HoldProgressPainter(
                  progress: _displayProgress,
                  trackColor: trackColor,
                  progressColor: progressColor,
                ),
              ),
              Container(
                width: AlongSpace.s48,
                height: AlongSpace.s48,
                decoration: BoxDecoration(
                  color: isFired && _isSos
                      ? AlongColors.semanticDanger
                      : bg,
                  shape: BoxShape.circle,
                  border: isFired && _isSos
                      ? Border.all(color: AlongColors.semanticDangerFill, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  _isSos ? Icons.sos_rounded : Icons.flashlight_on_rounded,
                  color: fg,
                ),
              ),
              if (isFired)
                Positioned(
                  bottom: 0,
                  child: Text(
                    firedLabel,
                    style: AlongText.caption.copyWith(color: firedLabelColor),
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
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
