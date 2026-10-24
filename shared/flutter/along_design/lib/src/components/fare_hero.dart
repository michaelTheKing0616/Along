import 'package:flutter/material.dart';

import '../craft.dart';
import '../tokens.g.dart';
import '../utils/fare_tier.dart';
import '../utils/format_money.dart';
import 'tier_pill.dart';

/// One line in the expandable fare breakdown.
class FareHeroLineItem {
  const FareHeroLineItem({
    required this.label,
    required this.amountNaira,
  });

  final String label;
  final int amountNaira;
}

/// Large fare display with tier pill and optional itemised expand (doc 05 §9).
class FareHero extends StatelessWidget {
  const FareHero({
    super.key,
    required this.amountNaira,
    this.tier = FareTier.verified,
    this.deltaNaira,
    this.lineItems = const [],
    this.expanded = false,
    this.onToggleExpand,
  });

  final int amountNaira;
  final FareTier tier;
  final int? deltaNaira;
  final List<FareHeroLineItem> lineItems;
  final bool expanded;
  final VoidCallback? onToggleExpand;

  bool get _hasDelta => deltaNaira != null;
  bool get _hasLineItems => lineItems.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                formatMoney(amountNaira),
                style: AlongText.displayXl,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
            if (_hasDelta) ...[
              const SizedBox(width: AlongSpace.s8),
              _DeltaBadge(deltaNaira: deltaNaira!),
            ],
          ],
        ),
        const SizedBox(height: AlongSpace.s8),
        TierPill(tier: tier),
        if (_hasLineItems) ...[
          const SizedBox(height: AlongSpace.s12),
          InkWell(
            onTap: onToggleExpand,
            customBorder: AlongCraft.border(AlongRadius.control.x),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AlongSpace.s4),
              child: Row(
                children: [
                  Text(
                    expanded ? 'Hide breakdown' : 'Show breakdown',
                    style: AlongText.label.copyWith(color: AlongColors.ink700),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AlongColors.ink700,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: AlongSpace.s8),
            for (final item in lineItems) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: AlongText.body.copyWith(color: AlongColors.ink700),
                    ),
                  ),
                  Text(
                    formatMoney(item.amountNaira),
                    style: AlongText.numericM,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
              const SizedBox(height: AlongSpace.s4),
            ],
          ],
        ],
      ],
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.deltaNaira});

  final int deltaNaira;

  @override
  Widget build(BuildContext context) {
    final isPositive = deltaNaira >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AlongSpace.s8,
        vertical: AlongSpace.s4,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: AlongCraft.fill(
        isPositive ? AlongColors.brandYellowTint : AlongColors.semanticWarningTint,
        corner: AlongRadius.xs.x,
      ),
      child: Text(
        '${isPositive ? '+' : '−'}${formatMoney(deltaNaira.abs())}',
        style: AlongText.label.copyWith(
          color: isPositive ? AlongColors.ink900 : AlongColors.semanticWarning,
        ),
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
