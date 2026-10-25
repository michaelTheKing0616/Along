import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/ledger/domain/earnings_summary.dart';
import 'package:mobile_driver/features/payments/data/payments_providers.dart';
import 'package:mobile_driver/features/ledger/presentation/ledger_controller.dart';
import 'package:mobile_driver/features/tenant/tenant_providers.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-19 Earnings & balance — Along balance + Trips sections (doc 06).
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ledger = ref.watch(driverLedgerControllerProvider);
    final entriesAsync = ref.watch(earningsLedgerPageProvider);
    final cashTripsAsync = ref.watch(earningsCashTripsProvider);
    final digitalPaymentsAsync = ref.watch(driverDigitalPaymentsProvider);
    final summary = EarningsSummaryData.from(
      cashToday: cashTripsAsync.valueOrNull ?? const [],
      digital: digitalPaymentsAsync.valueOrNull ?? const [],
      ledger: entriesAsync.valueOrNull?.entries ?? const [],
      now: DateTime.now(),
    );

    return Scaffold(
      key: const Key('earnings_screen'),
      appBar: AppBar(
        title: Text(l10n.navEarnings),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.standing),
            child: Text(l10n.standingLink),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(driverLedgerControllerProvider.notifier).refresh();
          ref.invalidate(earningsLedgerPageProvider);
          ref.invalidate(earningsCashTripsProvider);
          ref.invalidate(driverDigitalPaymentsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AlongSpace.s16),
          children: [
            AlongEarningsSummary(
              key: const Key('earnings_summary'),
              maxTrips: 5,
              today: summary.today,
              week: summary.week,
              payout: summary.payout,
            ),
            const SizedBox(height: AlongSpace.s24),
            BalanceCard(
              state: ledger.cardState,
              balanceNaira: ledger.balance.minorUnits ~/ 100,
              thresholdNaira: ledger.blockThreshold.minorUnits ~/ 100,
              standingLabel: ledger.standingLabel,
              onSettle: () => context.push(AppRoutes.settle),
            ),
            const SizedBox(height: AlongSpace.s24),
            Text(l10n.earningsLedgerSection, style: AlongText.overline),
            const SizedBox(height: AlongSpace.s8),
            entriesAsync.when(
              data: (page) {
                if (page.entries.isEmpty) {
                  return Text(
                    l10n.earningsLedgerEmpty,
                    style: AlongText.body.copyWith(color: AlongColors.ink500),
                  );
                }
                return Column(
                  key: const Key('earnings_ledger_list'),
                  children: [
                    for (final entry in page.entries)
                      LedgerRow(
                        key: Key('ledger_row_${entry.id}'),
                        label: ledgerEntryLabel(
                          entry.entryType,
                          destinationLabel: entry.destinationLabel,
                          memo: entry.memo,
                        ),
                        amount: entry.amount,
                        balanceAfter: entry.balanceAfter,
                        kind: _kindFor(entry.entryType),
                      ),
                  ],
                );
              },
              loading: () => const AlongSkeleton(variant: SkeletonVariant.line),
              error: (_, __) => Text(l10n.errorGeneric),
            ),
            const SizedBox(height: AlongSpace.s24),
            Text(l10n.earningsDigitalSection, style: AlongText.overline),
            const SizedBox(height: AlongSpace.s4),
            Text(
              l10n.earningsDigitalCaption,
              style: AlongText.caption.copyWith(color: AlongColors.ink500),
            ),
            const SizedBox(height: AlongSpace.s8),
            digitalPaymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return Text(
                    l10n.earningsDigitalEmpty,
                    style: AlongText.body.copyWith(color: AlongColors.ink500),
                  );
                }
                return Column(
                  key: const Key('earnings_digital_list'),
                  children: [
                    for (final payment in payments.take(20))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AlongSpace.s8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.earningsDigitalRow(payment.source),
                                style: AlongText.body,
                              ),
                            ),
                            Text(
                              formatAppMoney(ref, payment.driverAmount),
                              style: AlongText.numericM,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const AlongSkeleton(variant: SkeletonVariant.line),
              error: (_, __) => Text(l10n.errorGeneric),
            ),
            const SizedBox(height: AlongSpace.s16),
            AlongButton(
              label: l10n.guarantorLink,
              variant: AlongButtonVariant.secondary,
              onPressed: () => context.push(AppRoutes.guarantor),
            ),
          ],
        ),
      ),
    );
  }

  LedgerRowKind _kindFor(String entryType) => switch (entryType) {
    'cash_commission_debit' ||
    'deposit_drawdown' ||
    'payout_debit' => LedgerRowKind.debit,
    'digital_settlement_credit' || 'onboarding_deposit' => LedgerRowKind.credit,
    'manual_adjustment' => LedgerRowKind.adjustment,
    _ => LedgerRowKind.settlement,
  };
}
