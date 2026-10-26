import 'package:flutter/material.dart';

import '../motion.dart';
import '../palette.dart';
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
  static const _defaultHoldDuration = AlongDurations.sos;

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
    final p = AlongPalette.of(context);
    final dark = p.brightness == Brightness.dark;
    final isHolding =
        widget.visualState == HoldButtonVisualState.holding ||
        (_displayProgress > 0 &&
            widget.visualState == HoldButtonVisualState.idle);
    final isFired = widget.visualState == HoldButtonVisualState.fired;
    final danger = dark ? const Color(0xFFF87171) : AlongColors.semanticDanger;
    final dangerTint = dark
        ? const Color(0xFF3A1818)
        : AlongColors.semanticDangerTint;

    // SOS is a quiet squircle with a red word until it is held: reachable,
    // never shouting over the trip. Na Me is an ink tile with a torch.
    final Color bg = _isSos
        ? (isFired ? AlongColors.semanticDangerFill : dangerTint)
        : p.ink;
    final Color fg = _isSos ? (isFired ? Colors.white : danger) : p.onInk;
    final label = widget.label ?? (_isSos ? 'Hold for SOS' : 'Na Me');
    final firedLabel = _isSos ? 'Call 112' : 'Fired';
    const tile = AlongSpace.s48;
    const frame = tile + 8;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: frame,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isSos && (isHolding || isFired))
                    CustomPaint(
                      size: const Size.square(frame),
                      painter: _HoldProgressPainter(
                        progress: _displayProgress,
                        trackColor: danger.withValues(alpha: 0.2),
                        progressColor: danger,
                      ),
                    ),
                  Container(
                    width: tile,
                    height: tile,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: bg,
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: _isSos && !isFired
                            ? BorderSide(color: danger.withValues(alpha: 0.35))
                            : BorderSide.none,
                      ),
                    ),
                    child: _isSos
                        ? Text(
                            'SOS',
                            style: AlongText.caption.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          )
                        : Icon(
                            Icons.flashlight_on_rounded,
                            color: fg,
                            size: 22,
                          ),
                  ),
                ],
              ),
            ),
            if (isFired)
              Text(
                firedLabel,
                style: AlongText.caption.copyWith(
                  color: _isSos ? danger : p.muted,
                ),
              ),
          ],
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
    final rect = (Offset.zero & size).deflate(2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(19)));
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final arc = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, track);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress.clamp(0, 1)),
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _HoldProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
