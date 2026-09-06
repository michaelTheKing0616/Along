import 'package:along_core/along_core.dart' show TripStatus, TripSummary, formatMoney;
import 'package:along_design/along_design.dart' hide TransportMode, formatMoney;
import 'package:along_design/along_design.dart' as design show TransportMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/live_trip/domain/na_me_chip_mapper.dart';
import 'package:mobile_rider/features/live_trip/presentation/live_trip_controller.dart';
import 'package:mobile_rider/features/live_trip/presentation/na_me_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/vehicle_marker_panel.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:go_router/go_router.dart';

/// R-13 Active trip — map follow, SOS placeholder, LegTimeline, share placeholder.
class ActiveTripScreen extends ConsumerWidget {
  const ActiveTripScreen({super.key, required this.trip});

  final TripSummary trip;

  LiveTripArgs get _args => LiveTripArgs(
        tripId: trip.tripId,
        initialTrip: trip,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(liveTripControllerFamilyProvider(_args));
    final liveTrip = state.trip;
    final heading = liveTrip.live?.driver?.headingDegrees;
    final showNaMe = liveTrip.status == TripStatus.accepted ||
        liveTrip.status == TripStatus.boarded;
    final colour = naMeColourFromToken(liveTrip.naMe.colorToken);
    final shape = naMeShapeFromToken(liveTrip.naMe.shape);
    final eta = liveTrip.etaMinutes ?? 14;
    final fare = liveTrip.totalFare;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: VehicleMarkerPanel(
              headingDegrees: heading,
              showWalkingLine: false,
            ),
          ),
          Positioned(
            top: AlongSpace.s16,
            right: AlongSpace.s16,
            child: HoldButton(
              key: const Key('active_trip_sos'),
              type: HoldButtonType.sos,
              onFired: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.sosPlaceholder)),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AlongSpace.s16),
              decoration: const BoxDecoration(
                color: AlongColors.surface0,
                borderRadius: BorderRadius.vertical(top: AlongRadius.sheet),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.activeTripStatus(eta, formatMoney(liveTrip.totalFare)),
                    style: AlongText.heading2,
                  ),
                  const SizedBox(height: AlongSpace.s12),
                  LegTimeline(
                    key: const Key('active_trip_leg_timeline'),
                    variant: LegTimelineVariant.compact,
                    legs: [
                      LegTimelineLeg(
                        mode: _designMode(liveTrip.modeCode),
                        boardLabel: liveTrip.board.name,
                        alightLabel: liveTrip.alight.name,
                        fareNaira: fare.minorUnits ~/ 100,
                        state: LegTimelineLegState.current,
                      ),
                    ],
                  ),
                  const SizedBox(height: AlongSpace.s12),
                  Text(
                    '${liveTrip.driver.displayName} · ${liveTrip.vehicle.plateNumber}',
                    style: AlongText.body,
                  ),
                  if (showNaMe) ...[
                    const SizedBox(height: AlongSpace.s8),
                    Row(
                      children: [
                        NaMeChip(colour: colour, shape: shape),
                        const SizedBox(width: AlongSpace.s8),
                        HoldButton(
                          key: const Key('active_trip_na_me'),
                          type: HoldButtonType.naMe,
                          onFired: () => context.push(
                            AppRoutes.naMe,
                            extra: NaMeRouteArgs(tripId: liveTrip.tripId),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AlongSpace.s12),
                  Row(
                    children: [
                      Expanded(
                        child: AlongButton(
                          key: const Key('active_trip_extend'),
                          label: l10n.activeTripExtend,
                          variant: AlongButtonVariant.secondary,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.extendPlaceholder)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AlongSpace.s8),
                      Expanded(
                        child: AlongButton(
                          key: const Key('active_trip_share'),
                          label: l10n.activeTripShare,
                          variant: AlongButtonVariant.secondary,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.sharePlaceholder)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AlongSpace.s8),
                      Expanded(
                        child: AlongButton(
                          key: const Key('active_trip_report'),
                          label: l10n.activeTripReport,
                          variant: AlongButtonVariant.secondary,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.reportPlaceholder)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

design.TransportMode _designMode(String code) => switch (code) {
      'keke' => design.TransportMode.keke,
      'okada' => design.TransportMode.okada,
      'minibus' => design.TransportMode.minibus,
      _ => design.TransportMode.car,
    };
