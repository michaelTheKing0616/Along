import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/presentation/live_trip_controller.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/live_trip/presentation/na_me_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/plate_scan_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/vehicle_marker_panel.dart';
import 'package:mobile_rider/features/safety/presentation/guardian_share_screen.dart';
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

    final palette = AlongPalette.of(context);
    final colour = naMeColourFromToken(trip.naMe.colorToken);
    final shape = naMeShapeFromToken(trip.naMe.shape);
    final etaLine = switch (trip.eta?.status) {
      'ready' when trip.eta!.pickup != null => l10n.meetVehicleArrivingAt(
        trip.eta!.pickup!.label,
      ),
      'calculating' => l10n.meetVehicleCalculating,
      _ =>
        trip.etaMinutes != null
            ? l10n.meetVehicleArrivingIn(trip.etaMinutes!)
            : l10n.meetVehicleWalkTo(trip.board.walkS ~/ 60, trip.board.name),
    };
    final driverPoint = trip.live?.driver?.point;

    return TripSheetScaffold(
      mapFraction: 0.4,
      trailing: AlongMapButton(
        key: const Key('meet_vehicle_share'),
        icon: AlongIcons.share,
        tooltip: l10n.meetVehicleShare,
        onPressed: () => context.push(
          AppRoutes.guardianShare,
          extra: GuardianShareArgs(trip: trip),
        ),
      ),
      map: (top, bottom) => VehicleMarkerPanel(
        from: driverPoint ?? trip.live?.rider?.point,
        to: trip.board.location,
        vehicle: driverPoint,
        fromLabel: trip.driver.displayName,
        toLabel: trip.board.name,
        modeCode: trip.modeCode,
        semanticLabel: etaLine,
        topInset: top,
        bottomInset: bottom,
      ),
      footer: AlongButton(
        key: const Key('meet_vehicle_boarded'),
        label: l10n.meetVehicleBoarded,
        onPressed: () async {
          AlongHaptics.confirm(context);
          await controller.markBoarded();
        },
      ),
      children: [
        if (state.driverSignalLost) ...[
          TripNotice(
            icon: AlongIcons.info,
            text: l10n.meetVehicleDriverSignalLost,
            warn: true,
          ),
          const SizedBox(height: AlongSpace.s12),
        ] else if (state.livePaused) ...[
          TripNotice(icon: AlongIcons.info, text: l10n.meetVehicleLivePaused),
          const SizedBox(height: AlongSpace.s12),
        ],
        Text(etaLine, style: AlongType.title(palette)),
        const SizedBox(height: 2),
        Text(
          l10n.meetVehicleMeetAt(trip.board.name),
          style: AlongType.caption(palette),
        ),
        const SizedBox(height: AlongSpace.s16),
        DecoratedBox(
          decoration: AlongCraft.compactFill(palette.recessed, 72, corner: 20),
          child: Padding(
            padding: const EdgeInsets.all(AlongSpace.s12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NaMeChip(colour: colour, shape: shape),
                      const SizedBox(height: AlongSpace.s8),
                      Text(
                        l10n.meetVehicleNaMeShow,
                        style: AlongType.caption(palette),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AlongSpace.s12),
                HoldButton(
                  key: const Key('meet_vehicle_na_me_button'),
                  type: HoldButtonType.naMe,
                  label: l10n.activeTripNaMe,
                  onFired: () => context.push(
                    AppRoutes.naMe,
                    extra: NaMeRouteArgs(
                      tripId: trip.tripId,
                      counterpartLocation: trip.live?.driver?.point,
                      plateNumber: trip.vehicle.plateNumber,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AlongSpace.s12),
        _VehicleCard(
          trip: trip,
          stats: l10n.meetVehicleDriverStats(
            trip.driver.rating.toStringAsFixed(1),
            trip.driver.tripCount,
          ),
          plateConfirmed: _plateConfirmed,
          onScan: () async {
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
          onMatch: () {
            AlongHaptics.tick(context);
            setState(() => _plateConfirmed = true);
          },
        ),
        if (_card != null) ...[
          const SizedBox(height: AlongSpace.s16),
          Text(
            l10n.freeSeatCount(_card!.freeCount),
            style: AlongType.label(palette),
          ),
          for (final rule in _card!.rules)
            Text(
              rule.body == null ? rule.title : '${rule.title}. ${rule.body}',
              style: AlongType.caption(palette),
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
        const SizedBox(height: AlongSpace.s16),
        if (trip.board.walkM > 0) ...[
          AlongButton(
            key: const Key('meet_vehicle_wayfinding'),
            label: l10n.wayfindingTitle,
            variant: AlongButtonVariant.secondary,
            onPressed: () => _openWayfinding(context, trip, l10n),
          ),
          const SizedBox(height: AlongSpace.s8),
        ],
        AlongButton(
          key: const Key('meet_vehicle_cancel'),
          label: l10n.meetVehicleCancel,
          variant: AlongButtonVariant.tertiary,
          onPressed: state.driverSignalLost
              ? () async {
                  await controller.cancelTrip();
                  if (context.mounted) context.go(AppRoutes.home);
                }
              : null,
        ),
      ],
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

/// Who and what to look for: Na Me shape, driver, plate, and the two
/// plate checks side by side.
class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.trip,
    required this.stats,
    required this.plateConfirmed,
    required this.onScan,
    required this.onMatch,
  });

  final TripSummary trip;
  final String stats;
  final bool plateConfirmed;
  final VoidCallback onScan;
  final VoidCallback onMatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final dark = p.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: AlongCraft.compactFill(
        dark ? p.recessed : p.surface,
        160,
        corner: 20,
        side: dark ? BorderSide.none : BorderSide(color: p.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TripDriverAvatar(name: trip.driver.displayName),
                const SizedBox(width: AlongSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.driver.displayName, style: AlongType.label(p)),
                      Text(stats, style: AlongType.caption(p)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AlongSpace.s12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: AlongCraft.compactFill(p.ink, 32, corner: 10),
                  child: Text(
                    trip.vehicle.plateNumber,
                    key: const Key('meet_vehicle_plate'),
                    style: AlongType.numeric(p)
                        .copyWith(color: p.onInk, fontSize: 15),
                  ),
                ),
                const SizedBox(width: AlongSpace.s12),
                Expanded(
                  child: Text(
                    '${trip.vehicle.color} · ${trip.vehicle.makeModel}',
                    style: AlongType.caption(p),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AlongSpace.s12),
            Builder(
              builder: (context) {
                // Side by side normally; stacked when large text would
                // wrap the labels onto two lines.
                final big = MediaQuery.textScalerOf(context).scale(16) > 18;
                final scan = AlongButton(
                  key: const Key('meet_vehicle_plate_scan'),
                  label: l10n.plateScan,
                  size: AlongButtonSize.secondary,
                  variant: AlongButtonVariant.secondary,
                  onPressed: onScan,
                );
                final match = AlongButton(
                  key: const Key('meet_vehicle_plate_match'),
                  label: plateConfirmed ? l10n.plateMatches : l10n.plateCheck,
                  size: AlongButtonSize.secondary,
                  variant: plateConfirmed
                      ? AlongButtonVariant.secondary
                      : AlongButtonVariant.yellow,
                  onPressed: onMatch,
                );
                if (big) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      match,
                      const SizedBox(height: AlongSpace.s8),
                      scan,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: scan),
                    const SizedBox(width: AlongSpace.s8),
                    Expanded(child: match),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
