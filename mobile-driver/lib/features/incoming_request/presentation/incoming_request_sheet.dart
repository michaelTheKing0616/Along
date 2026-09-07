import 'dart:math' as math;

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide FareTier, formatMoney;
import 'package:along_design/src/utils/fare_tier.dart' as design_fare;
import 'package:flutter/material.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_notifier.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

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
    final theme = Theme.of(context);
    final progress = state.requestTtlS == 0
        ? 0.0
        : state.remainingSeconds / state.requestTtlS;

    return Material(
      color: AlongColors.surface0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    l10n.incomingRequestTitle,
                    style: AlongText.heading2,
                  ),
                  if (state.trip.dispatchAttempt > 1) ...[
                    const SizedBox(width: AlongSpace.s8),
                    Container(
                      key: const Key('incoming_request_cascade_badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AlongSpace.s8,
                        vertical: AlongSpace.s4,
                      ),
                      decoration: BoxDecoration(
                        color: AlongColors.semanticInfoTint,
                        borderRadius: BorderRadius.circular(AlongRadius.xs.x),
                      ),
                      child: Text(
                        l10n.incomingRequestCascade(
                          state.trip.dispatchAttempt,
                          state.maxCascade,
                        ),
                        style: AlongText.caption.copyWith(
                          color: AlongColors.semanticInfo,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CustomPaint(
                      painter: _CountdownRingPainter(progress: progress),
                      child: Center(
                        child: Text(
                          l10n.incomingRequestCountdown(state.remainingSeconds),
                          style: AlongText.caption,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AlongSpace.s12),
              Text(
                l10n.incomingRequestRiderLine(
                  trip.rider.displayName,
                  trip.rider.rating.toStringAsFixed(1),
                  trip.rider.tripCount,
                ),
                style: AlongText.bodyStrong,
              ),
              if (trip.womenOnly) ...[
                const SizedBox(height: AlongSpace.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AlongSpace.s8,
                    vertical: AlongSpace.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AlongColors.semanticInfoTint,
                    borderRadius: BorderRadius.circular(AlongRadius.xs.x),
                  ),
                  child: Text(
                    l10n.incomingRequestWomenOnly,
                    style: AlongText.caption.copyWith(
                      color: AlongColors.semanticInfo,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AlongSpace.s16),
              _LocationRow(
                icon: Icons.trip_origin,
                label: state.trip.isRoamingHail
                    ? l10n.incomingRequestRoamingPickup
                    : l10n.incomingRequestPickup,
                value: trip.board.name,
                meta: trip.approachBand != null
                    ? _approachBandLabel(l10n, trip.approachBand!)
                    : state.trip.isRoamingHail
                        ? l10n.incomingRequestRoamingPickupMeta
                        : null,
                metaKey: trip.approachBand != null
                    ? const Key('incoming_request_approach_band')
                    : null,
              ),
              const SizedBox(height: AlongSpace.s8),
              _LocationRow(
                icon: Icons.place_outlined,
                label: l10n.incomingRequestDropoff,
                value: trip.alight.name,
              ),
              if (trip.load.flagged) ...[
                const SizedBox(height: AlongSpace.s12),
                Row(
                  key: const Key('incoming_request_load_row'),
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AlongColors.semanticWarning,
                      size: 20,
                    ),
                    const SizedBox(width: AlongSpace.s8),
                    Expanded(
                      child: Text(
                        _loadLabel(l10n, trip.load),
                        style: AlongText.bodyStrong.copyWith(
                          color: AlongColors.semanticWarning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AlongSpace.s16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l10n.incomingRequestFareLine(
                        formatMoney(trip.totalFare),
                        _fareTierLabel(l10n, trip.fare.tier),
                      ),
                      style: AlongText.body,
                    ),
                  ),
                  if (trip.fare.unconfirmed)
                    TierPill(
                      key: const Key('incoming_request_estimate_pill'),
                      tier: _designTier(trip.fare.tier),
                    ),
                ],
              ),
              const SizedBox(height: AlongSpace.s4),
              Text(
                l10n.incomingRequestAlongFee(
                  formatMoney(state.alongFee),
                  formatCommissionPercent(state.commissionRate),
                ),
                style: AlongText.caption.copyWith(color: AlongColors.ink500),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: AlongSpace.s8),
                Text(
                  l10n.errorGeneric,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AlongColors.semanticDanger,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: AlongButton(
                      key: const Key('incoming_request_decline'),
                      label: l10n.incomingRequestDecline,
                      variant: AlongButtonVariant.secondary,
                      onPressed: state.isResponding ? null : onDecline,
                    ),
                  ),
                  const SizedBox(width: AlongSpace.s12),
                  Expanded(
                    flex: 6,
                    child: AlongButton(
                      key: const Key('incoming_request_accept'),
                      label: l10n.incomingRequestAccept,
                      variant: AlongButtonVariant.yellow,
                      visualState: state.isResponding
                          ? AlongButtonVisualState.loading
                          : AlongButtonVisualState.normal,
                      onPressed: state.isResponding ? null : onAccept,
                    ),
                  ),
                ],
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
    if (size != null &&
        size.isNotEmpty &&
        note != null &&
        note.isNotEmpty) {
      return l10n.incomingRequestLoadDetail(size, note);
    }
    if (note != null && note.isNotEmpty) return note;
    return l10n.incomingRequestLoadDefault;
  }

  String _fareTierLabel(AppLocalizations l10n, FareTier tier) =>
      switch (tier) {
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

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.meta,
    this.metaKey,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? meta;
  final Key? metaKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AlongColors.ink700),
        const SizedBox(width: AlongSpace.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ',
                style: AlongText.caption.copyWith(color: AlongColors.ink500),
              ),
              Text(value, style: AlongText.bodyStrong),
              if (meta != null)
                Text(
                  meta!,
                  key: metaKey,
                  style: AlongText.caption.copyWith(color: AlongColors.ink500),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final track = Paint()
      ..color = AlongColors.surface200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final arc = Paint()
      ..color = AlongColors.brandYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
