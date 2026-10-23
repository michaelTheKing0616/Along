import 'package:flutter/material.dart';

import '../craft.dart';
import '../motion.dart';
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

  ({AlongSpotKind spot, String heading, String body, String defaultAction})
  get _content => switch (variant) {
    EmptyStateVariant.coverageGap => (
      spot: AlongSpotKind.route,
      heading: 'No routes here yet',
      body: 'Along does not have verified routes for this area. Try a nearby park or check back soon.',
      defaultAction: 'Report a route',
    ),
    EmptyStateVariant.noHistory => (
      spot: AlongSpotKind.ticket,
      heading: 'No trips yet',
      body: 'Your completed trips will appear here.',
      defaultAction: 'Find a ride',
    ),
    EmptyStateVariant.offline => (
      spot: AlongSpotKind.offline,
      heading: 'You are offline',
      body: 'Connect to the internet to search routes. Saved trips and Na Me still work.',
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
          _EmptyMark(kind: content.spot),
          const SizedBox(height: AlongSpace.s16),
          Text(
            content.heading,
            style: AlongText.heading2,
            textAlign: TextAlign.center,
          ),
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

class _EmptyMark extends StatefulWidget {
  const _EmptyMark({required this.kind});

  final AlongSpotKind kind;

  @override
  State<_EmptyMark> createState() => _EmptyMarkState();
}

class _EmptyMarkState extends State<_EmptyMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      value: 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AlongMotionPolicy.play(context)) return;
      _float.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, _) {
        final dy = AlongMotionPolicy.play(context) ? -4 * _float.value : 0.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: AlongSpot(kind: widget.kind),
        );
      },
    );
  }
}
