import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/live_trip/domain/na_me_chip_mapper.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/presentation/live_trip_controller.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/live_trip/presentation/na_me_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/vehicle_marker_panel.dart';
import 'package:mobile_rider/features/safety/presentation/share_trip_sheet.dart';
import 'package:mobile_rider/features/wayfinding/presentation/wayfinding_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

class MeetVehicleRouteArgs {
  const MeetVehicleRouteArgs({required this.trip});

  final TripSummary trip;
}

/// R-11 Meet your vehicle — live marker, Na Me, wayfinding, boarded override.
class MeetVehicleScreen extends ConsumerStatefulWidget {
  const MeetVehicleScreen({super.key, required this.trip});

  final TripSummary trip;

  @override
  ConsumerState<MeetVehicleScreen> createState() => _MeetVehicleScreenState();
}

class _MeetVehicleScreenState extends ConsumerState<MeetVehicleScreen> {
  LiveTripArgs get _args =>
      LiveTripArgs(tripId: widget.trip.tripId, initialTrip: widget.trip);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(liveTripControllerFamilyProvider(_args));
    final controller = ref.read(
      liveTripControllerFamilyProvider(_args).notifier,
    );
    final trip = state.trip;

    ref.listen(liveTripControllerFamilyProvider(_args), (prev, next) {
      if (prev?.trip.status == next.trip.status) return;
      if (next.trip.status == TripStatus.boarded ||
          next.trip.status == TripStatus.inTransit) {
        context.go(AppRoutes.activeTrip, extra: next.trip);
      }
    });

    final heading = trip.live?.driver?.headingDegrees;
    final colour = naMeColourFromToken(trip.naMe.colorToken);
    final shape = naMeShapeFromToken(trip.naMe.shape);
    final etaLine = trip.etaMinutes != null
        ? l10n.meetVehicleArrivingIn(trip.etaMinutes!)
        : l10n.meetVehicleWalkTo(trip.board.walkS ~/ 60, trip.board.name);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: VehicleMarkerPanel(
              headingDegrees: heading,
              showWalkingLine: trip.board.walkM > 0,
              lat: trip.live?.driver?.lat ?? trip.live?.rider?.lat,
              lng: trip.live?.driver?.lng ?? trip.live?.rider?.lng,
            ),
          ),
          Flexible(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AlongSpace.s16),
              decoration: const BoxDecoration(
                color: AlongColors.surface0,
                borderRadius: BorderRadius.vertical(top: AlongRadius.sheet),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.driverSignalLost)
                      Text(
                        l10n.meetVehicleDriverSignalLost,
                        style: AlongText.bodyStrong.copyWith(
                          color: AlongColors.semanticWarning,
                        ),
                      ),
                    if (state.livePaused)
                      Text(
                        l10n.meetVehicleLivePaused,
                        style: AlongText.caption.copyWith(
                          color: AlongColors.ink500,
                        ),
                      ),
                    Row(
                      children: [
                        NaMeChip(colour: colour, shape: shape),
                        const SizedBox(width: AlongSpace.s8),
                        Expanded(
                          child: Text(
                            l10n.meetVehicleNaMeHint(trip.naMe.label),
                            style: AlongText.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AlongSpace.s12),
                    Center(
                      child: HoldButton(
                        key: const Key('meet_vehicle_na_me_button'),
                        type: HoldButtonType.naMe,
                        onFired: () => context.push(
                          AppRoutes.naMe,
                          extra: NaMeRouteArgs(
                            tripId: trip.tripId,
                            counterpartLocation: trip.live?.driver?.point,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AlongSpace.s16),
                    Text(
                      '${trip.driver.displayName} · ${trip.driver.rating.toStringAsFixed(1)} · ${trip.driver.tripCount} trips',
                      style: AlongText.body,
                    ),
                    const SizedBox(height: AlongSpace.s4),
                    Text(
                      trip.vehicle.plateNumber,
                      key: const Key('meet_vehicle_plate'),
                      style: AlongText.numericL,
                    ),
                    Text(
                      '${trip.vehicle.color} · ${trip.vehicle.makeModel}',
                      style: AlongText.caption.copyWith(
                        color: AlongColors.ink500,
                      ),
                    ),
                    const SizedBox(height: AlongSpace.s8),
                    Text(etaLine, style: AlongText.bodyStrong),
                    if (trip.board.walkM > 0) ...[
                      const SizedBox(height: AlongSpace.s12),
                      AlongButton(
                        key: const Key('meet_vehicle_wayfinding'),
                        label: l10n.wayfindingTitle,
                        variant: AlongButtonVariant.secondary,
                        onPressed: () => _openWayfinding(context, trip, l10n),
                      ),
                    ],
                    const SizedBox(height: AlongSpace.s16),
                    Row(
                      children: [
                        Expanded(
                          child: AlongButton(
                            key: const Key('meet_vehicle_share'),
                            label: l10n.meetVehicleShare,
                            variant: AlongButtonVariant.secondary,
                            onPressed: () => ShareTripSheet.show(
                              context,
                              journeyId: trip.journeyId,
                            ),
                          ),
                        ),
                        const SizedBox(width: AlongSpace.s8),
                        Expanded(
                          child: AlongButton(
                            key: const Key('meet_vehicle_cancel'),
                            label: l10n.meetVehicleCancel,
                            variant: AlongButtonVariant.secondary,
                            onPressed: state.driverSignalLost
                                ? () async {
                                    await controller.cancelTrip();
                                    if (context.mounted)
                                      context.go(AppRoutes.home);
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AlongSpace.s8),
                    AlongButton(
                      key: const Key('meet_vehicle_boarded'),
                      label: l10n.meetVehicleBoarded,
                      variant: AlongButtonVariant.tertiary,
                      onPressed: () async {
                        await controller.markBoarded();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openWayfinding(
    BuildContext context,
    TripSummary trip,
    AppLocalizations l10n,
  ) {
    final destination = trip.board.location;
    if (destination == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.wayfindingNoSteps)));
      return;
    }

    final userLocation =
        trip.live?.rider?.point ??
        ref.read(homeControllerProvider).userLocation;
    final origin = userLocation ?? destination;

    context.push(
      AppRoutes.wayfinding,
      extra: WayfindingRouteArgs(
        from: origin,
        to: destination,
        userLocation: userLocation,
        cacheTripId: trip.tripId,
        destinationLabel: trip.board.name,
      ),
    );
  }
}
