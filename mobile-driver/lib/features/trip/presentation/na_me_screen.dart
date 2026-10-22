import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/trip/domain/driver_trip_config.dart';

class NaMeRouteArgs {
  const NaMeRouteArgs({required this.tripId, this.plateNumber});

  final String tripId;
  final String? plateNumber;

  @override
  bool operator ==(Object other) =>
      other is NaMeRouteArgs &&
      other.tripId == tripId &&
      other.plateNumber == plateNumber;

  @override
  int get hashCode => Object.hash(tripId, plateNumber);
}

class DriverNaMeEffects implements NaMeEffects {
  @override
  Future<void> speak(String text) async {}

  @override
  void hapticPulse() => HapticFeedback.heavyImpact();
}

/// D-16 Na Me — offline cached pairing via shared [NaMeFullscreen].
class NaMeScreen extends ConsumerWidget {
  const NaMeScreen({super.key, required this.args});

  final NaMeRouteArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(driverTripConfigProvider);

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

        return NaMeFullscreen(
          colorToken: pairing.colorToken,
          shapeToken: pairing.shape,
          label: pairing.label,
          plateNumber: args.plateNumber,
          timing: configAsync.value!.naMeTiming,
          effects: DriverNaMeEffects(),
          onClose: () => Navigator.of(context).maybePop(),
        );
      },
    );
  }
}
