import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// One extra tap to pick a decline reason (doc 06 D-14).
class DeclineReasonSheet extends StatelessWidget {
  const DeclineReasonSheet({
    super.key,
    required this.l10n,
    required this.onReasonSelected,
  });

  final AppLocalizations l10n;
  final ValueChanged<String> onReasonSelected;

  static const reasons = [
    _DeclineReason('no_room_for_load', 'declineReasonNoRoomForLoad'),
    _DeclineReason('too_far', 'declineReasonTooFar'),
    _DeclineReason('ending_shift', 'declineReasonEndingShift'),
    _DeclineReason('other', 'declineReasonOther'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AlongSpace.s16),
      clipBehavior: Clip.antiAlias,
      decoration: AlongCraft.fill(
        AlongColors.surface0,
        corner: AlongRadius.sheet.x,
        top: true,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.declineReasonTitle, style: AlongText.heading2),
            const SizedBox(height: AlongSpace.s12),
            Wrap(
              spacing: AlongSpace.s8,
              runSpacing: AlongSpace.s8,
              children: [
                for (final reason in reasons)
                  ActionChip(
                    key: Key('decline_reason_${reason.code}'),
                    label: Text(_labelFor(l10n, reason.labelKey)),
                    onPressed: () => onReasonSelected(reason.code),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(AppLocalizations l10n, String key) => switch (key) {
        'declineReasonNoRoomForLoad' => l10n.declineReasonNoRoomForLoad,
        'declineReasonTooFar' => l10n.declineReasonTooFar,
        'declineReasonEndingShift' => l10n.declineReasonEndingShift,
        _ => l10n.declineReasonOther,
      };
}

class _DeclineReason {
  const _DeclineReason(this.code, this.labelKey);

  final String code;
  final String labelKey;
}
