import 'package:flutter/material.dart';

import '../craft.dart';
import '../palette.dart';
import '../tokens.g.dart';
import '../utils/format_money.dart';
import 'along_button.dart';

/// Balance card states (doc 05 §9 `BalanceCard`).
enum BalanceCardState { good, warned, paused }

enum BalanceCardVariant { full, compact }

/// Driver ledger balance summary (doc 05 §9, D-08/D-19).
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    this.variant = BalanceCardVariant.full,
    this.state = BalanceCardState.good,
    this.balanceNaira = 1250,
    this.thresholdNaira = -5000,
    this.standingLabel = 'Good standing',
    this.onSettle,
    this.onTap,
  });

  final BalanceCardVariant variant;
  final BalanceCardState state;
  final int balanceNaira;
  final int thresholdNaira;
  final String standingLabel;
  final VoidCallback? onSettle;
  final VoidCallback? onTap;

  Color _balanceColor(BuildContext context) => switch (state) {
    BalanceCardState.good => _c(context).ink,
    BalanceCardState.warned => AlongColors.semanticWarning,
    BalanceCardState.paused => AlongColors.semanticDanger,
  };

  Color get _standingColor => switch (state) {
    BalanceCardState.good => AlongColors.semanticSuccess,
    BalanceCardState.warned => AlongColors.semanticWarning,
    BalanceCardState.paused => AlongColors.semanticDanger,
  };

  String get _statusLine => switch (state) {
    BalanceCardState.good => 'Balance healthy',
    BalanceCardState.warned => 'Approaching settlement threshold',
    BalanceCardState.paused =>
      'Matching pauses below ${formatMoney(thresholdNaira)}',
  };

  // Light keeps the original tokens exactly; dark reads the palette so the
  // card never renders as a white slab on a dark screen.
  static _Tones _c(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return const _Tones.light();
    }
    final p = AlongPalette.of(context);
    return _Tones(
      surface: p.surface,
      ink: p.ink,
      body: p.ink,
      muted: p.muted,
      line: p.line,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (variant == BalanceCardVariant.compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Material(
      color: _c(context).surface,
      shape: AlongCraft.border(AlongRadius.card.x),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: AlongCraft.border(AlongRadius.card.x),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AlongSpace.s16,
            vertical: AlongSpace.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Along balance',
                      style: AlongText.caption.copyWith(
                        color: _c(context).muted,
                      ),
                    ),
                    Text(
                      formatMoney(balanceNaira),
                      style: AlongText.numericL.copyWith(
                        color: _balanceColor(context),
                      ),
                      softWrap: false,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AlongSpace.s8,
                  vertical: AlongSpace.s4,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: AlongCraft.fill(
                  _standingColor.withValues(alpha: 0.15),
                  corner: AlongRadius.control.x,
                ),
                child: Text(
                  standingLabel,
                  style: AlongText.caption.copyWith(color: _standingColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final showSettle = balanceNaira < 0 || state == BalanceCardState.paused;

    return Container(
      padding: const EdgeInsets.all(AlongSpace.s16),
      clipBehavior: Clip.antiAlias,
      decoration: AlongCraft.fill(
        _c(context).surface,
        corner: AlongRadius.card.x,
        side: BorderSide(
          color: state == BalanceCardState.paused
              ? AlongColors.semanticDangerFill
              : _c(context).line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Along balance',
            style: AlongText.caption.copyWith(color: _c(context).muted),
          ),
          const SizedBox(height: AlongSpace.s4),
          Text(
            formatMoney(balanceNaira),
            style: AlongText.displayL.copyWith(color: _balanceColor(context)),
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: AlongSpace.s8),
          Text(
            _statusLine,
            style: AlongText.body.copyWith(color: _c(context).body),
          ),
          const SizedBox(height: AlongSpace.s4),
          Text(
            'Matching pauses below ${formatMoney(thresholdNaira)}',
            style: AlongText.caption.copyWith(color: _c(context).muted),
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
          if (showSettle) ...[
            const SizedBox(height: AlongSpace.s16),
            AlongButton(
              label: 'Settle',
              variant: AlongButtonVariant.yellow,
              onPressed: onSettle ?? () {},
            ),
          ],
        ],
      ),
    );
  }
}

class _Tones {
  const _Tones({
    required this.surface,
    required this.ink,
    required this.body,
    required this.muted,
    required this.line,
  });
  const _Tones.light()
    : surface = AlongColors.surface0,
      ink = AlongColors.ink900,
      body = AlongColors.ink700,
      muted = AlongColors.ink500,
      line = AlongColors.ink100;
  final Color surface;
  final Color ink;
  final Color body;
  final Color muted;
  final Color line;
}
