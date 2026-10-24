import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:flutter/material.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// D-08 LEDGER_BLOCKED banner — balance, threshold, Settle CTA (TS-UI-05).
class LedgerBlockedBanner extends StatelessWidget {
  const LedgerBlockedBanner({
    super.key,
    required this.balance,
    required this.blockThreshold,
    required this.onSettle,
    this.l10n,
  });

  final Money balance;
  final Money blockThreshold;
  final VoidCallback onSettle;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final labels = l10n ?? AppLocalizations.of(context);

    return Container(
      key: const Key('ledger_blocked_banner'),
      padding: const EdgeInsets.all(AlongSpace.s12),
      clipBehavior: Clip.antiAlias,
      decoration: AlongCraft.fill(
        AlongColors.semanticDangerTint,
        corner: AlongRadius.card.x,
        side: const BorderSide(color: AlongColors.semanticDangerFill),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            labels.homeLedgerBlockedTitle,
            style: AlongText.bodyStrong.copyWith(color: AlongColors.semanticDanger),
          ),
          const SizedBox(height: AlongSpace.s8),
          Text(
            labels.homeLedgerBlockedBalance(formatMoney(balance)),
            style: AlongText.body.copyWith(color: AlongColors.ink900),
          ),
          Text(
            labels.homeLedgerBlockedThreshold(formatMoney(blockThreshold)),
            style: AlongText.caption.copyWith(color: AlongColors.ink700),
          ),
          const SizedBox(height: AlongSpace.s12),
          AlongButton(
            key: const Key('ledger_blocked_settle'),
            label: labels.settleCta,
            variant: AlongButtonVariant.yellow,
            onPressed: onSettle,
          ),
        ],
      ),
    );
  }
}
