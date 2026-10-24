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
import 'package:mobile_rider/features/live_trip/presentation/plate_scan_screen.dart';
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

  VehicleCard? _card;
  var _plateConfirmed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadCard);
  }

  Future<void> _loadCard() async {
    try {
      final card = await ref
          .read(seatRepositoryProvider)
          .cardForTrip(widget.trip.tripId);
      if (mounted && card != null) setState(() => _card = card);
    } catch (_) {
      // The trip can be met before a seat layout exists.
    }
  }

  Future<void> _claim(String seatId) async {
    final card = _card;
    final seat = card?.layout.seatById(seatId);
    if (card == null || seat == null || !seat.isPassenger) return;
    final engine = const SeatRuleEngine();
    final rowId = card.layout.rowIdOf(seatId);
    final acks = engine.acknowledgementsRequired(
      rules: card.rules,
      seatId: seatId,
      rowId: rowId,
    );
    var version = 1;
    for (final state in card.seats) {
      if (state.seatId == seatId) version = state.version;
    }
    try {
      await ref
          .read(seatRepositoryProvider)
          .claimSeat(
            layoutId: card.layoutId,
            seatId: seatId,
            expectedVersion: version,
            ackRuleIds: [for (final rule in acks) rule.id],
          );
      await _loadCard();
    } on AlongException catch (error) {
      if (!mounted) return;
      final titles = (error.code == AlongErrorCode.ruleAck ? acks : card.rules)
          .map((rule) => rule.title)
          .join('\n');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(titles)));
    }
  }

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
    final etaLine = switch (trip.eta?.status) {
      'ready' when trip.eta!.pickup != null =>
        'Arriving · ${trip.eta!.pickup!.label}',
      'calculating' => 'Calculating…',
      _ => trip.etaMinutes != null
          ? l10n.meetVehicleArrivingIn(trip.etaMinutes!)
          : l10n.meetVehicleWalkTo(trip.board.walkS ~/ 60, trip.board.name),
    };

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
              clipBehavior: Clip.antiAlias,
              decoration: AlongCraft.fill(
                AlongColors.surface0,
                corner: AlongRadius.sheet.x,
                top: true,
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
                            plateNumber: trip.vehicle.plateNumber,
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
                    AlongButton(
                      key: const Key('meet_vehicle_plate_scan'),
                      label: l10n.plateScan,
                      variant: AlongButtonVariant.secondary,
                      onPressed: () async {
                        final confirmed = await context.push<bool>(
                          AppRoutes.plateScan,
                          extra: PlateScanArgs(
                            expectedPlate: trip.vehicle.plateNumber,
                            tripId: trip.tripId,
                            trip: trip,
                          ),
                        );
                        if (confirmed == true && mounted) {
                          setState(() => _plateConfirmed = true);
                        }
                      },
                    ),
                    const SizedBox(height: AlongSpace.s8),
                    AlongButton(
                      key: const Key('meet_vehicle_plate_match'),
                      label: _plateConfirmed
                          ? l10n.plateMatches
                          : l10n.plateCheck,
                      variant: _plateConfirmed
                          ? AlongButtonVariant.secondary
                          : AlongButtonVariant.yellow,
                      onPressed: () => setState(() => _plateConfirmed = true),
                    ),
                    const SizedBox(height: AlongSpace.s8),
                    Text(etaLine, style: AlongText.bodyStrong),
                    if (_card != null) ...[
                      const SizedBox(height: AlongSpace.s12),
                      Text(
                        l10n.freeSeatCount(_card!.freeCount),
                        style: AlongText.bodyStrong,
                      ),
                      for (final rule in _card!.rules)
                        Text(
                          rule.body == null
                              ? rule.title
                              : '${rule.title}. ${rule.body}',
                        ),
                      const SizedBox(height: AlongSpace.s8),
                      SeatMap(
                        body: _card!.layout.body,
                        rows: [
                          for (final row in _card!.layout.rows)
                            SeatMapRowView(
                              id: row.id,
                              ruleTitle: _rowRule(_card!.rules, row.id),
                              seats: [
                                for (final seat in row.seats)
                                  SeatMapSeat(
                                    id: seat.id,
                                    label: seat.label,
                                    role: seat.role,
                                    status: _seatStatus(_card!, seat.id),
                                    statusWord: seat.isPassenger
                                        ? _seatStatus(_card!, seat.id)
                                        : l10n.seatDriver,
                                  ),
                              ],
                            ),
                        ],
                        onSeatTap: _claim,
                      ),
                    ],
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
                                    if (context.mounted) {
                                      context.go(AppRoutes.home);
                                    }
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

  String _seatStatus(VehicleCard card, String seatId) {
    for (final seat in card.seats) {
      if (seat.seatId == seatId) return seat.status;
    }
    return 'free';
  }

  String? _rowRule(List<RideRule> rules, String rowId) {
    final titles = [
      for (final rule in rules)
        if (rule.targetScope == 'row' && rule.targetRef == rowId) rule.title,
    ];
    if (titles.isEmpty) return null;
    return titles.join(' · ');
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
