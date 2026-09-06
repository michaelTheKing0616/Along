import 'package:along_core/along_core.dart' hide formatMoney;
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../tokens.g.dart';
import '../utils/format_money.dart';

/// Visual kind for [LedgerRow] amount colouring (doc 05 §9).
enum LedgerRowKind { debit, credit, settlement, adjustment }

/// Ledger list row — human label, signed amount, balance after (doc 05 §9).
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.label,
    required this.amount,
    this.balanceAfter,
    this.kind = LedgerRowKind.debit,
  });

  final String label;
  final Money amount;
  final Money? balanceAfter;
  final LedgerRowKind kind;

  Color get _amountColor => switch (kind) {
        LedgerRowKind.debit => AlongColors.semanticDanger,
        LedgerRowKind.credit || LedgerRowKind.settlement => AlongColors.semanticSuccess,
        LedgerRowKind.adjustment => AlongColors.ink700,
      };

  String get _signedAmount {
    final negative = amount.amount < Decimal.zero;
    final naira = amount.minorUnits ~/ 100;
    if (negative) {
      return formatMoney(-naira.abs());
    }
    return '+${formatMoney(naira)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AlongSpace.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AlongText.bodyStrong,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _signedAmount,
                style: AlongText.numericM.copyWith(color: _amountColor),
                softWrap: false,
              ),
              if (balanceAfter != null)
                Text(
                  formatMoney(balanceAfter!.minorUnits ~/ 100),
                  style: AlongText.caption.copyWith(color: AlongColors.ink500),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
