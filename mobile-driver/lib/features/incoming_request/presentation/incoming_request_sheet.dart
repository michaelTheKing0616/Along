import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart'
    show DriverVoiceIntent, parseDriverVoice;
import 'package:along_design/along_design.dart' hide FareTier, formatMoney;
import 'package:along_design/along_design.dart' as design_fare show FareTier;
import 'package:flutter/material.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_notifier.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';

/// D-14 Incoming request full-screen sheet (doc 06).
class IncomingRequestSheet extends StatelessWidget {
  const IncomingRequestSheet({
    super.key,
    required this.state,
    required this.l10n,
    required this.onAccept,
    required this.onDecline,
  });

  final IncomingRequestState state;
  final AppLocalizations l10n;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final p = AlongPalette.of(context);
    final progress = state.requestTtlS == 0
        ? 0.0
        : state.remainingSeconds / state.requestTtlS;
    final fare = formatMoney(trip.totalFare);

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DriveSheet(
          key: const Key('incoming_request_card'),
          maxHeightFactor: 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _Countdown(progress: progress)),
                  const SizedBox(width: AlongSpace.s12),
                  Text(
                    l10n.incomingRequestCountdown(state.remainingSeconds),
                    key: const Key('incoming_request_seconds'),
                    style: AlongType.label(p).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AlongSpace.s12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.incomingRequestTitle,
                        style: AlongType.caption(p),
                      ),
                      const SizedBox(height: AlongSpace.s4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              fare,
                              key: const Key('incoming_request_fare'),
                              maxLines: 1,
                              style: AlongType.display(p).copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          if (trip.fare.unconfirmed)
                            TierPill(
                              key: const Key('incoming_request_estimate_pill'),
                              tier: _designTier(trip.fare.tier),
                            ),
                        ],
                      ),
                      Text(
                        l10n.incomingFareCaption(
                          _fareTierLabel(l10n, trip.fare.tier),
                        ),
                        style: AlongType.caption(p),
                      ),
                      const SizedBox(height: AlongSpace.s16),
                      DriveRoute(
                        fromLabel: state.trip.isRoamingHail
                            ? l10n.incomingRequestRoamingPickup
                            : l10n.incomingRequestPickup,
                        from: trip.board.name,
                        fromMeta: trip.approachBand != null
                            ? _approachBandLabel(l10n, trip.approachBand!)
                            : state.trip.isRoamingHail
                            ? l10n.incomingRequestRoamingPickupMeta
                            : null,
                        fromMetaKey: trip.approachBand != null
                            ? const Key('incoming_request_approach_band')
                            : null,
                        toLabel: l10n.incomingRequestDropoff,
                        to: trip.alight.name,
                      ),
                      const SizedBox(height: AlongSpace.s16),
                      DrivePanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AlongSpace.s16,
                          vertical: AlongSpace.s12,
                        ),
                        child: Row(
                          children: [
                            AlongIcon(AlongIcons.user, size: 20, color: p.ink),
                            const SizedBox(width: AlongSpace.s12),
                            Expanded(
                              child: Text(
                                l10n.incomingRequestRiderLine(
                                  trip.rider.displayName,
                                  trip.rider.rating.toStringAsFixed(1),
                                  trip.rider.tripCount,
                                ),
                                style: AlongType.label(p),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trip.dispatchAttempt > 1 ||
                          trip.womenOnly ||
                          trip.load.flagged) ...[
                        const SizedBox(height: AlongSpace.s12),
                        Wrap(
                          spacing: AlongSpace.s8,
                          runSpacing: AlongSpace.s8,
                          children: [
                            if (trip.dispatchAttempt > 1)
                              DriveTag(
                                key: const Key(
                                  'incoming_request_cascade_badge',
                                ),
                                tone: DriveTagTone.info,
                                label: l10n.incomingRequestCascade(
                                  trip.dispatchAttempt,
                                  state.maxCascade,
                                ),
                              ),
                            if (trip.womenOnly)
                              DriveTag(
                                tone: DriveTagTone.info,
                                icon: AlongIcons.female,
                                label: l10n.incomingRequestWomenOnly,
                              ),
                            if (trip.load.flagged)
                              DriveTag(
                                key: const Key('incoming_request_load_row'),
                                tone: DriveTagTone.warning,
                                icon: AlongIcons.luggage,
                                label: _loadLabel(l10n, trip.load),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AlongSpace.s12),
                      Text(
                        l10n.incomingRequestAlongFee(
                          formatMoney(state.alongFee),
                          formatCommissionPercent(state.commissionRate),
                        ),
                        style: AlongType.caption(p),
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: AlongSpace.s8),
                        Text(
                          l10n.errorGeneric,
                          style: AlongType.caption(p).copyWith(color: p.danger),
                        ),
                      ],
                      const SizedBox(height: AlongSpace.s12),
                      TextField(
                        key: const Key('incoming_voice_command'),
                        style: AlongType.body(p),
                        decoration: InputDecoration(
                          hintText: l10n.voiceCommandHint,
                          hintStyle: AlongType.bodyMuted(p),
                          isDense: true,
                          filled: true,
                          fillColor: p.recessed,
                          prefixIcon: AlongIcon(
                            AlongIcons.microphone,
                            size: 18,
                            color: p.muted,
                          ),
                          border: AlongCraft.input(BorderSide.none),
                          enabledBorder: AlongCraft.input(BorderSide.none),
                          focusedBorder: AlongCraft.input(
                            BorderSide(color: p.ink, width: 1.5),
                          ),
                        ),
                        onSubmitted: (value) {
                          final command = parseDriverVoice(value);
                          if (command?.intent == DriverVoiceIntent.accept) {
                            onAccept();
                          }
                          if (command?.intent == DriverVoiceIntent.decline) {
                            onDecline();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AlongSpace.s16),
              AlongButton(
                key: const Key('incoming_request_accept'),
                label: l10n.incomingAcceptFare(fare),
                visualState: state.isResponding
                    ? AlongButtonVisualState.loading
                    : AlongButtonVisualState.normal,
                onPressed: state.isResponding
                    ? null
                    : () {
                        AlongHaptics.confirm(context);
                        onAccept();
                      },
              ),
              const SizedBox(height: AlongSpace.s8),
              AlongButton(
                key: const Key('incoming_request_decline'),
                label: l10n.incomingRequestDecline,
                variant: AlongButtonVariant.tertiary,
                size: AlongButtonSize.secondary,
                onPressed: state.isResponding ? null : onDecline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _loadLabel(AppLocalizations l10n, TripLoadInfo load) {
    final size = load.size?.trim();
    final note = load.note?.trim();
    if (size != null && size.isNotEmpty && note != null && note.isNotEmpty) {
      return l10n.incomingRequestLoadDetail(size, note);
    }
    if (note != null && note.isNotEmpty) return note;
    return l10n.incomingRequestLoadDefault;
  }

  String _fareTierLabel(AppLocalizations l10n, FareTier tier) => switch (tier) {
    FareTier.throughFare => l10n.fareTierStandard,
    FareTier.summedLegs => l10n.fareTierCommunity,
    FareTier.driverProfile => l10n.fareTierProfile,
    FareTier.unconfirmed => l10n.fareTierEstimate,
  };

  design_fare.FareTier _designTier(FareTier tier) => switch (tier) {
    FareTier.throughFare => design_fare.FareTier.verified,
    FareTier.summedLegs => design_fare.FareTier.crowd,
    FareTier.driverProfile => design_fare.FareTier.candidate,
    FareTier.unconfirmed => design_fare.FareTier.estimate,
  };

  String _approachBandLabel(AppLocalizations l10n, TripApproachBand band) =>
      switch (band) {
        TripApproachBand.under2 => l10n.incomingRequestApproachBandUnder2,
        TripApproachBand.m2_5 => l10n.incomingRequestApproachBandM2_5,
        TripApproachBand.over5 => l10n.incomingRequestApproachBandOver5,
      };
}

/// Time left to accept, as a draining squircle track (accent on recessed).
class _Countdown extends StatelessWidget {
  const _Countdown({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return AlongCraft.clip(
      corner: AlongRadius.xs.x,
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: p.recessed),
            AnimatedFractionallySizedBox(
              duration: AlongMoves.roll.of(context),
              curve: AlongMoves.roll.curve,
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0, 1).toDouble(),
              child: ColoredBox(color: p.accent),
            ),
          ],
        ),
      ),
    );
  }
}
