import 'package:along_core/along_core.dart' show TripStatus, TripSummary, TripWaitApproach, computeAlongCommission, formatMoney;
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/trip/domain/driver_trip_config.dart';
import 'package:mobile_driver/features/payments/data/payments_providers.dart';
import 'package:mobile_driver/features/payments/presentation/payment_request_controller.dart';
import 'package:mobile_driver/features/payments/presentation/payment_request_screen.dart';
import 'package:mobile_driver/features/trip/presentation/active_trip_controller.dart';
import 'package:mobile_driver/features/trip/presentation/extend_trip_sheet.dart';
import 'package:mobile_driver/features/trip/presentation/trip_complete_sheet.dart';
import 'package:mobile_driver/features/trip/presentation/na_me_screen.dart';
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
        final paidDigitally = next.digitalPayment != null ||
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
    final controller =
        ref.read(activeTripControllerFamilyProvider(args).notifier);
    final appConfig = ref.watch(appConfigProvider);
    final digitalEnabled = ref.watch(digitalPaymentsEnabledProvider);

    final trip = state.trip;
    final entry = state.entry;
    final status = trip?.status ?? entry?.status;
    final naMe = trip?.naMe ?? entry?.naMe;
    final riderName = trip?.rider.displayName ?? entry?.rider.displayName ?? '';
    final boardName = trip?.board.name ?? entry?.board.name ?? '';
    final alightName = trip?.alight.name ?? '';
    final fare = trip?.totalFare;

    return Scaffold(
      key: const Key('active_trip_screen'),
      body: Stack(
        children: [
          Positioned.fill(
            child: AlongMap(
              key: const Key('active_trip_map'),
              styleUrl: appConfig.tilesBaseUrl == null
                  ? null
                  : '${appConfig.tilesBaseUrl}/styles/along-light.json',
              initialCameraPosition: MapCamera.abujaDefault(),
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
                onFired: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.sosPlaceholder)),
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
              decoration: const BoxDecoration(
                color: AlongColors.surface0,
                borderRadius: BorderRadius.vertical(top: AlongRadius.sheet),
              ),
              child: SafeArea(
                top: false,
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(riderName, style: AlongText.heading2),
                          const SizedBox(height: AlongSpace.s8),
                          Text(
                            l10n.activeTripBoardAlight(boardName, alightName),
                            style: AlongText.body,
                          ),
                          if (trip?.wait != null) ...[
                            const SizedBox(height: AlongSpace.s8),
                            Text(
                              l10n.activeTripWalkEta(trip!.wait!.walkEtaMinutes),
                              key: const Key('active_trip_walk_eta'),
                              style: AlongText.numericM,
                            ),
                            if (trip.wait!.approach == TripWaitApproach.stalled)
                              Text(
                                l10n.activeTripStalledCaption,
                                key: const Key('active_trip_stalled_caption'),
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
                                  colour: naMeColourFromToken(naMe.colorToken),
                                  shape: naMeShapeFromToken(naMe.shape),
                                ),
                                const SizedBox(width: AlongSpace.s8),
                                HoldButton(
                                  key: const Key('active_trip_na_me'),
                                  type: HoldButtonType.naMe,
                                  onFired: () => context.push(
                                    AppRoutes.naMe,
                                    extra: NaMeRouteArgs(tripId: args.tripId),
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
                          if (status == TripStatus.accepted ||
                              status == TripStatus.transfer)
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
                                if (!enabled) return const SizedBox.shrink();
                                return Column(
                                  children: [
                                    AlongButton(
                                      key: const Key('active_trip_request_payment'),
                                      label: l10n.requestPayment,
                                      variant: AlongButtonVariant.secondary,
                                      onPressed: () => context.push(
                                        AppRoutes.paymentRequest,
                                        extra: PaymentRequestArgs(
                                          tripId: args.tripId,
                                          riderName: riderName,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AlongSpace.s8),
                                  ],
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
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: AlongSpace.s8),
                            Text(
                              l10n.errorGeneric,
                              style: AlongText.caption.copyWith(
                                color: AlongColors.semanticDanger,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
