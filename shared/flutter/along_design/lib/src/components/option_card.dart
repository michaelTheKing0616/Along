import 'package:flutter/material.dart';

import '../tokens.g.dart';
import '../utils/fare_tier.dart';
import '../utils/format_money.dart';
import '../utils/transport_mode.dart';
import 'along_button.dart';
import 'mode_chip.dart';
import 'tier_pill.dart';

/// Option card layout variants (doc 05 §9 `OptionCard`).
enum OptionCardVariant { direct, multiLeg }

/// Snapshot states for golden tests.
enum OptionCardVisualState { normal, pressed, unavailable, warning }

/// Trip option card — mode column, route title, meta, fare + tier, request CTA.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    this.variant = OptionCardVariant.direct,
    this.visualState = OptionCardVisualState.normal,
    this.recommended = false,
    this.mode = TransportMode.car,
    this.secondaryMode,
    this.boardLabel = 'Lugbe Park',
    this.alightLabel = 'Area 1 Park',
    this.meta = '4 min walk · ~6 min wait · direct',
    this.fareNaira = 450,
    this.tier = FareTier.verified,
    this.unavailableReason,
    this.loadWarning,
    this.onRequest,
  });

  final OptionCardVariant variant;
  final OptionCardVisualState visualState;
  final bool recommended;
  final TransportMode mode;
  final TransportMode? secondaryMode;
  final String boardLabel;
  final String alightLabel;
  final String meta;
  final int fareNaira;
  final FareTier tier;
  final String? unavailableReason;
  final String? loadWarning;
  final VoidCallback? onRequest;

  bool get _isUnavailable => visualState == OptionCardVisualState.unavailable;
  bool get _hasLoadWarning => visualState == OptionCardVisualState.warning;

  @override
  Widget build(BuildContext context) {
    final borderColor = recommended ? AlongColors.brandYellow : AlongColors.ink100;
    final borderWidth = recommended ? 2.0 : 1.0;

    return Opacity(
      opacity: _isUnavailable ? 0.5 : 1,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AlongColors.surface0,
              borderRadius: BorderRadius.circular(AlongRadius.lg.x),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AlongSpace.s12,
                      vertical: AlongSpace.s4,
                    ),
                    decoration: BoxDecoration(
                      color: AlongColors.brandYellowTint,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AlongRadius.lg.x - 1),
                      ),
                    ),
                    child: Text(
                      'Recommended',
                      style: AlongText.overline.copyWith(
                        color: AlongColors.brandYellowOn,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AlongSpace.s16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          ModeChip(mode: mode, size: ModeChipSize.small),
                          if (variant == OptionCardVariant.multiLeg &&
                              secondaryMode != null) ...[
                            const SizedBox(height: AlongSpace.s4),
                            ModeChip(
                              mode: secondaryMode!,
                              size: ModeChipSize.small,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: AlongSpace.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Board at $boardLabel → $alightLabel',
                              style: AlongText.title,
                            ),
                            const SizedBox(height: AlongSpace.s4),
                            Text(
                              meta,
                              style: AlongText.caption.copyWith(
                                color: AlongColors.ink500,
                              ),
                            ),
                            if (_hasLoadWarning && loadWarning != null) ...[
                              const SizedBox(height: AlongSpace.s8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                    color: AlongColors.semanticWarning,
                                  ),
                                  const SizedBox(width: AlongSpace.s4),
                                  Expanded(
                                    child: Text(
                                      loadWarning!,
                                      style: AlongText.caption.copyWith(
                                        color: AlongColors.semanticWarning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_isUnavailable && unavailableReason != null) ...[
                              const SizedBox(height: AlongSpace.s8),
                              Text(
                                unavailableReason!,
                                style: AlongText.caption.copyWith(
                                  color: AlongColors.ink500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AlongSpace.s8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatMoney(fareNaira),
                            style: AlongText.numericL,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: AlongSpace.s4),
                          TierPill(tier: tier),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_isUnavailable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AlongSpace.s16,
                      0,
                      AlongSpace.s16,
                      AlongSpace.s16,
                    ),
                    child: AlongButton(
                      label: 'Request ${formatMoney(fareNaira)}',
                      size: AlongButtonSize.secondary,
                      onPressed: onRequest ?? () {},
                    ),
                  ),
              ],
            ),
          ),
          if (visualState == OptionCardVisualState.pressed)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AlongColors.ink900.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AlongRadius.lg.x),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
