import 'package:flutter/material.dart';

import '../tokens.g.dart';
import 'along_button.dart';

/// Empty state scenarios (doc 05 §9 `EmptyState`).
enum EmptyStateVariant { coverageGap, noHistory, offline }

/// Illustration-free empty state — icon, heading, body, one action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.variant,
    this.actionLabel,
    this.onAction,
  });

  final EmptyStateVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;

  ({IconData icon, String heading, String body, String defaultAction})
      get _content => switch (variant) {
            EmptyStateVariant.coverageGap => (
                icon: Icons.map_outlined,
                heading: 'No routes here yet',
                body:
                    'Along does not have verified routes for this area. Try a nearby park or check back soon.',
                defaultAction: 'Report a route',
              ),
            EmptyStateVariant.noHistory => (
                icon: Icons.history_rounded,
                heading: 'No trips yet',
                body: 'Your completed trips will appear here.',
                defaultAction: 'Find a ride',
              ),
            EmptyStateVariant.offline => (
                icon: Icons.wifi_off_rounded,
                heading: 'You are offline',
                body:
                    'Connect to the internet to search routes. Saved trips and Na Me still work.',
                defaultAction: 'Retry',
              ),
          };

  @override
  Widget build(BuildContext context) {
    final content = _content;
    return Padding(
      padding: const EdgeInsets.all(AlongSpace.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(content.icon, size: 48, color: AlongColors.ink500),
          const SizedBox(height: AlongSpace.s16),
          Text(content.heading, style: AlongText.heading2, textAlign: TextAlign.center),
          const SizedBox(height: AlongSpace.s8),
          Text(
            content.body,
            style: AlongText.body.copyWith(color: AlongColors.ink500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlongSpace.s24),
          AlongButton(
            label: actionLabel ?? content.defaultAction,
            variant: AlongButtonVariant.secondary,
            fullWidth: false,
            onPressed: onAction ?? () {},
          ),
        ],
      ),
    );
  }
}
