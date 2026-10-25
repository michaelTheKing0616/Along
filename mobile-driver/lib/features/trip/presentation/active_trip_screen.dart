import 'package:along_core/along_core.dart'
    show
        TripEtaStop,
        TripStatus,
        TripWaitApproach,
        computeAlongCommission,
        formatMoney;
import 'package:along_design/along_design.dart' hide formatMoney;
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
import 'package:mobile_driver/features/trip/presentation/active_trip_controller.dart';
import 'package:mobile_driver/features/trip/presentation/extend_trip_sheet.dart';
import 'package:mobile_driver/features/trip/presentation/trip_chat.dart';
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AlongSpace.s16),
              clipBehavior: Clip.antiAlias,
              decoration: AlongCraft.fill(
                AlongColors.surface0,
                corner: AlongRadius.sheet.x,
                top: true,
              ),
              child: SafeArea(
                top: false,
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(riderName, style: AlongText.heading2),
                              const SizedBox(height: AlongSpace.s8),
                              Text(
                                l10n.activeTripBoardAlight(
                                  boardName,
                                  alightName,
                                ),
                                style: AlongText.body,
                              ),
                              const SizedBox(height: AlongSpace.s8),
                              Text(
                                trip?.eta?.driverLine ?? 'Calculating…',
                                key: const Key('active_trip_eta'),
                                style: AlongText.body,
                              ),
                              for (final stop
                                  in trip?.eta?.stops ?? const <TripEtaStop>[])
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AlongSpace.s4,
                                  ),
                                  child: Text(
                                    '${stop.name} · ${stop.label}',
                                    key: Key('active_trip_stop_${stop.id}'),
                                    style: AlongText.caption,
                                  ),
                                ),
                              if (trip?.wait != null) ...[
                                const SizedBox(height: AlongSpace.s8),
                                Text(
                                  l10n.activeTripWalkEta(
                                    trip!.wait!.walkEtaMinutes,
                                  ),
                                  key: const Key('active_trip_walk_eta'),
                                  style: AlongText.numericM,
                                ),
                                if (trip.wait!.approach ==
                                    TripWaitApproach.stalled)
                                  Text(
                                    l10n.activeTripStalledCaption,
                                    key: const Key(
                                      'active_trip_stalled_caption',
                                    ),
                                    style: AlongText.caption.copyWith(
                                      color: AlongColors.semanticWarning,
                                    ),
                                  ),
                              ],
                              if (naMe != null &&
                                  (status == TripStatus.accepted ||
                                      status == TripStatus.boarded ||
                                      status == TripStatus.transfer)) ...[
                                const SizedBox(height: AlongSpace.s12),
                                Row(
                                  children: [
                                    NaMeChip(
                                      colour: naMeColourFromToken(
                                        naMe.colorToken,
                                      ),
                                      shape: naMeShapeFromToken(naMe.shape),
                                    ),
                                    const SizedBox(width: AlongSpace.s8),
                                    HoldButton(
                                      key: const Key('active_trip_na_me'),
                                      type: HoldButtonType.naMe,
                                      onFired: () => context.push(
                                        AppRoutes.naMe,
                                        extra: NaMeRouteArgs(
                                          tripId: args.tripId,
                                          plateNumber:
                                              trip?.vehicle.plateNumber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (fare != null && configAsync.hasValue) ...[
                                const SizedBox(height: AlongSpace.s12),
                                Text(
                                  l10n.incomingRequestFareLine(
                                    formatMoney(fare),
                                    l10n.fareTierStandard,
                                  ),
                                  style: AlongText.bodyStrong,
                                ),
                                Text(
                                  l10n.incomingRequestAlongFee(
                                    formatMoney(
                                      computeAlongCommission(
                                        fare,
                                        configAsync.value!.commissionRate,
                                      ),
                                    ),
                                    (configAsync.value!.commissionRate * 100)
                                        .toStringAsFixed(1),
                                  ),
                                  style: AlongText.caption.copyWith(
                                    color: AlongColors.ink500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AlongSpace.s16),
                              if (chat != null) ...[
                                AlongUnreadBadge(
                                  count: chat.unread,
                                  child: AlongButton(
                                    key: const Key('active_trip_message'),
                                    label: riderName.isEmpty
                                        ? 'Message rider'
                                        : 'Message $riderName',
                                    variant: AlongButtonVariant.secondary,
                                    onPressed: () => openTripChat(
                                      context,
                                      ref,
                                      tripId: args.tripId,
                                      otherName: riderName.isEmpty
                                          ? 'Rider'
                                          : riderName,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AlongSpace.s8),
                              ],
                              AlongButton(
                                key: const Key('active_trip_seat_map'),
                                label: l10n.seatMapTitle,
                                variant: AlongButtonVariant.secondary,
                                onPressed: () =>
                                    context.push(AppRoutes.seatBoard),
                              ),
                              const SizedBox(height: AlongSpace.s8),
                              if (status == TripStatus.accepted) ...[
                                AlongButton(
                                  key: const Key('active_trip_release'),
                                  label: l10n.activeTripRelease,
                                  variant: AlongButtonVariant.secondary,
                                  visualState: state.isSubmitting
                                      ? AlongButtonVisualState.loading
                                      : AlongButtonVisualState.normal,
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => controller.releaseMatch(),
                                ),
                                const SizedBox(height: AlongSpace.s8),
                              ],
                              if (status == TripStatus.accepted)
                                AlongButton(
                                  key: const Key('active_trip_enter_pin'),
                                  label: 'Enter pickup PIN',
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      fullscreenDialog: true,
                                      builder: (_) => AlongPinEntryScreen(
                                        riderName: riderName.isEmpty
                                            ? 'your rider'
                                            : riderName.split(' ').first,
                                        onSubmit: controller.verifyPin,
                                        onGetHelp: switch (ref
                                            .read(appConfigProvider)
                                            .supportUri) {
                                          final uri? => () => launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
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
                                  ),
                                ),
                              if (status == TripStatus.transfer)
                                AlongButton(
                                  key: const Key('active_trip_mark_boarded'),
                                  label: l10n.manifestMarkBoarded,
                                  variant: AlongButtonVariant.secondary,
                                  visualState: state.isSubmitting
                                      ? AlongButtonVisualState.loading
                                      : AlongButtonVisualState.normal,
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => controller.markBoarded(),
                                ),
                              if (status == TripStatus.boarded)
                                AlongButton(
                                  key: const Key('active_trip_start'),
                                  label: l10n.activeTripStart,
                                  visualState: state.isSubmitting
                                      ? AlongButtonVisualState.loading
                                      : AlongButtonVisualState.normal,
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => controller.startTrip(),
                                ),
                              if (status == TripStatus.inTransit) ...[
                                digitalEnabled.maybeWhen(
                                  data: (enabled) {
                                    if (!enabled) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AlongSpace.s8,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: AlongButton(
                                              key: const Key(
                                                'active_trip_request_payment',
                                              ),
                                              label: l10n.requestPayment,
                                              variant:
                                                  AlongButtonVariant.yellow,
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
                                          Expanded(
                                            child: AlongButton(
                                              key: const Key(
                                                'active_trip_complete',
                                              ),
                                              label: l10n.activeTripComplete,
                                              visualState: state.isSubmitting
                                                  ? AlongButtonVisualState
                                                        .loading
                                                  : AlongButtonVisualState
                                                        .normal,
                                              onPressed: state.isSubmitting
                                                  ? null
                                                  : () => controller
                                                        .completeTrip(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  orElse: () => const SizedBox.shrink(),
                                ),
                                AlongButton(
                                  key: const Key('active_trip_extend'),
                                  label: l10n.extendTripTitle,
                                  variant: AlongButtonVariant.secondary,
                                  onPressed: () => ExtendTripSheet.show(
                                    context,
                                    tripId: args.tripId,
                                  ),
                                ),
                                if (digitalEnabled.maybeWhen(
                                  data: (enabled) => !enabled,
                                  orElse: () => true,
                                )) ...[
                                  const SizedBox(height: AlongSpace.s8),
                                  AlongButton(
                                    key: const Key('active_trip_complete'),
                                    label: l10n.activeTripComplete,
                                    visualState: state.isSubmitting
                                        ? AlongButtonVisualState.loading
                                        : AlongButtonVisualState.normal,
                                    onPressed: state.isSubmitting
                                        ? null
                                        : () => controller.completeTrip(),
                                  ),
                                ],
                              ],
                              if (state.errorMessage != null) ...[
                                const SizedBox(height: AlongSpace.s8),
                                Text(
                                  l10n.errorGeneric,
                                  style: AlongText.caption.copyWith(
                                    color: AlongColors.semanticDanger,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AlongSpace.s8),
                              AlongButton(
                                key: const Key('active_trip_report'),
                                label: l10n.activeTripReport,
                                variant: AlongButtonVariant.secondary,
                                onPressed: () => context.push(
                                  AppRoutes.reportIncident,
                                  extra: args.tripId,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
