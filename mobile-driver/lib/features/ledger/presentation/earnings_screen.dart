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
import 'package:mobile_driver/widgets/drive_kit.dart';

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
      cashTrips: cashTripsAsync.valueOrNull ?? const [],
      digital: digitalPaymentsAsync.valueOrNull ?? const [],
      context: ref.watch(earningsContextProvider).valueOrNull,
      now: ref.watch(earningsClockProvider)(),
    );

    final p = AlongPalette.of(context);
    Widget empty(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AlongSpace.s8),
      child: Text(text, style: AlongType.bodyMuted(p)),
    );

    return Scaffold(
      key: const Key('earnings_screen'),
      backgroundColor: p.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(driverLedgerControllerProvider.notifier).refresh();
            ref.invalidate(earningsLedgerPageProvider);
            ref.invalidate(earningsCashTripsProvider);
            ref.invalidate(earningsContextProvider);
            ref.invalidate(driverDigitalPaymentsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AlongSpace.s16,
              AlongSpace.s16,
              AlongSpace.s16,
              AlongSpace.s32,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.navEarnings, style: AlongType.display(p)),
                  ),
                  TextButton(
                    key: const Key('earnings_standing_link'),
                    onPressed: () => context.push(AppRoutes.standing),
                    child: Text(l10n.standingLink, style: AlongType.label(p)),
                  ),
                ],
              ),
              const SizedBox(height: AlongSpace.s12),
              AlongEarningsSummary(
                key: const Key('earnings_summary'),
                maxTrips: 5,
                today: summary.today,
                week: summary.week,
                payout: summary.payout,
              ),
              const SizedBox(height: AlongSpace.s16),
              BalanceCard(
                state: ledger.cardState,
                balanceNaira: ledger.balance.minorUnits ~/ 100,
                thresholdNaira: ledger.blockThreshold.minorUnits ~/ 100,
                standingLabel: ledger.standingLabel,
                onSettle: () => context.push(AppRoutes.settle),
              ),
              DriveSection(l10n.earningsLedgerSection),
              entriesAsync.when(
                data: (page) {
                  if (page.entries.isEmpty) {
                    return empty(l10n.earningsLedgerEmpty);
                  }
                  return DriveRows(
                    key: const Key('earnings_ledger_list'),
                    children: [
                      for (final entry in page.entries)
                        _MoneyLine(
                          key: Key('ledger_row_${entry.id}'),
                          title: ledgerEntryLabel(
                            entry.entryType,
                            destinationLabel: entry.destinationLabel,
                            memo: entry.memo,
                          ),
                          detail: l10n.earningsBalanceAfter(
                            formatAppMoney(ref, entry.balanceAfter),
                          ),
                          amount: entry.amount,
                          credit:
                              _kindFor(entry.entryType) !=
                                  LedgerRowKind.debit &&
                              _kindFor(entry.entryType) !=
                                  LedgerRowKind.adjustment,
                          text: formatAppMoney(ref, entry.amount),
                        ),
                    ],
                  );
                },
                loading: () =>
                    const AlongSkeleton(variant: SkeletonVariant.line),
                error: (_, __) => empty(l10n.errorGeneric),
              ),
              DriveSection(l10n.earningsDigitalSection),
              Text(l10n.earningsDigitalCaption, style: AlongType.caption(p)),
              const SizedBox(height: AlongSpace.s8),
              digitalPaymentsAsync.when(
                data: (payments) {
                  if (payments.isEmpty) {
                    return empty(l10n.earningsDigitalEmpty);
                  }
                  return DriveRows(
                    key: const Key('earnings_digital_list'),
                    children: [
                      for (final payment in payments.take(20))
                        _MoneyLine(
                          title: l10n.earningsDigitalRow(payment.source),
                          amount: payment.driverAmount,
                          credit: true,
                          text: formatAppMoney(ref, payment.driverAmount),
                        ),
                    ],
                  );
                },
                loading: () =>
                    const AlongSkeleton(variant: SkeletonVariant.line),
                error: (_, __) => empty(l10n.errorGeneric),
              ),
              const SizedBox(height: AlongSpace.s16),
              DriveRows(
                children: [
                  DriveRow(
                    key: const Key('earnings_guarantor_link'),
                    icon: AlongIcons.shield,
                    title: l10n.guarantorLink,
                    chevron: true,
                    onTap: () => context.push(AppRoutes.guarantor),
                  ),
                ],
              ),
            ],
          ),
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

/// One money movement: label, optional balance-after, signed amount.
/// Credits read green; debits stay ink with a true minus sign.
class _MoneyLine extends StatelessWidget {
  const _MoneyLine({
    super.key,
    required this.title,
    required this.amount,
    required this.credit,
    required this.text,
    this.detail,
  });

  final String title;
  final String? detail;
  final Money amount;
  final bool credit;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final negative = amount.amount.sign < 0;
    final shown = negative
        ? '\u2212${text.replaceFirst('-', '')}'
        : (credit ? '+$text' : text);
    return DriveRow(
      title: title,
      detail: detail,
      trailing: shown,
      trailingStyle: AlongType.body(p).copyWith(
        fontWeight: FontWeight.w600,
        fontFeatures: AlongType.figures,
        color: credit && !negative ? AlongColors.semanticSuccess : p.ink,
      ),
    );
  }
}
