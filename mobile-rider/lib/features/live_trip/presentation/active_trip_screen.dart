import 'dart:async';

import 'package:along_core/along_core.dart'
    show TripEta, TripEtaStop, TripStatus, TripSummary;
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart' hide TransportMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/tenant/tenant_providers.dart';
import 'package:mobile_rider/features/live_trip/domain/payments_config.dart';
import 'package:mobile_rider/features/live_trip/domain/live_trip_config.dart';
import 'package:mobile_rider/features/live_trip/presentation/driver_contact.dart';
import 'package:mobile_rider/features/live_trip/presentation/extend_trip_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/live_trip_controller.dart';
import 'package:mobile_rider/features/live_trip/presentation/na_me_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/pay_driver_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/trip_chat.dart';
import 'package:mobile_rider/features/live_trip/presentation/trip_complete_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/trip_receipt_page.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
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
  /// PIN minted by "Get a new PIN" until the trip view catches up.
  String? _freshPin;

  Future<void> _newPin(String tripId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await ref
          .read(tripsRepositoryProvider)
          .regenerateTripPin(tripId);
      if (!mounted) return;
      if (r.pin.isNotEmpty) setState(() => _freshPin = r.pin);
      AlongHaptics.success(context);
      if (!r.regenerated) {
        messenger.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).tripPinTooSoon)),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).tripPinFailed)),
      );
    }
  }

  LiveTripArgs get _args =>
      LiveTripArgs(tripId: widget.trip.tripId, initialTrip: widget.trip);

  final _silentTaps = SilentTapSeries();
  final _safeWord = TextEditingController();
  (double, double)? _anchor;
  DateTime? _stationarySince;
  DateTime _lastConfirm = DateTime.now();
  DateTime? _promptSince;
  var _escalated = false;
  TripEta? _lastEta;
  TripEta? _prevEta;

  /// Keeps the reading before the current one so a slowdown can be shown.
  void _trackEta(TripEta? eta) {
    if (eta == null || eta.updatedAt == _lastEta?.updatedAt) return;
    _prevEta = _lastEta;
    _lastEta = eta;
  }

  /// Seconds until the driver reaches the pickup, from the live estimator.
  int? _pickupSeconds(TripSummary trip) {
    final eta = trip.eta;
    final pickup = eta != null && eta.isReady ? eta.pickup : null;
    if (pickup != null) return pickup.lowS;
    final minutes = trip.etaMinutes;
    return minutes == null ? null : minutes * 60;
  }

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

  static bool _chatLive(TripStatus status) =>
      status == TripStatus.accepted ||
      status == TripStatus.boarded ||
      status == TripStatus.inTransit;

  /// The Na Me moment: plays only on a confirmed match (trip turned
  /// boarded), closes itself in under 1.2 s, and needs no rider tap.
  void _celebrateBoarding(TripSummary trip) {
    final l10n = AppLocalizations.of(context);
    final nav = Navigator.of(context, rootNavigator: true);
    final closeNaMe = NaMeScreen.isOpen.value;
    nav.push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (context, _, _) => AlongNaMeCelebration(
          pairing: AlongNaMeChoice(
            colorToken: trip.naMe.colorToken,
            shape: trip.naMe.shape,
            label: trip.naMe.label,
          ),
          title: l10n.tripMatchedTitle,
          subtitle: l10n.tripMatchedBody(
            trip.driver.displayName.split(' ').first,
          ),
          onChime: () => unawaited(playNaMeChime()),
          onDone: () {
            nav.pop();
            if (closeNaMe && NaMeScreen.isOpen.value) nav.maybePop();
          },
        ),
      ),
    );
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
      if (previous?.trip.status == TripStatus.accepted &&
          next.trip.status == TripStatus.boarded &&
          mounted) {
        _celebrateBoarding(next.trip);
      }
      if (next.showCompleteSheet &&
          previous?.showCompleteSheet != next.showCompleteSheet &&
          mounted) {
        TripCompleteSheet.show(
          context,
          trip: next.trip,
          receipt: next.completeReceipt,
          onFinished: () {
            controller.acknowledgeCompleteSheet();
            // The sheet pops itself right after this; push once it is gone.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              TripReceiptPage.show(
                context,
                trip: next.trip,
                receipt: next.completeReceipt,
              );
            });
          },
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

    final showNaMe =
        liveTrip.status == TripStatus.accepted ||
        liveTrip.status == TripStatus.boarded;
    final colour = naMeColourFromToken(liveTrip.naMe.colorToken);
    final shape = naMeShapeFromToken(liveTrip.naMe.shape);
    _trackEta(liveTrip.eta);
    final pickupSeconds = liveTrip.status == TripStatus.accepted
        ? _pickupSeconds(liveTrip)
        : null;
    // Preloaded for the whole live trip so the sheet opens on a full thread.
    final chat = _chatLive(liveTrip.status)
        ? ref.watch(tripChatProvider(liveTrip.tripId))
        : null;
    chat?.onIncoming = () {
      if (mounted) AlongHaptics.tick(context);
    };
    final car = [
      liveTrip.vehicle.color,
      liveTrip.vehicle.makeModel,
    ].where((part) => part.trim().isNotEmpty).join(' ');
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

    final palette = AlongPalette.of(context);
    final toPickup = liveTrip.status == TripStatus.accepted;
    final driverPoint = liveTrip.live?.driver?.point;
    final mapFrom = toPickup
        ? (driverPoint ?? liveTrip.live?.rider?.point)
        : liveTrip.board.location;
    final mapTo = toPickup ? liveTrip.board.location : liveTrip.alight.location;

    return TripSheetScaffold(
      mapFraction: 0.38,
      leading: AlongMapButton(
        key: const Key('active_trip_share'),
        icon: AlongIcons.share,
        tooltip: l10n.activeTripShare,
        onPressed: () =>
            ShareTripSheet.show(context, journeyId: liveTrip.journeyId),
      ),
      trailing: HoldButton(
        key: const Key('active_trip_sos'),
        type: HoldButtonType.sos,
        holdDuration: holdDuration,
        onFired: () => context.push(
          AppRoutes.sosActive,
          extra: SosActiveRouteArgs(trip: liveTrip),
        ),
      ),
      map: (top, bottom) => VehicleMarkerPanel(
        from: mapFrom,
        to: mapTo,
        vehicle: driverPoint,
        fromLabel: toPickup ? liveTrip.driver.displayName : liveTrip.board.name,
        toLabel: toPickup ? liveTrip.board.name : liveTrip.alight.name,
        modeCode: liveTrip.modeCode,
        semanticLabel: liveTrip.alight.name,
        topInset: top,
        bottomInset: bottom,
      ),
      children: [
        if (prompt != GuardianPrompt.none && prompt != GuardianPrompt.missed)
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
            decoration: InputDecoration(hintText: l10n.guardianSafeWordHint),
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
              KeyedSubtree(
                key: const Key('active_trip_eta'),
                child: pickupSeconds != null
                    ? AlongHandoffPanel(
                        key: const Key('active_trip_handoff'),
                        secondsAway: pickupSeconds,
                        driverName: liveTrip.driver.displayName,
                        plate: liveTrip.vehicle.plateNumber,
                        car: car,
                        pickupPoint: liveTrip.board.name,
                        pin: _freshPin ?? liveTrip.handoff?.pin,
                        onNewPin: liveTrip.handoff?.pin == null
                            ? null
                            : () => _newPin(liveTrip.tripId),
                        onCall: liveTrip.handoff?.contactAvailable == true
                            ? () => contactDriver(
                                context,
                                ref,
                                tripId: liveTrip.tripId,
                                sms: false,
                              )
                            : null,
                        unread: chat?.unread ?? 0,
                        onMessage: chat == null
                            ? null
                            : () => openTripChat(
                                context,
                                ref,
                                tripId: liveTrip.tripId,
                                otherName: liveTrip.driver.displayName,
                              ),
                      )
                    : AlongLiveEtaPanel(
                        eta: liveTrip.eta,
                        previous: _prevEta,
                        destination: liveTrip.alight.name,
                        failed: state.livePaused,
                      ),
              ),
              if (pickupSeconds == null)
                for (final stop in liveTrip.eta?.stops ?? const <TripEtaStop>[])
                  Padding(
                    padding: const EdgeInsets.only(top: AlongSpace.s4),
                    child: Text(
                      '${stop.name} · ${stop.label}',
                      key: Key('active_trip_stop_${stop.id}'),
                      style: AlongType.caption(AlongPalette.of(context)),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: AlongSpace.s16),
        Row(
          key: const Key('active_trip_leg_timeline'),
          children: [
            TripModeTile(modeCode: liveTrip.modeCode, size: 40),
            const SizedBox(width: AlongSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tripCompleteRoute(
                      liveTrip.board.name,
                      liveTrip.alight.name,
                    ),
                    style: AlongType.label(palette),
                  ),
                  Text(liveTrip.modeLabel, style: AlongType.caption(palette)),
                ],
              ),
            ),
            const SizedBox(width: AlongSpace.s8),
            Text(formatAppMoney(ref, fare), style: AlongType.label(palette)),
          ],
        ),
        if (pickupSeconds == null || showNaMe) ...[
          const SizedBox(height: AlongSpace.s16),
          Row(
            children: [
              if (showNaMe) ...[
                NaMeChip(colour: colour, shape: shape),
                const SizedBox(width: AlongSpace.s12),
              ],
              Expanded(
                child: pickupSeconds == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            liveTrip.driver.displayName,
                            style: AlongType.label(palette),
                          ),
                          Text(
                            [
                              liveTrip.vehicle.plateNumber,
                              car,
                            ].where((s) => s.isNotEmpty).join(' · '),
                            style: AlongType.caption(palette),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              if (showNaMe)
                HoldButton(
                  key: const Key('active_trip_na_me'),
                  type: HoldButtonType.naMe,
                  onFired: () => context.push(
                    AppRoutes.naMe,
                    extra: NaMeRouteArgs(
                      tripId: liveTrip.tripId,
                      driverName: liveTrip.driver.displayName,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (digitalEnabled) ...[
          const SizedBox(height: AlongSpace.s16),
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
        if (chat != null && pickupSeconds == null) ...[
          const SizedBox(height: AlongSpace.s12),
          AlongUnreadBadge(
            count: chat.unread,
            child: AlongButton(
              key: const Key('active_trip_message'),
              label: l10n.activeTripMessage(liveTrip.driver.displayName),
              variant: AlongButtonVariant.secondary,
              onPressed: () => openTripChat(
                context,
                ref,
                tripId: liveTrip.tripId,
                otherName: liveTrip.driver.displayName,
              ),
            ),
          ),
        ],
        const SizedBox(height: AlongSpace.s8),
        Row(
          children: [
            Expanded(
              child: AlongButton(
                key: const Key('active_trip_extend'),
                label: l10n.activeTripExtend,
                variant: AlongButtonVariant.tertiary,
                onPressed:
                    liveTrip.status == TripStatus.inTransit ||
                        liveTrip.status == TripStatus.boarded
                    ? () => ExtendTripSheet.show(context, trip: liveTrip)
                    : null,
              ),
            ),
            Expanded(
              child: AlongButton(
                key: const Key('active_trip_report'),
                label: l10n.activeTripReport,
                variant: AlongButtonVariant.tertiary,
                onPressed: () => context.push(
                  AppRoutes.reportIncident,
                  extra: liveTrip.tripId,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
