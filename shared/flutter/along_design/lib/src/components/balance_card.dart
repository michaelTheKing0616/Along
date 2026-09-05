import 'package:flutter/material.dart';

import '../tokens.g.dart';
import '../utils/format_money.dart';
import 'along_button.dart';

/// Balance card states (doc 05 §9 `BalanceCard` — stub for Phase 4 ledger).
enum BalanceCardState { good, warned, paused }

/// Driver ledger balance summary — stub until Phase 4 ledger integration.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    this.state = BalanceCardState.good,
    this.balanceNaira = 1250,
    this.thresholdNaira = -500,
    this.onSettle,
  });

  final BalanceCardState state;
  final int balanceNaira;
  final int thresholdNaira;
  final VoidCallback? onSettle;

  Color get _balanceColor => switch (state) {
        BalanceCardState.good => AlongColors.ink900,
        BalanceCardState.warned => AlongColors.semanticWarning,
        BalanceCardState.paused => AlongColors.semanticDanger,
      };

  String get _statusLine => switch (state) {
        BalanceCardState.good => 'Balance healthy',
        BalanceCardState.warned => 'Approaching settlement threshold',
        BalanceCardState.paused => 'Account paused — settle to go online',
      };

  @override
  Widget build(BuildContext context) {
    final showSettle = balanceNaira < 0 || state == BalanceCardState.paused;

    return Container(
      padding: const EdgeInsets.all(AlongSpace.s16),
      decoration: BoxDecoration(
        color: AlongColors.surface0,
        borderRadius: BorderRadius.circular(AlongRadius.md.x),
        border: Border.all(
          color: state == BalanceCardState.paused
              ? AlongColors.semanticDangerFill
              : AlongColors.ink100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ledger balance', style: AlongText.caption.copyWith(color: AlongColors.ink500)),
          const SizedBox(height: AlongSpace.s4),
          Text(
            formatMoney(balanceNaira),
            style: AlongText.displayL.copyWith(color: _balanceColor),
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: AlongSpace.s8),
          Text(
            _statusLine,
            style: AlongText.body.copyWith(color: AlongColors.ink700),
          ),
          const SizedBox(height: AlongSpace.s4),
          Text(
            'Threshold: ${formatMoney(thresholdNaira)}',
            style: AlongText.caption.copyWith(color: AlongColors.ink500),
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
