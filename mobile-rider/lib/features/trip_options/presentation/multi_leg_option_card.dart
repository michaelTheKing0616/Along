import 'package:along_core/along_core.dart' show PlanCandidate;
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/features/trip_options/presentation/option_card_mapper.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-07 multi-leg card with expandable [LegTimeline] and per-leg request CTAs.
class MultiLegOptionCard extends StatelessWidget {
  const MultiLegOptionCard({
    super.key,
    required this.candidate,
    required this.recommended,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onRequestLeg,
    required this.onWhy,
    required this.loadWarning,
    required this.l10n,
  });

  final PlanCandidate candidate;
  final bool recommended;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final void Function(int legIndex) onRequestLeg;
  final VoidCallback? onWhy;
  final String? loadWarning;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final firstLeg = candidate.legs.first;
    final isTier3 = candidate.legs.any((l) => l.fare.unconfirmed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OptionCard(
          key: Key('option_card_${candidate.candidateId}'),
          variant: OptionCardVariant.multiLeg,
          recommended: recommended,
          mode: OptionCardMapper.mapMode(firstLeg.mode),
          secondaryMode: candidate.legs.length > 1
              ? OptionCardMapper.mapMode(candidate.legs[1].mode)
              : null,
          boardLabel: firstLeg.boardName,
          alightLabel: candidate.legs.last.alightName,
          meta: OptionCardMapper.metaForCandidate(candidate),
          fareNaira: candidate.totalFareMinorUnits,
          tier: OptionCardMapper.mapFareTier(
            firstLeg.fare.tier,
            unconfirmed: firstLeg.fare.unconfirmed,
          ),
          visualState: loadWarning != null
              ? OptionCardVisualState.warning
              : OptionCardVisualState.normal,
          loadWarning: loadWarning,
          unavailableReason: !candidate.viableDirect
              ? l10n.tripOptionsSlowerDirectCaption
              : null,
          recommendedLabel: l10n.tripOptionsRecommended,
          requestLabel: isTier3 ? l10n.tripOptionsAgreePrice : null,
          requestLabelFor: l10n.tripOptionsRequest,
          onRequest: isTier3 ? null : () => onRequestLeg(0),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s4),
          child: Row(
            children: [
              AlongTextLink(
                key: Key('multi_leg_toggle_${candidate.candidateId}'),
                onPressed: onToggleExpanded,
                icon: expanded ? AlongIcons.caretUp : AlongIcons.caretDown,
                label: expanded
                    ? l10n.tripOptionsHideLegs
                    : l10n.tripOptionsShowLegs,
              ),
              if (recommended && onWhy != null) ...[
                const Spacer(),
                AlongTextLink(
                  key: Key('why_${candidate.candidateId}'),
                  onPressed: onWhy!,
                  label: l10n.tripOptionsWhy,
                ),
              ],
            ],
          ),
        ),
        if (expanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AlongSpace.s16,
              0,
              AlongSpace.s16,
              AlongSpace.s12,
            ),
            child: LegTimeline(
              legs: _timelineLegs(candidate),
            ),
          ),
          for (var i = 0; i < candidate.legs.length; i++)
            if (!candidate.legs[i].fare.unconfirmed)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AlongSpace.s16,
                  0,
                  AlongSpace.s16,
                  AlongSpace.s8,
                ),
                child: AlongButton(
                  key: Key('leg_request_${candidate.candidateId}_$i'),
                  label: l10n.tripOptionsRequestLeg(
                    i + 1,
                    formatMoney(
                      (candidate.legs[i].fare.total.amount.toDouble()).round(),
                    ),
                  ),
                  size: AlongButtonSize.secondary,
                  onPressed: () => onRequestLeg(i),
                ),
              ),
        ],
      ],
    );
  }

  List<LegTimelineLeg> _timelineLegs(PlanCandidate candidate) {
    final rows = <LegTimelineLeg>[];
    for (var i = 0; i < candidate.legs.length; i++) {
      final leg = candidate.legs[i];
      rows.add(
        LegTimelineLeg(
          mode: OptionCardMapper.mapMode(leg.mode),
          boardLabel: leg.boardName,
          alightLabel: leg.alightName,
          fareNaira: (leg.fare.total.amount.toDouble()).round(),
          etaAtTransfer: i < candidate.transfers.length
              ? '~${(candidate.transfers[i].transferSeconds / 60).ceil()} min at ${candidate.transfers[i].parkName}'
              : null,
          state: LegTimelineLegState.pending,
        ),
      );
      if (i < candidate.transfers.length) {
        final transfer = candidate.transfers[i];
        rows.add(
          LegTimelineLeg(
            mode: TransportMode.car,
            boardLabel: transfer.parkName,
            alightLabel: transfer.parkName,
            isWalk: true,
            etaAtTransfer:
                '${(transfer.walkMeters / 1000).toStringAsFixed(1)} km walk',
            state: LegTimelineLegState.pending,
          ),
        );
      }
    }
    return rows;
  }
}
