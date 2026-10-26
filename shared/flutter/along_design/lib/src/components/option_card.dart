import 'package:flutter/material.dart';

import '../craft.dart';
import '../icons.dart';
import '../palette.dart';
import '../type.dart';
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
    this.requestLabel,
    this.recommendedLabel = 'Recommended',
    this.requestLabelFor,
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
  final String? requestLabel;

  /// Band text on the recommended card. Apps pass their translation.
  final String recommendedLabel;

  /// Builds the request label from the formatted fare, for translations.
  final String Function(String fare)? requestLabelFor;

  bool get _isUnavailable => visualState == OptionCardVisualState.unavailable;
  bool get _hasLoadWarning => visualState == OptionCardVisualState.warning;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final borderColor = recommended ? palette.accent : palette.line;
    final borderWidth = recommended ? 2.0 : 1.0;
    final caption = AlongType.caption(palette);

    return Opacity(
      opacity: _isUnavailable ? 0.5 : 1,
      child: Stack(
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: AlongCraft.fill(
              palette.surface,
              corner: AlongRadius.card.x,
              side: BorderSide(color: borderColor, width: borderWidth),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AlongSpace.s16,
                      vertical: AlongSpace.s4,
                    ),
                    color: palette.accent.withValues(alpha: 0.22),
                    child: Text(
                      recommendedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.label(palette).copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AlongSpace.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mode and fare share the top line so the place names
                      // get the full width, even at 1.3x text.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ModeChip(mode: mode, size: ModeChipSize.small),
                          if (variant == OptionCardVariant.multiLeg &&
                              secondaryMode != null) ...[
                            const SizedBox(width: AlongSpace.s4),
                            ModeChip(
                              mode: secondaryMode!,
                              size: ModeChipSize.small,
                            ),
                          ],
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatMoney(fareNaira),
                                style: AlongText.numericL.copyWith(
                                  color: palette.ink,
                                ),
                                softWrap: false,
                              ),
                              const SizedBox(height: AlongSpace.s4),
                              TierPill(tier: tier),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AlongSpace.s8),
                      Text(
                        'Board at $boardLabel → $alightLabel',
                        style: AlongType.title(palette),
                      ),
                      const SizedBox(height: AlongSpace.s4),
                      Text(meta, style: caption),
                      if (_hasLoadWarning && loadWarning != null) ...[
                        const SizedBox(height: AlongSpace.s8),
                        Row(
                          children: [
                            AlongIcon(
                              AlongIcons.info,
                              size: 16,
                              color: AlongColors.semanticWarning,
                            ),
                            const SizedBox(width: AlongSpace.s4),
                            Expanded(
                              child: Text(
                                loadWarning!,
                                style: caption.copyWith(
                                  color: AlongColors.semanticWarning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_isUnavailable && unavailableReason != null) ...[
                        const SizedBox(height: AlongSpace.s8),
                        Text(unavailableReason!, style: caption),
                      ],
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
                      label:
                          requestLabel ??
                          requestLabelFor?.call(formatMoney(fareNaira)) ??
                          'Request ${formatMoney(fareNaira)}',
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
                  decoration: AlongCraft.fill(
                    palette.ink.withValues(alpha: 0.08),
                    corner: AlongRadius.card.x,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
