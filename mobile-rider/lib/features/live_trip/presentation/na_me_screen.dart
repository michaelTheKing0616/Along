import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/live_trip_config.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';

class FlutterNaMeEffects implements NaMeEffects {
  FlutterNaMeEffects(this._tts);

  final WayfindingTts _tts;

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  void hapticPulse() => HapticFeedback.heavyImpact();
}

/// Max brightness and keep-awake while the rider holds up Na Me.
class NaMeScreenHost {
  Future<void> enter() async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(1);
      await WakelockPlus.enable();
    } catch (_) {}
  }

  Future<void> exit() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
      await WakelockPlus.disable();
    } catch (_) {}
  }
}

/// The match chime, shipped in along_design.
Future<void> playNaMeChime() async {
  try {
    final player = AudioPlayer()..audioCache = AudioCache(prefix: '');
    await player.play(
      AssetSource('packages/along_design/assets/sounds/na_me_chime.wav'),
    );
  } catch (_) {}
}

final naMeScreenHostProvider = Provider<NaMeScreenHost>(
  (ref) => NaMeScreenHost(),
);

final naMeEffectsProvider = Provider<NaMeEffects>((ref) {
  return FlutterNaMeEffects(ref.watch(wayfindingTtsProvider));
});

class NaMeRouteArgs {
  const NaMeRouteArgs({
    required this.tripId,
    this.counterpartLocation,
    this.userLocation,
    this.plateNumber,
    this.driverName,
  });

  final String tripId;
  final String? driverName;
  final GeoPoint? counterpartLocation;
  final GeoPoint? userLocation;
  final String? plateNumber;

  @override
  bool operator ==(Object other) =>
      other is NaMeRouteArgs &&
      other.tripId == tripId &&
      other.counterpartLocation == counterpartLocation &&
      other.userLocation == userLocation &&
      other.plateNumber == plateNumber;

  @override
  int get hashCode =>
      Object.hash(tripId, counterpartLocation, userLocation, plateNumber);
}

/// R-12 Na Me fullscreen. With optical sync on, the rider shows the camera
/// code (frames from the trip secret, re-keyed every step) and needs zero
/// taps: brightness is maxed and the screen kept awake until it closes.
class NaMeScreen extends ConsumerStatefulWidget {
  const NaMeScreen({super.key, required this.args});

  final NaMeRouteArgs args;

  /// True while a Na Me screen is on top, so the boarded moment can close it.
  static final isOpen = ValueNotifier<bool>(false);

  @override
  ConsumerState<NaMeScreen> createState() => _NaMeScreenState();
}

class _NaMeScreenState extends ConsumerState<NaMeScreen> {
  late final Future<(NaMePairing?, String?)> _load = _fetch();
  Timer? _tick;
  late final NaMeScreenHost _host;
  int _step = NaMeOptical.stepAt(DateTime.now());

  NaMeRouteArgs get args => widget.args;

  Future<(NaMePairing?, String?)> _fetch() async {
    final repo = ref.read(tripsRepositoryProvider);
    final pairing = await repo.cachedNaMePairing(args.tripId);
    String? secret;
    if (ref.read(appConfigProvider).naMeOpticalEnabled) {
      secret = await repo.naMeSecret(args.tripId).catchError((_) => null);
    }
    return (pairing, secret);
  }

  @override
  void initState() {
    super.initState();
    NaMeScreen.isOpen.value = true;
    _host = ref.read(naMeScreenHostProvider)..enter();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = NaMeOptical.stepAt(DateTime.now());
      if (s != _step && mounted) setState(() => _step = s);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    NaMeScreen.isOpen.value = false;
    _host.exit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(liveTripConfigProvider);

    return FutureBuilder<(NaMePairing?, String?)>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AlongColors.ink900,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final (pairing, secret) = snapshot.data ?? (null, null);
        if (pairing == null || !configAsync.hasValue) {
          return Scaffold(
            backgroundColor: AlongColors.ink900,
            appBar: AppBar(backgroundColor: Colors.transparent),
            body: Center(
              child: Text(
                'Na Me pairing unavailable',
                style: AlongText.body.copyWith(color: AlongColors.surface0),
              ),
            ),
          );
        }

        if (secret != null) {
          return AlongNaMeShowScreen(
            key: ValueKey(_step),
            pairing: AlongNaMeChoice(
              colorToken: pairing.colorToken,
              shape: pairing.shape,
              label: pairing.label,
            ),
            driverName: args.driverName ?? 'your driver',
            frames: NaMeOptical.frames(secret, _step),
            onClose: () => Navigator.of(context).maybePop(),
          );
        }

        return NaMeFullscreen(
          colorToken: pairing.colorToken,
          shapeToken: pairing.shape,
          label: pairing.label,
          plateNumber: args.plateNumber,
          timing: NaMeTimingConfig(
            strobeInterval: configAsync.value!.naMeStrobeMs,
            cycleDuration: configAsync.value!.naMeCycleDuration,
          ),
          effects: ref.read(naMeEffectsProvider),
          bearingDegrees: _bearing(args),
          onClose: () => Navigator.of(context).maybePop(),
        );
      },
    );
  }

  double? _bearing(NaMeRouteArgs args) {
    final from = args.userLocation;
    final to = args.counterpartLocation;
    if (from == null || to == null) return null;
    return bearingDegrees(from, to);
  }
}
