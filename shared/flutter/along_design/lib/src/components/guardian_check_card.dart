import 'package:flutter/material.dart';

import '../tokens.g.dart';
import 'along_button.dart';

/// Quiet "are you OK?" card. One confirm, no map tiles.
class GuardianCheckCard extends StatelessWidget {
  const GuardianCheckCard({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AlongColors.surface0,
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              key: const Key('guardian_check_title'),
              style: AlongText.heading2,
            ),
            const SizedBox(height: AlongSpace.s8),
            Text(body, style: AlongText.body),
            const SizedBox(height: AlongSpace.s12),
            AlongButton(
              key: const Key('guardian_check_ok'),
              label: confirmLabel,
              onPressed: onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rest nudge. Priority is named. There is no cash amount.
class RestNudgeCard extends StatelessWidget {
  const RestNudgeCard({
    super.key,
    required this.title,
    required this.body,
    required this.restLabel,
    required this.onRest,
    this.priorityLabel,
  });

  final String title;
  final String body;
  final String restLabel;
  final VoidCallback onRest;
  final String? priorityLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AlongColors.surface0,
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              key: const Key('rest_nudge_title'),
              style: AlongText.heading2,
            ),
            const SizedBox(height: AlongSpace.s8),
            Text(body, style: AlongText.body),
            if (priorityLabel != null) ...[
              const SizedBox(height: AlongSpace.s8),
              Text(
                priorityLabel!,
                key: const Key('rest_priority_label'),
                style: AlongText.caption,
              ),
            ],
            const SizedBox(height: AlongSpace.s12),
            AlongButton(
              key: const Key('rest_nudge_start'),
              label: restLabel,
              variant: AlongButtonVariant.secondary,
              onPressed: onRest,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lost-and-found line. Shows the role, never a phone number.
class MaskedMessageLine extends StatelessWidget {
  const MaskedMessageLine({
    super.key,
    required this.roleLabel,
    required this.body,
  });

  final String roleLabel;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AlongSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(roleLabel, style: AlongText.caption),
          Text(body, style: AlongText.body),
        ],
      ),
    );
  }
}
