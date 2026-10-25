import 'package:along_core/along_core.dart'
    show TripEtaStop, TripStatus, TripSummary;
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart' hide TransportMode;
import 'package:along_design/along_design.dart' as design show TransportMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/tenant/tenant_providers.dart';
import 'package:mobile_rider/features/live_trip/domain/payments_config.dart';
import 'package:mobile_rider/features/live_trip/domain/live_trip_config.dart';
import 'package:mobile_rider/features/live_trip/presentation/extend_trip_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/live_trip_controller.dart';
import 'package:mobile_rider/features/live_trip/presentation/na_me_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/pay_driver_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/trip_complete_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/vehicle_marker_panel.dart';
import 'package:mobile_rider/features/safety/presentation/guardian_screen.dart';
import 'package:mobile_rider/features/safety/presentation/share_trip_sheet.dart';
import 'package:mobile_rider/features/safety/presentation/sos_active_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:go_router/go_router.dart';

/// R-13 Active trip — map follow, SOS placeholder, LegTimeline, extend/complete.
class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key, required this.trip});

  final TripSummary trip;

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  LiveTripArgs get _args =>
      LiveTripArgs(tripId: widget.trip.tripId, initialTrip: widget.trip);

  final _silentTaps = SilentTapSeries();
  final _safeWord = TextEditingController();
  (double, double)? _anchor;
  DateTime? _stationarySince;
  DateTime _lastConfirm = DateTime.now();
  DateTime? _promptSince;
  var _escalated = false;

  @override
  void dispose() {
    _safeWord.dispose();
    super.dispose();
  }

  void _track(TripSummary trip) {
    final driver = trip.live?.driver;
    if (driver == null) return;
    final now = DateTime.now();
    final anchor = _anchor;
    if (anchor == null) {
      _anchor = (driver.lat, driver.lng);
      _stationarySince = now;
      return;
    }
    final moved = distanceMeters(
      lat1: anchor.$1,
      lng1: anchor.$2,
      lat2: driver.lat,
      lng2: driver.lng,
    );
    if (moved > 30) {
      _anchor = (driver.lat, driver.lng);
      _stationarySince = now;
    }
  }

  GuardianPrompt _promptFor(GuardianPrefs prefs, TripSummary trip) {
    if (!prefs.enabled) return GuardianPrompt.none;
    _track(trip);
    final driver = trip.live?.driver;
    final rider = trip.live?.rider;
    double? meters;
    if (driver != null && rider != null) {
      meters = distanceMeters(
        lat1: rider.lat,
        lng1: rider.lng,
        lat2: driver.lat,
        lng2: driver.lng,
      );
    }
    final now = DateTime.now();
    return evaluateGuardian(
      prefs: prefs,
      riderToDriverMeters: meters,
      stationaryFor: _stationarySince == null
          ? Duration.zero
          : now.difference(_stationarySince!),
      sinceLastConfirm: now.difference(_lastConfirm),
      promptOpen: _promptSince != null,
      promptOpenFor: _promptSince == null
          ? Duration.zero
          : now.difference(_promptSince!),
    );
  }

  void _raiseSilent(TripSummary trip) {
    context.push(AppRoutes.sosActive, extra: SosActiveRouteArgs(trip: trip));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(liveTripControllerFamilyProvider(_args));
    final controller = ref.read(
      liveTripControllerFamilyProvider(_args).notifier,
    );
    final liveTrip = state.trip;
    final digitalEnabled = ref
        .watch(digitalPaymentsEnabledProvider)
        .maybeWhen(data: (value) => value, orElse: () => false);

    ref.listen(liveTripControllerFamilyProvider(_args), (previous, next) {
      if (next.showCompleteSheet &&
          previous?.showCompleteSheet != next.showCompleteSheet &&
          mounted) {
        TripCompleteSheet.show(
          context,
          trip: next.trip,
          receipt: next.completeReceipt,
          onFinished: controller.acknowledgeCompleteSheet,
        );
      }
      if (next.pendingExtension != null &&
          previous?.pendingExtension?.extensionId !=
              next.pendingExtension?.extensionId &&
          mounted) {
        IncomingExtensionSheet.show(
          context,
          trip: next.trip,
          proposal: next.pendingExtension!,
          onResponded: (_) => controller.clearPendingExtension(),
        );
      }
    });

    final heading = liveTrip.live?.driver?.headingDegrees;
    final showNaMe =
        liveTrip.status == TripStatus.accepted ||
        liveTrip.status == TripStatus.boarded;
    final colour = naMeColourFromToken(liveTrip.naMe.colorToken);
    final shape = naMeShapeFromToken(liveTrip.naMe.shape);
    final etaLabel = liveTrip.eta?.headline ?? 'Calculating…';
    final fare = liveTrip.totalFare;
    final holdDuration = ref
        .watch(liveTripConfigProvider)
        .maybeWhen(
          data: (cfg) => cfg.sosHoldDurationMs,
          orElse: () => const Duration(milliseconds: 600),
        );
    final prefs =
        ref.watch(guardianPrefsProvider).valueOrNull ?? GuardianPrefs.disabled;
    final prompt = _promptFor(prefs, liveTrip);
    if (prompt == GuardianPrompt.missed && !_escalated) {
      _escalated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _raiseSilent(liveTrip);
      });
    } else if (prompt != GuardianPrompt.none &&
        prompt != GuardianPrompt.missed) {
      _promptSince ??= DateTime.now();
    } else if (prompt == GuardianPrompt.none) {
      _promptSince = null;
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: VehicleMarkerPanel(
              headingDegrees: heading,
              showWalkingLine: false,
              lat: liveTrip.live?.driver?.lat ?? liveTrip.live?.rider?.lat,
              lng: liveTrip.live?.driver?.lng ?? liveTrip.live?.rider?.lng,
            ),
          ),
          Positioned(
            top: AlongSpace.s16,
            right: AlongSpace.s16,
            child: HoldButton(
              key: const Key('active_trip_sos'),
              type: HoldButtonType.sos,
              holdDuration: holdDuration,
              onFired: () => context.push(
                AppRoutes.sosActive,
                extra: SosActiveRouteArgs(trip: liveTrip),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prompt != GuardianPrompt.none &&
                      prompt != GuardianPrompt.missed)
                    GuardianCheckCard(
                      title: l10n.guardianTitle,
                      body: switch (prompt) {
                        GuardianPrompt.offRoute => l10n.guardianOffRouteBody,
                        GuardianPrompt.longStop => l10n.guardianLongStopBody,
                        GuardianPrompt.checkIn => l10n.guardianCheckInBody,
                        GuardianPrompt.missed => l10n.guardianMissedBody,
                        GuardianPrompt.none => '',
                      },
                      confirmLabel: l10n.guardianOk,
                      onConfirm: () => setState(() {
                        _lastConfirm = DateTime.now();
                        _promptSince = null;
                        _escalated = false;
                      }),
                    ),
                  if (prefs.safeWord.trim().isNotEmpty)
                    TextField(
                      key: const Key('active_trip_safe_word'),
                      controller: _safeWord,
                      decoration: InputDecoration(
                        hintText: l10n.guardianSafeWordHint,
                      ),
                      onSubmitted: (value) {
                        if (!safeWordMatches(prefs.safeWord, value)) return;
                        _safeWord.clear();
                        _raiseSilent(liveTrip);
                      },
                    ),
                  GestureDetector(
                    onTap: () {
                      if (!prefs.enabled) return;
                      if (_silentTaps.register(DateTime.now())) {
                        _raiseSilent(liveTrip);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'In transit · $etaLabel · ${formatAppMoney(ref, liveTrip.totalFare)} Standard fare',
                          key: const Key('active_trip_eta'),
                          style: AlongText.heading2,
                        ),
                        for (final stop in liveTrip.eta?.stops ?? const <TripEtaStop>[])
                          Padding(
                            padding: const EdgeInsets.only(top: AlongSpace.s4),
                            child: Text(
                              '${stop.name} · ${stop.label}',
                              key: Key('active_trip_stop_${stop.id}'),
                              style: AlongText.caption,
                            ),
                          ),
                      ],
                    ),
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
                  if (digitalEnabled) ...[
                    const SizedBox(height: AlongSpace.s12),
                    Row(
                      children: [
                        Expanded(
                          child: AlongButton(
                            key: const Key('active_trip_scan'),
                            label: l10n.activeTripScan,
                            variant: AlongButtonVariant.secondary,
                            onPressed: () => context.push(AppRoutes.scanToPay),
                          ),
                        ),
                        const SizedBox(width: AlongSpace.s8),
                        Expanded(
                          child: AlongButton(
                            key: const Key('active_trip_pay'),
                            label: l10n.payDriverCta(
                              formatAppMoney(ref, liveTrip.totalFare),
                            ),
                            variant: AlongButtonVariant.yellow,
                            onPressed: () => PayDriverSheet.show(
                              context,
                              trip: liveTrip,
                              autoInitiate: true,
                            ),
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
                          onPressed:
                              liveTrip.status == TripStatus.inTransit ||
                                  liveTrip.status == TripStatus.boarded
                              ? () => ExtendTripSheet.show(
                                  context,
                                  trip: liveTrip,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: AlongSpace.s8),
                      Expanded(
                        child: AlongButton(
                          key: const Key('active_trip_share'),
                          label: l10n.activeTripShare,
                          variant: AlongButtonVariant.secondary,
                          onPressed: () => ShareTripSheet.show(
                            context,
                            journeyId: liveTrip.journeyId,
                          ),
                        ),
                      ),
                      const SizedBox(width: AlongSpace.s8),
                      Expanded(
                        child: AlongButton(
                          key: const Key('active_trip_report'),
                          label: l10n.activeTripReport,
                          variant: AlongButtonVariant.secondary,
                          onPressed: () => context.push(
                            AppRoutes.reportIncident,
                            extra: liveTrip.tripId,
                          ),
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
