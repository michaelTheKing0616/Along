import 'package:along_core/along_core.dart'
    show
        NaMePairing,
        TripEtaStop,
        TripStatus,
        TripWaitApproach,
        computeAlongCommission,
        formatMoney;
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:along_data/along_data.dart' show TripChatController;
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/trip/domain/driver_trip_config.dart';
import 'package:mobile_driver/features/payments/data/payments_providers.dart';
import 'package:mobile_driver/features/payments/presentation/payment_request_controller.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/features/trip/presentation/na_me_handshake_screen.dart';
import 'package:mobile_driver/features/trip/presentation/active_trip_controller.dart';
import 'package:mobile_driver/features/trip/presentation/extend_trip_sheet.dart';
import 'package:mobile_driver/features/trip/presentation/trip_chat.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';
import 'package:mobile_driver/features/trip/presentation/trip_complete_sheet.dart';
import 'package:mobile_driver/features/trip/presentation/na_me_screen.dart';
import 'package:mobile_driver/features/safety/presentation/sos_active_screen.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-16 Active trip — map, Na Me, start/complete, extend (doc 06).
class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key, required this.args});

  final ActiveTripArgs args;

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    ref.listen(activeTripControllerFamilyProvider(args), (previous, next) {
      if (next.completeResult != null &&
          previous?.completeResult == null &&
          context.mounted) {
        final paidDigitally =
            next.digitalPayment != null ||
            next.completeResult!.trip.paymentMethod == 'digital';
        TripCompleteSheet.show(
          context,
          result: next.completeResult!,
          paidDigitally: paidDigitally,
          driverAmountReceived: next.digitalPayment?.driverAmount,
          onFinished: () {
            if (context.mounted) context.pop();
          },
        );
      }
    });
    final l10n = AppLocalizations.of(context);
    final configAsync = ref.watch(driverTripConfigProvider);
    final state = ref.watch(activeTripControllerFamilyProvider(args));
    final controller = ref.read(
      activeTripControllerFamilyProvider(args).notifier,
    );
    final appConfig = ref.watch(appConfigProvider);
    final home = ref.watch(driverHomeControllerProvider);
    final digitalEnabled = ref.watch(digitalPaymentsEnabledProvider);

    final trip = state.trip;
    final entry = state.entry;
    final status = trip?.status ?? entry?.status;
    // Preloaded for the whole live trip so the sheet opens on a full thread.
    final chat =
        status == TripStatus.accepted ||
            status == TripStatus.boarded ||
            status == TripStatus.inTransit
        ? ref.watch(tripChatProvider(args.tripId))
        : null;
    chat?.onIncoming = () {
      if (context.mounted) AlongHaptics.tick(context);
    };
    final naMe = trip?.naMe ?? entry?.naMe;
    final riderName = trip?.rider.displayName ?? entry?.rider.displayName ?? '';
    final boardName = trip?.board.name ?? entry?.board.name ?? '';
    final alightName = trip?.alight.name ?? '';
    final fare = trip?.totalFare;
    final holdDuration = configAsync.maybeWhen(
      data: (cfg) => cfg.sosHoldDurationMs,
      orElse: () => const Duration(milliseconds: 600),
    );

    return Scaffold(
      key: const Key('active_trip_screen'),
      body: Stack(
        children: [
          Positioned.fill(
            child: AlongMap(
              key: const Key('active_trip_map'),
              styleUrl: AlongStyleLoader.resolveBasemapStyleUrl(
                tilesBase: appConfig.tilesBaseUrl,
                citySlug: home.citySlug,
              ),
              allowDemoStyleFallback: false,
              // Drawn, host-stable city map: what tests and a missing
              // brand style show instead of a blank land fill.
              placeholder: const AlongCityMap(
                mode: AlongCityMapMode.trip,
                sheetInset: 0.5,
                demoLabel: false,
                assetPackage: 'along_design',
              ),
              initialCameraPosition: home.mapCenter == null
                  ? null
                  : MapCamera.forCenter(
                      lat: home.mapCenter!.lat,
                      lng: home.mapCenter!.lng,
                    ),
              myLocationEnabled: true,
            ),
          ),
          Positioned(
            top: AlongSpace.s16,
            right: AlongSpace.s16,
            child: SafeArea(
              child: HoldButton(
                key: const Key('active_trip_sos'),
                type: HoldButtonType.sos,
                holdDuration: holdDuration,
                onFired: () {
                  final activeTrip = trip;
                  if (activeTrip == null) return;
                  context.push(
                    AppRoutes.sosActive,
                    extra: SosActiveRouteArgs(trip: activeTrip),
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DriveSheet(
              key: const Key('active_trip_sheet'),
              // Content-sized at 1x; at large text the whole panel still fits.
              maxHeightFactor: 0.95,
              child: state.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(AlongSpace.s24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _PinnedPanel(
                      parts: _panel(
                        context,
                        l10n: l10n,
                        state: state,
                        controller: controller,
                        status: status,
                        riderName: riderName,
                        boardName: boardName,
                        alightName: alightName,
                        naMe: naMe,
                        chat: chat,
                        digitalEnabled: digitalEnabled.maybeWhen(
                          data: (enabled) => enabled,
                          orElse: () => false,
                        ),
                        fare: fare == null
                            ? null
                            : (
                                formatMoney(fare),
                                configAsync.hasValue
                                    ? formatMoney(
                                        computeAlongCommission(
                                          fare,
                                          configAsync.value!.commissionRate,
                                        ),
                                      )
                                    : null,
                                configAsync.hasValue
                                    ? (configAsync.value!.commissionRate * 100)
                                          .toStringAsFixed(1)
                                    : null,
                              ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  (List<Widget>, List<Widget>) _panel(
    BuildContext context, {
    required AppLocalizations l10n,
    required ActiveTripState state,
    required ActiveTripController controller,
    required TripStatus? status,
    required String riderName,
    required String boardName,
    required String alightName,
    required NaMePairing? naMe,
    required TripChatController? chat,
    required bool digitalEnabled,
    required (String, String?, String?)? fare,
  }) {
    final p = AlongPalette.of(context);
    final args = widget.args;
    final trip = state.trip;
    final first = riderName.isEmpty
        ? l10n.activeTripRiderFallback
        : riderName.split(' ').first;
    final busy = state.isSubmitting
        ? AlongButtonVisualState.loading
        : AlongButtonVisualState.normal;
    final phase = switch (status) {
      TripStatus.boarded || TripStatus.transfer => 1,
      TripStatus.inTransit => 2,
      _ => 0,
    };
    final title = switch (phase) {
      1 => l10n.activeTripOnBoardTitle(first),
      2 => l10n.activeTripDropTitle(first),
      _ => l10n.activeTripPickUpTitle(first),
    };
    final place = phase == 2 ? alightName : boardName;
    final pickupPhase = status == TripStatus.accepted;
    final showNaMe =
        naMe != null &&
        (status == TripStatus.accepted ||
            status == TripStatus.boarded ||
            status == TripStatus.transfer);

    void openPin() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AlongPinEntryScreen(
          riderName: first,
          onSubmit: controller.verifyPin,
          onGetHelp: switch (ref.read(appConfigProvider).supportUri) {
            final uri? => () => launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            ),
            null => null,
          },
          onVerified: () {
            final nav = Navigator.of(context);
            Future.delayed(
              const Duration(milliseconds: 360),
              () => nav.maybePop(),
            );
          },
        ),
      ),
    );

    void openNaMe() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            NaMeHandshakeScreen(args: args, riderName: first, pairing: naMe!),
      ),
    );

    final complete = AlongButton(
      key: const Key('active_trip_complete'),
      label: l10n.activeTripComplete,
      visualState: busy,
      onPressed: state.isSubmitting
          ? null
          : () {
              AlongHaptics.confirm(context);
              controller.completeTrip();
            },
    );

    final primary = <Widget>[
      if (pickupPhase && naMe != null) ...[
        AlongButton(
          key: const Key('active_trip_board'),
          label: l10n.activeTripBoardNaMe,
          onPressed: openNaMe,
        ),
      ] else if (pickupPhase)
        AlongButton(
          key: const Key('active_trip_enter_pin'),
          label: l10n.activeTripEnterPin,
          onPressed: openPin,
        ),
      if (status == TripStatus.transfer)
        AlongButton(
          key: const Key('active_trip_mark_boarded'),
          label: l10n.manifestMarkBoarded,
          visualState: busy,
          onPressed: state.isSubmitting ? null : () => controller.markBoarded(),
        ),
      if (status == TripStatus.boarded)
        AlongButton(
          key: const Key('active_trip_start'),
          label: l10n.activeTripStart,
          visualState: busy,
          onPressed: state.isSubmitting
              ? null
              : () {
                  AlongHaptics.confirm(context);
                  controller.startTrip();
                },
        ),
      if (status == TripStatus.inTransit && digitalEnabled)
        Row(
          children: [
            Expanded(
              child: AlongButton(
                key: const Key('active_trip_request_payment'),
                label: l10n.requestPayment,
                variant: AlongButtonVariant.yellow,
                onPressed: () => context.push(
                  AppRoutes.paymentRequest,
                  extra: PaymentRequestArgs(
                    tripId: args.tripId,
                    riderName: riderName,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AlongSpace.s8),
            Expanded(child: complete),
          ],
        )
      else if (status == TripStatus.inTransit)
        complete,
    ];

    final tiles = <Widget>[
      if (chat != null)
        DriveActionTile(
          key: const Key('active_trip_message'),
          icon: AlongIcons.chat,
          label: l10n.activeTripMessageShort,
          badge: chat.unread,
          onPressed: () => openTripChat(
            context,
            ref,
            tripId: args.tripId,
            otherName: riderName.isEmpty ? 'Rider' : riderName,
          ),
        ),
      if (pickupPhase && naMe != null)
        DriveActionTile(
          key: const Key('active_trip_enter_pin'),
          icon: AlongIcons.password,
          label: l10n.activeTripPinShort,
          onPressed: openPin,
        ),
      DriveActionTile(
        key: const Key('active_trip_seat_map'),
        icon: Icons.event_seat_rounded,
        label: l10n.activeTripSeatsShort,
        onPressed: () => context.push(AppRoutes.seatBoard),
      ),
      if (status == TripStatus.inTransit)
        DriveActionTile(
          key: const Key('active_trip_extend'),
          icon: AlongIcons.addTime,
          label: l10n.activeTripExtendShort,
          onPressed: () => ExtendTripSheet.show(context, tripId: args.tripId),
        ),
      DriveActionTile(
        key: const Key('active_trip_report'),
        icon: AlongIcons.info,
        label: l10n.activeTripReportShort,
        onPressed: () =>
            context.push(AppRoutes.reportIncident, extra: args.tripId),
      ),
    ];

    return (
      [
        DrivePhaseBar(
          labels: [
            l10n.drivePhasePickup,
            l10n.drivePhaseBoard,
            l10n.drivePhaseDrop,
          ],
          current: phase,
        ),
        const SizedBox(height: AlongSpace.s16),
        Text(title, style: AlongType.caption(p)),
        const SizedBox(height: 2),
        Text(
          place,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AlongType.display(p).copyWith(fontSize: 28, height: 1.1),
        ),
        const SizedBox(height: AlongSpace.s4),
        Text(
          trip?.eta?.driverLine(l10n.tripEtaPickup) ?? l10n.tripEtaCalculating,
          key: const Key('active_trip_eta'),
          style: AlongType.label(p),
        ),
        for (final stop in trip?.eta?.stops ?? const <TripEtaStop>[])
          Padding(
            padding: const EdgeInsets.only(top: AlongSpace.s4),
            child: Text(
              '${stop.name} · ${stop.label}',
              key: Key('active_trip_stop_${stop.id}'),
              style: AlongType.caption(p),
            ),
          ),
        if (trip?.wait != null) ...[
          const SizedBox(height: AlongSpace.s8),
          Text(
            l10n.activeTripWalkEta(trip!.wait!.walkEtaMinutes),
            key: const Key('active_trip_walk_eta'),
            style: AlongType.title(p),
          ),
          if (trip.wait!.approach == TripWaitApproach.stalled)
            Padding(
              padding: const EdgeInsets.only(top: AlongSpace.s4),
              child: DriveTag(
                key: const Key('active_trip_stalled_caption'),
                tone: DriveTagTone.warning,
                label: l10n.activeTripStalledCaption,
              ),
            ),
        ],
        if (showNaMe || fare != null) ...[
          const SizedBox(height: AlongSpace.s16),
          DrivePanel(
            padding: const EdgeInsets.all(AlongSpace.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showNaMe)
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: NaMeChip(
                            colour: naMeColourFromToken(naMe.colorToken),
                            shape: naMeShapeFromToken(naMe.shape),
                          ),
                        ),
                      ),
                      const SizedBox(width: AlongSpace.s8),
                      HoldButton(
                        key: const Key('active_trip_na_me'),
                        type: HoldButtonType.naMe,
                        onFired: () => context.push(
                          AppRoutes.naMe,
                          extra: NaMeRouteArgs(
                            tripId: args.tripId,
                            plateNumber: trip?.vehicle.plateNumber,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (showNaMe && fare != null)
                  const SizedBox(height: AlongSpace.s12),
                if (fare != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.activeTripFareLabel,
                              style: AlongType.caption(p),
                            ),
                            if (fare.$2 != null)
                              Text(
                                l10n.activeTripFeeCaption(fare.$2!, fare.$3!),
                                style: AlongType.caption(p),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AlongSpace.s8),
                      Text(
                        fare.$1,
                        key: const Key('active_trip_fare'),
                        style: AlongType.title(p).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
      [
        const SizedBox(height: AlongSpace.s16),
        ...primary,
        if (primary.isNotEmpty) const SizedBox(height: AlongSpace.s12),
        Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: AlongSpace.s8),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AlongSpace.s8),
          Text(
            l10n.errorGeneric,
            style: AlongType.caption(p).copyWith(color: p.danger),
          ),
        ],
        if (status == TripStatus.accepted) ...[
          const SizedBox(height: AlongSpace.s8),
          AlongButton(
            key: const Key('active_trip_release'),
            label: l10n.activeTripRelease,
            variant: AlongButtonVariant.tertiary,
            size: AlongButtonSize.secondary,
            visualState: busy,
            onPressed: state.isSubmitting
                ? null
                : () => controller.releaseMatch(),
          ),
        ],
      ],
    );
  }
}

/// Trip details scroll; the phase action and tiles stay pinned in reach.
class _PinnedPanel extends StatelessWidget {
  const _PinnedPanel({required this.parts});

  final (List<Widget>, List<Widget>) parts;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            // Room under the last row so it scrolls fully clear of the CTA.
            padding: const EdgeInsets.only(bottom: AlongSpace.s12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: parts.$1,
            ),
          ),
        ),
        ...parts.$2,
      ],
    );
  }
}
