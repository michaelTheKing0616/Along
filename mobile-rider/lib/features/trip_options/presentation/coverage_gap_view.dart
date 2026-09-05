import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-18 Coverage gap — honest empty state when planner finds no routes.
class CoverageGapView extends StatelessWidget {
  const CoverageGapView({
    super.key,
    required this.gap,
    this.onWalkThere,
    this.onTellUs,
    this.reportThanks = false,
  });

  final CoverageGap gap;
  final VoidCallback? onWalkThere;
  final VoidCallback? onTellUs;
  final bool reportThanks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final distanceKm = (gap.nearestStage.distanceM / 1000);
    final distanceLabel = distanceKm >= 1
        ? l10n.coverageGapDistanceKm(distanceKm.toStringAsFixed(1))
        : l10n.coverageGapDistanceM(gap.nearestStage.distanceM);

    final vehicleLine = gap.ambientVehicleCount <= 0
        ? l10n.coverageGapVehiclesNone
        : l10n.coverageGapVehiclesNearby(gap.ambientVehicleCount);

    return Padding(
      padding: const EdgeInsets.all(AlongSpace.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 48, color: AlongColors.ink500),
          const SizedBox(height: AlongSpace.s16),
          Text(
            l10n.coverageGapTitle,
            style: AlongText.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlongSpace.s8),
          Text(
            l10n.coverageGapNearestBoarding(
              gap.nearestStage.name,
              distanceLabel,
            ),
            style: AlongText.body.copyWith(color: AlongColors.ink500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlongSpace.s12),
          Text(
            vehicleLine,
            style: AlongText.caption.copyWith(color: AlongColors.ink500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlongSpace.s24),
          AlongButton(
            key: const Key('coverage_gap_walk'),
            label: l10n.coverageGapWalkThere,
            variant: AlongButtonVariant.secondary,
            fullWidth: false,
            onPressed: onWalkThere ?? () {},
          ),
          const SizedBox(height: AlongSpace.s12),
          TextButton(
            key: const Key('coverage_gap_report'),
            onPressed: reportThanks ? null : onTellUs,
            child: Text(
              reportThanks
                  ? l10n.coverageGapThanks
                  : l10n.coverageGapTellUs,
            ),
          ),
        ],
      ),
    );
  }
}
