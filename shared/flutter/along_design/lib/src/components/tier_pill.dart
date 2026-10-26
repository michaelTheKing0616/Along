import 'package:flutter/material.dart';

import '../craft.dart';
import '../palette.dart';
import '../tokens.g.dart';
import '../utils/fare_tier.dart';

/// Small pill showing fare verification tier next to every fare (FM8).
class TierPill extends StatelessWidget {
  const TierPill({
    super.key,
    required this.tier,
  });

  final FareTier tier;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AlongSpace.s8,
        vertical: AlongSpace.s4,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: AlongCraft.fill(
        palette.recessed,
        corner: AlongRadius.xs.x,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AlongSpace.s8,
            height: AlongSpace.s8,
            decoration: BoxDecoration(
              color: tier.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AlongSpace.s4),
          Flexible(
            child: Text(
              tier.label,
              style: AlongText.caption.copyWith(color: palette.ink),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
