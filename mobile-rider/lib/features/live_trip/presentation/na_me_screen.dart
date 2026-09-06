import 'dart:async';
import 'dart:math' as math;

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/live_trip_config.dart';
import 'package:mobile_rider/features/live_trip/domain/na_me_chip_mapper.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';

/// Offline Na Me signal effects (doc 07 §9) — zero network.
abstract class NaMeEffects {
  Future<void> speak(String text);
  void hapticPulse();
}

class FlutterNaMeEffects implements NaMeEffects {
  FlutterNaMeEffects(this._tts);

  final WayfindingTts _tts;

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  void hapticPulse() => HapticFeedback.heavyImpact();
}

final naMeEffectsProvider = Provider<NaMeEffects>((ref) {
  return FlutterNaMeEffects(ref.watch(wayfindingTtsProvider));
});

class NaMeControllerState {
  const NaMeControllerState({
    this.pairing,
    this.isStrobing = false,
    this.strobeOn = true,
    this.cycleRemainingMs = 0,
    this.bearingDegrees,
    this.loading = true,
    this.errorMessage,
  });

  final NaMePairing? pairing;
  final bool isStrobing;
  final bool strobeOn;
  final int cycleRemainingMs;
  final double? bearingDegrees;
  final bool loading;
  final String? errorMessage;

  NaMeControllerState copyWith({
    NaMePairing? pairing,
    bool? isStrobing,
    bool? strobeOn,
    int? cycleRemainingMs,
    double? bearingDegrees,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NaMeControllerState(
      pairing: pairing ?? this.pairing,
      isStrobing: isStrobing ?? this.isStrobing,
      strobeOn: strobeOn ?? this.strobeOn,
      cycleRemainingMs: cycleRemainingMs ?? this.cycleRemainingMs,
      bearingDegrees: bearingDegrees ?? this.bearingDegrees,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class NaMeRouteArgs {
  const NaMeRouteArgs({
    required this.tripId,
    this.counterpartLocation,
    this.userLocation,
  });

  final String tripId;
  final GeoPoint? counterpartLocation;
  final GeoPoint? userLocation;

  @override
  bool operator ==(Object other) =>
      other is NaMeRouteArgs &&
      other.tripId == tripId &&
      other.counterpartLocation == counterpartLocation &&
      other.userLocation == userLocation;

  @override
  int get hashCode => Object.hash(tripId, counterpartLocation, userLocation);
}

final naMeControllerFamilyProvider = NotifierProvider.family<
    NaMeController, NaMeControllerState, NaMeRouteArgs>(
  NaMeController.new,
);

/// R-12 Na Me fullscreen controller — reads cached pairing only (TS-UI-02).
class NaMeController extends FamilyNotifier<NaMeControllerState, NaMeRouteArgs> {
  Timer? _strobeTimer;
  Timer? _cycleTimer;
  Timer? _cycleEndTimer;
  LiveTripConfig? _config;

  @override
  NaMeControllerState build(NaMeRouteArgs args) {
    ref.onDispose(_disposeTimers);
    Future.microtask(() => _load(args));
    return const NaMeControllerState(loading: true);
  }

  void _disposeTimers() {
    _strobeTimer?.cancel();
    _cycleTimer?.cancel();
    _cycleEndTimer?.cancel();
  }

  Future<void> _load(NaMeRouteArgs args) async {
    try {
      final pairing = await ref
          .read(tripsRepositoryProvider)
          .cachedNaMePairing(args.tripId);
      _config = await ref.read(liveTripConfigProvider.future);
      final bearing = _bearing(args);
      state = NaMeControllerState(
        pairing: pairing,
        loading: false,
        bearingDegrees: bearing,
      );
    } catch (e) {
      state = NaMeControllerState(loading: false, errorMessage: e.toString());
    }
  }

  double? _bearing(NaMeRouteArgs args) {
    final from = args.userLocation;
    final to = args.counterpartLocation;
    if (from == null || to == null) return null;
    return bearingDegrees(from, to);
  }

  void triggerOnce() => _startStrobe(continuous: false);

  void triggerHoldStart() => _startStrobe(continuous: true);

  void triggerHoldEnd() {
    if (_cycleTimer == null) {
      stopStrobe();
    }
  }

  void _startStrobe({required bool continuous}) {
    final pairing = state.pairing;
    final config = _config;
    if (pairing == null || config == null) return;

    _disposeTimers();
    ref.read(naMeEffectsProvider).speak('Along — ${pairing.label}');
    ref.read(naMeEffectsProvider).hapticPulse();

    state = state.copyWith(
      isStrobing: true,
      strobeOn: true,
      cycleRemainingMs: config.naMeCycleDuration.inMilliseconds,
    );

    _strobeTimer = Timer.periodic(config.naMeStrobeMs, (_) {
      state = state.copyWith(strobeOn: !state.strobeOn);
      ref.read(naMeEffectsProvider).hapticPulse();
    });

    _cycleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final remaining = state.cycleRemainingMs - 100;
      if (remaining <= 0) {
        timer.cancel();
        stopStrobe();
        return;
      }
      state = state.copyWith(cycleRemainingMs: remaining);
    });

    if (!continuous) {
      _cycleEndTimer?.cancel();
      _cycleEndTimer = Timer(config.naMeCycleDuration, stopStrobe);
    }
  }

  void stopStrobe() {
    _disposeTimers();
    state = state.copyWith(isStrobing: false, strobeOn: true, cycleRemainingMs: 0);
  }
}

/// R-12 Na Me fullscreen — offline strobe from cached pairing.
class NaMeScreen extends ConsumerWidget {
  const NaMeScreen({super.key, required this.args});

  final NaMeRouteArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(naMeControllerFamilyProvider(args));
    final controller = ref.read(naMeControllerFamilyProvider(args).notifier);
    final pairing = state.pairing;

    if (state.loading) {
      return const Scaffold(
        backgroundColor: AlongColors.ink900,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (pairing == null) {
      return Scaffold(
        backgroundColor: AlongColors.ink900,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text(
            state.errorMessage ?? 'Na Me pairing unavailable',
            style: AlongText.body.copyWith(color: AlongColors.surface0),
          ),
        ),
      );
    }

    final colour = naMeColourFromToken(pairing.colorToken);
    final shape = naMeShapeFromToken(pairing.shape);
    final fill = state.isStrobing && state.strobeOn
        ? colour.color
        : AlongColors.ink900;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: fill,
        body: SafeArea(
          child: GestureDetector(
            key: const Key('na_me_fullscreen'),
            onTap: controller.triggerOnce,
            onLongPressStart: (_) => controller.triggerHoldStart(),
            onLongPressEnd: (_) => controller.triggerHoldEnd(),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AlongColors.surface0),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.bearingDegrees != null)
                          Transform.rotate(
                            angle: state.bearingDegrees! * math.pi / 180,
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
                            color: state.isStrobing && !state.strobeOn
                                ? AlongColors.ink900
                                : colour.color,
                          ),
                        ),
                        const SizedBox(height: AlongSpace.s16),
                        Text(
                          pairing.label.toUpperCase(),
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
                if (state.isStrobing)
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
