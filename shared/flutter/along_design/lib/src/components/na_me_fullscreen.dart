import 'dart:async';
import 'dart:math' as math;

import 'package:along_design/src/components/na_me_mapper.dart';
import 'package:along_design/src/tokens.g.dart';
import 'package:along_design/src/utils/name_signal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Timing for Na Me strobe cycles — sourced from app_config in each app.
class NaMeTimingConfig {
  const NaMeTimingConfig({
    required this.strobeInterval,
    required this.cycleDuration,
  });

  final Duration strobeInterval;
  final Duration cycleDuration;
}

/// Offline Na Me effects (doc 07 §9) — injectable per app.
abstract class NaMeEffects {
  Future<void> speak(String text);
  void hapticPulse();
}

class DefaultNaMeEffects implements NaMeEffects {
  @override
  Future<void> speak(String text) async {}

  @override
  void hapticPulse() => HapticFeedback.heavyImpact();
}

/// Shared fullscreen Na Me signal (R-12 / D-16) — zero network.
class NaMeFullscreen extends StatefulWidget {
  const NaMeFullscreen({
    super.key,
    required this.colorToken,
    required this.shapeToken,
    required this.label,
    required this.timing,
    required this.effects,
    this.bearingDegrees,
    this.onClose,
  });

  final String colorToken;
  final String shapeToken;
  final String label;
  final NaMeTimingConfig timing;
  final NaMeEffects effects;
  final double? bearingDegrees;
  final VoidCallback? onClose;

  @override
  State<NaMeFullscreen> createState() => _NaMeFullscreenState();
}

class _NaMeFullscreenState extends State<NaMeFullscreen> {
  Timer? _strobeTimer;
  Timer? _cycleTimer;
  Timer? _cycleEndTimer;
  bool _isStrobing = false;
  bool _strobeOn = true;
  int _cycleRemainingMs = 0;

  @override
  void dispose() {
    _disposeTimers();
    super.dispose();
  }

  void _disposeTimers() {
    _strobeTimer?.cancel();
    _cycleTimer?.cancel();
    _cycleEndTimer?.cancel();
    _strobeTimer = null;
    _cycleTimer = null;
    _cycleEndTimer = null;
  }

  void _triggerOnce() => _startStrobe(continuous: false);

  void _triggerHoldStart() => _startStrobe(continuous: true);

  void _triggerHoldEnd() {
    if (_cycleTimer == null) {
      _stopStrobe();
    }
  }

  void _startStrobe({required bool continuous}) {
    _disposeTimers();
    unawaited(widget.effects.speak('Along — ${widget.label}'));
    widget.effects.hapticPulse();

    setState(() {
      _isStrobing = true;
      _strobeOn = true;
      _cycleRemainingMs = widget.timing.cycleDuration.inMilliseconds;
    });

    _strobeTimer = Timer.periodic(widget.timing.strobeInterval, (_) {
      if (!mounted) return;
      setState(() => _strobeOn = !_strobeOn);
      widget.effects.hapticPulse();
    });

    _cycleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _cycleRemainingMs - 100;
      if (remaining <= 0) {
        timer.cancel();
        _stopStrobe();
        return;
      }
      setState(() => _cycleRemainingMs = remaining);
    });

    if (!continuous) {
      _cycleEndTimer = Timer(widget.timing.cycleDuration, _stopStrobe);
    }
  }

  void _stopStrobe() {
    _disposeTimers();
    if (!mounted) return;
    setState(() {
      _isStrobing = false;
      _strobeOn = true;
      _cycleRemainingMs = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colour = naMeColourFromToken(widget.colorToken);
    final shape = naMeShapeFromToken(widget.shapeToken);
    final fill = _isStrobing && _strobeOn ? colour.color : AlongColors.ink900;

    return Scaffold(
      backgroundColor: fill,
      body: SafeArea(
        child: GestureDetector(
          key: const Key('na_me_fullscreen'),
          onTap: _triggerOnce,
          onLongPressStart: (_) => _triggerHoldStart(),
          onLongPressEnd: (_) => _triggerHoldEnd(),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AlongColors.surface0),
                  onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.bearingDegrees != null)
                        Transform.rotate(
                          angle: widget.bearingDegrees! * math.pi / 180,
                          child: const Icon(
                            key: Key('na_me_compass_arrow'),
                            Icons.navigation_rounded,
                            color: AlongColors.surface0,
                            size: 48,
                          ),
                        ),
                      const SizedBox(height: AlongSpace.s24),
                      CustomPaint(
                        size: const Size.square(240),
                        painter: _NaMeShapeLarge(
                          shape: shape,
                          color: _isStrobing && !_strobeOn
                              ? AlongColors.ink900
                              : colour.color,
                        ),
                      ),
                      const SizedBox(height: AlongSpace.s16),
                      Text(
                        widget.label.toUpperCase(),
                        key: const Key('na_me_label'),
                        style: AlongText.displayL.copyWith(
                          color: AlongColors.surface0,
                        ),
                      ),
                      const SizedBox(height: AlongSpace.s8),
                      Text(
                        'Hold to strobe',
                        style: AlongText.caption.copyWith(
                          color: AlongColors.surface0.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isStrobing)
                Padding(
                  padding: const EdgeInsets.all(AlongSpace.s16),
                  child: Text(
                    key: const Key('na_me_strobing'),
                    'Signalling…',
                    style: AlongText.bodyStrong.copyWith(
                      color: AlongColors.surface0,
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

class _NaMeShapeLarge extends CustomPainter {
  _NaMeShapeLarge({required this.shape, required this.color});

  final NaMeShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    switch (shape) {
      case NaMeShape.circle:
        canvas.drawCircle(center, r, paint);
      case NaMeShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r, center.dy)
          ..close();
        canvas.drawPath(path, paint);
      default:
        canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NaMeShapeLarge oldDelegate) =>
      oldDelegate.color != color || oldDelegate.shape != shape;
}
