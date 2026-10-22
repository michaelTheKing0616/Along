import 'dart:async';
import 'dart:math' as math;

import 'package:along_design/src/components/na_me_mapper.dart';
import 'package:along_design/src/components/na_me_shape_painter.dart';
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

/// Snapshot states for golden tests (doc 05 §9 `NaMeScreen`).
enum NaMeFullscreenVisualState { idle, strobeOn, strobeOff }

/// Shared fullscreen Na Me signal (R-12 / D-16) — zero network, full-bleed.
class NaMeFullscreen extends StatefulWidget {
  const NaMeFullscreen({
    super.key,
    required this.colorToken,
    required this.shapeToken,
    required this.label,
    required this.timing,
    required this.effects,
    this.bearingDegrees,
    this.plateNumber,
    this.onClose,
    this.visualState,
  });

  final String colorToken;
  final String shapeToken;
  final String label;
  final NaMeTimingConfig timing;
  final NaMeEffects effects;
  final double? bearingDegrees;
  final String? plateNumber;
  final VoidCallback? onClose;

  /// When set, renders a static snapshot (goldens) instead of live strobe.
  final NaMeFullscreenVisualState? visualState;

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

  bool get _isPreview => widget.visualState != null;

  bool get _effectiveStrobing => _isPreview
      ? widget.visualState != NaMeFullscreenVisualState.idle
      : _isStrobing;

  bool get _effectiveStrobeOn => switch (widget.visualState) {
    NaMeFullscreenVisualState.strobeOff => false,
    NaMeFullscreenVisualState.strobeOn => true,
    NaMeFullscreenVisualState.idle || null => _strobeOn,
  };

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

  void _triggerOnce() {
    if (_isPreview) return;
    _startStrobe(continuous: false);
  }

  void _triggerHoldStart() {
    if (_isPreview) return;
    _startStrobe(continuous: true);
  }

  void _triggerHoldEnd() {
    if (_isPreview) return;
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
    final fill = _effectiveStrobing && _effectiveStrobeOn
        ? colour.color
        : AlongColors.ink900;
    final shapeColor = _effectiveStrobing && !_effectiveStrobeOn
        ? AlongColors.ink900
        : colour.color;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: fill,
      body: GestureDetector(
        key: const Key('na_me_fullscreen'),
        onTap: _triggerOnce,
        onLongPressStart: _isPreview ? null : (_) => _triggerHoldStart(),
        onLongPressEnd: _isPreview ? null : (_) => _triggerHoldEnd(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topInset),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: AlongColors.surface0),
                onPressed:
                    widget.onClose ?? () => Navigator.of(context).maybePop(),
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
                          size: AlongSpace.s48,
                        ),
                      ),
                    const SizedBox(height: AlongSpace.s24),
                    CustomPaint(
                      size: const Size.square(240),
                      painter: NaMeShapePainter(
                        shape: shape,
                        color: shapeColor,
                      ),
                    ),
                    const SizedBox(height: AlongSpace.s16),
                    Text(
                      widget.label.toUpperCase(),
                      key: const Key('na_me_label'),
                      style: AlongText.displayL.copyWith(
                        color: AlongColors.surface0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.plateNumber != null &&
                        widget.plateNumber!.trim().isNotEmpty) ...[
                      const SizedBox(height: AlongSpace.s8),
                      Text(
                        widget.plateNumber!,
                        key: const Key('na_me_plate'),
                        style: AlongText.numericL.copyWith(
                          color: AlongColors.surface0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
            if (_effectiveStrobing)
              Padding(
                padding: const EdgeInsets.all(AlongSpace.s16),
                child: Text(
                  key: const Key('na_me_strobing'),
                  'Signalling…',
                  style: AlongText.bodyStrong.copyWith(
                    color: AlongColors.surface0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}
