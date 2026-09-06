import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final naMeEffectsProvider = Provider<NaMeEffects>((ref) {
  return FlutterNaMeEffects(ref.watch(wayfindingTtsProvider));
});

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

/// R-12 Na Me fullscreen — offline strobe from cached pairing (shared widget).
class NaMeScreen extends ConsumerWidget {
  const NaMeScreen({super.key, required this.args});

  final NaMeRouteArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(liveTripConfigProvider);

    return FutureBuilder<NaMePairing?>(
      future: ref.read(tripsRepositoryProvider).cachedNaMePairing(args.tripId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AlongColors.ink900,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pairing = snapshot.data;
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

        final bearing = _bearing(args);

        return NaMeFullscreen(
          colorToken: pairing.colorToken,
          shapeToken: pairing.shape,
          label: pairing.label,
          timing: NaMeTimingConfig(
            strobeInterval: configAsync.value!.naMeStrobeMs,
            cycleDuration: configAsync.value!.naMeCycleDuration,
          ),
          effects: ref.read(naMeEffectsProvider),
          bearingDegrees: bearing,
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
