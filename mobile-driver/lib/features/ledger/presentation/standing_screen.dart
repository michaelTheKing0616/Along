import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/ledger/presentation/ledger_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';

/// D-21 Standing — reason, balance, grace, history (doc 06).
class StandingScreen extends ConsumerWidget {
  const StandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ledger = ref.watch(driverLedgerControllerProvider);
    final historyAsync = ref.watch(standingHistoryProvider);

    final p = AlongPalette.of(context);
    final paused = ledger.cardState == BalanceCardState.paused;
    return KeyedSubtree(
      key: const Key('standing_screen'),
      child: DrivePage(
        title: l10n.standingTitle,
        footer: AlongButton(
          key: const Key('standing_settle'),
          label: l10n.settleCta,
          onPressed: () => context.push(AppRoutes.settle),
        ),
        children: [
          const SizedBox(height: AlongSpace.s16),
          DriveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DriveTag(
                  label: ledger.standingLabel,
                  tone: paused ? DriveTagTone.warning : DriveTagTone.neutral,
                ),
                const SizedBox(height: AlongSpace.s12),
                Text(
                  formatMoney(ledger.balance),
                  style: AlongType.display(p).copyWith(fontSize: 40),
                ),
                const SizedBox(height: AlongSpace.s4),
                Text(
                  l10n.standingBlockThreshold(
                    formatMoney(
                      Money.parse(
                        ledger.blockThreshold.amount.abs().toString(),
                        currency: ledger.blockThreshold.currency,
                      ),
                    ),
                  ),
                  style: AlongType.bodyMuted(p),
                ),
                if (ledger.graceDeadline != null) ...[
                  const SizedBox(height: AlongSpace.s8),
                  Text(
                    l10n.standingGraceDeadline(
                      MaterialLocalizations.of(context)
                          .formatShortDate(ledger.graceDeadline!.toLocal()),
                    ),
                    style: AlongType.label(p).copyWith(color: p.danger),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AlongSpace.s12),
          Text(l10n.standingRestoreHint, style: AlongType.bodyMuted(p)),
          DriveSection(l10n.standingHistoryTitle),
          historyAsync.when(
            data: (rows) {
              if (rows.isEmpty) {
                return DriveCard(
                  child: Text(
                    l10n.standingHistoryEmpty,
                    style: AlongType.bodyMuted(p),
                  ),
                );
              }
              return DriveRows(
                children: [
                  for (final row in rows)
                    DriveRow(
                      key: Key('standing_history_${row.created_at}'),
                      icon: AlongIcons.history,
                      title: standingLabel(row.to_standing),
                      detail: row.reason,
                      trailing: row.balance_at == null
                          ? null
                          : formatMoney(
                              Money.parse(row.balance_at!, currency: 'NGN'),
                            ),
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
