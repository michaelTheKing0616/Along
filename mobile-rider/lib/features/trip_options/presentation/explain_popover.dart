import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-07 "Why?" explain popover — fare / time / effort bars from planner metrics.
void showExplainPopover(
  BuildContext context, {
  required PlanExplain explain,
}) {
  final l10n = AppLocalizations.of(context);
  final total = (explain.fare + explain.time + explain.strenuous)
      .clamp(0.0001, double.infinity);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AlongPalette.of(context).bg,
    shape: AlongCraft.borderVertical(top: AlongRadius.sheet.x),
    clipBehavior: Clip.antiAlias,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(AlongSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.tripOptionsWhyTitle, style: AlongText.heading2),
            const SizedBox(height: AlongSpace.s16),
            _ExplainBar(
              label: l10n.tripOptionsWhyFare,
              value: explain.fare / total,
            ),
            const SizedBox(height: AlongSpace.s12),
            _ExplainBar(
              label: l10n.tripOptionsWhyTime,
              value: explain.time / total,
            ),
            const SizedBox(height: AlongSpace.s12),
            _ExplainBar(
              label: l10n.tripOptionsWhyEffort,
              value: explain.strenuous / total,
            ),
          ],
        ),
      );
    },
  );
}

class _ExplainBar extends StatelessWidget {
  const _ExplainBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AlongText.bodyStrong),
            Text(
              '${(value * 100).round()}%',
              style: AlongText.caption.copyWith(color: AlongColors.ink500),
            ),
          ],
        ),
        const SizedBox(height: AlongSpace.s4),
        AlongCraft.clip(
          corner: AlongRadius.xs.x,
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 12,
            backgroundColor: AlongColors.surface100,
            color: AlongColors.brandYellow,
          ),
        ),
      ],
    );
  }
}
