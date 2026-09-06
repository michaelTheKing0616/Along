import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/ledger/presentation/ledger_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-21 Standing — reason, balance, grace, history (doc 06).
class StandingScreen extends ConsumerWidget {
  const StandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ledger = ref.watch(driverLedgerControllerProvider);
    final historyAsync = ref.watch(standingHistoryProvider);

    return Scaffold(
      key: const Key('standing_screen'),
      appBar: AppBar(
        title: Text(l10n.standingTitle),
        backgroundColor: AlongColors.surface0,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AlongSpace.s16),
        children: [
          Text(
            ledger.standingLabel,
            style: AlongText.displayL.copyWith(
              color: ledger.cardState == BalanceCardState.paused
                  ? AlongColors.semanticDanger
                  : AlongColors.ink900,
            ),
          ),
          const SizedBox(height: AlongSpace.s8),
          Text(
            l10n.standingBalanceAt(formatMoney(ledger.balance)),
            style: AlongText.body,
          ),
          Text(
            l10n.standingBlockThreshold(formatMoney(ledger.blockThreshold)),
            style: AlongText.caption.copyWith(color: AlongColors.ink500),
          ),
          if (ledger.graceDeadline != null) ...[
            const SizedBox(height: AlongSpace.s8),
            Text(
              l10n.standingGraceDeadline(
                MaterialLocalizations.of(context).formatShortDate(
                  ledger.graceDeadline!.toLocal(),
                ),
              ),
              style: AlongText.bodyStrong.copyWith(color: AlongColors.semanticWarning),
            ),
          ],
          const SizedBox(height: AlongSpace.s8),
          Text(
            l10n.standingRestoreHint,
            style: AlongText.body.copyWith(color: AlongColors.ink700),
          ),
          const SizedBox(height: AlongSpace.s16),
          AlongButton(
            key: const Key('standing_settle'),
            label: l10n.settleCta,
            variant: AlongButtonVariant.yellow,
            onPressed: () => context.push(AppRoutes.settle),
          ),
          const SizedBox(height: AlongSpace.s24),
          Text(l10n.standingHistoryTitle, style: AlongText.overline),
          const SizedBox(height: AlongSpace.s8),
          historyAsync.when(
            data: (rows) {
              if (rows.isEmpty) {
                return Text(
                  l10n.standingHistoryEmpty,
                  style: AlongText.body.copyWith(color: AlongColors.ink500),
                );
              }
              return Column(
                children: [
                  for (final row in rows)
                    ListTile(
                      key: Key('standing_history_${row.created_at}'),
                      title: Text(standingLabel(row.to_standing)),
                      subtitle: Text(row.reason),
                      trailing: row.balance_at != null
                          ? Text(
                              formatMoney(
                                Money.parse(row.balance_at!, currency: 'NGN'),
                              ),
                              style: AlongText.caption,
                            )
                          : null,
                    ),
                ],
              );
            },
            loading: () => const AlongSkeleton(variant: SkeletonVariant.line),
            error: (_, __) => Text(l10n.errorGeneric),
          ),
        ],
      ),
    );
  }
}
