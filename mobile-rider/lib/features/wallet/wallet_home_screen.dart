import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/wallet/wallet_pass_screen.dart';
import 'package:mobile_rider/features/wallet/wallet_screen.dart';
import 'package:mobile_rider/features/wallet/wallet_send_screen.dart';
import 'package:mobile_rider/features/wallet/wallet_split_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Wallet home: the credit card, Top up · Send · Pass · Split, split requests
/// waiting on this rider, and activity grouped by day.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  /// Split id being settled → its key, kept across retries.
  final _settleKeys = <String, String>{};
  String? _settling;

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _settle(WalletSplitRequest req, {required bool accept}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final key = _settleKeys.putIfAbsent(req.id, () => walletKey('settle'));
    setState(() => _settling = req.id);
    try {
      await ref
          .read(walletRepositoryProvider)
          .settleSplit(splitId: req.id, accept: accept, idempotencyKey: key);
      _settleKeys.remove(req.id);
      ref.invalidate(walletSummaryProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? l10n.walletOwedPaidSnack(alongNaira(req.amount))
                : l10n.walletOwedDeclinedSnack,
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(walletFailureText(l10n, e))),
      );
    } finally {
      if (mounted) setState(() => _settling = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(walletSummaryProvider);
    return summary.when(
      skipLoadingOnRefresh: true,
      loading: () => const WalletLoadingView(),
      error: (_, _) =>
          WalletErrorView(onRetry: () => ref.invalidate(walletSummaryProvider)),
      data: _home,
    );
  }

  Widget _home(WalletSummary data) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(walletNowProvider)();
    final canPop = Navigator.of(context).canPop();
    final groups = <String, List<WalletEntry>>{};
    for (final e in data.entries) {
      final day = DateTime(e.at.year, e.at.month, e.at.day);
      final diff = DateTime(now.year, now.month, now.day).difference(day);
      final label = switch (diff.inDays) {
        0 => l10n.walletToday,
        1 => l10n.walletYesterday,
        _ => l10n.walletEarlier,
      };
      groups.putIfAbsent(label, () => []).add(e);
    }
    return Scaffold(
      key: const Key('wallet_home'),
      backgroundColor: p.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(walletSummaryProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              if (canPop)
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackButton(color: p.ink),
                )
              else
                const SizedBox(height: 8),
              AlongWalletCard(
                key: const Key('wallet_card'),
                amount: alongNaira(data.balance),
                semanticsLabel: l10n.walletBalanceSemantics(
                  alongNaira(data.balance),
                ),
              ),
              const SizedBox(height: 16),
              AlongWalletActions(
                actions: [
                  AlongWalletAction(
                    key: const Key('wallet_action_topup'),
                    icon: AlongIcons.plus,
                    label: l10n.walletActionTopUp,
                    onTap: () => _open(const WalletTopUpScreen()),
                  ),
                  AlongWalletAction(
                    key: const Key('wallet_action_send'),
                    icon: AlongIcons.arrowRight,
                    label: l10n.walletActionSend,
                    onTap: () => _open(const WalletSendScreen()),
                  ),
                  AlongWalletAction(
                    key: const Key('wallet_action_pass'),
                    icon: AlongIcons.receipt,
                    label: l10n.walletActionPass,
                    onTap: () => _open(const WalletPassScreen()),
                  ),
                  AlongWalletAction(
                    key: const Key('wallet_action_split'),
                    icon: AlongIcons.share,
                    label: l10n.walletActionSplit,
                    onTap: () => _open(const WalletSplitScreen()),
                  ),
                ],
              ),
              for (final req in data.splitsOwed) ...[
                const SizedBox(height: 12),
                _OwedCard(
                  request: req,
                  busy: _settling == req.id,
                  onPay: () => _settle(req, accept: true),
                  onDecline: () => _settle(req, accept: false),
                ),
              ],
              const SizedBox(height: 8),
              if (data.entries.isEmpty) ...[
                AlongTxnGroup(
                  label: l10n.walletActivity,
                  icon: AlongIcons.history,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.walletActivityEmpty,
                  key: const Key('wallet_activity_empty'),
                  style: AlongType.bodyMuted(p),
                ),
              ],
              for (final g in groups.entries) ...[
                AlongTxnGroup(label: g.key, icon: _groupIcon(l10n, g.key)),
                for (final e in g.value)
                  AlongTxnRow(
                    icon: switch (e.kind) {
                      WalletEntryKind.topUp => AlongIcons.plus,
                      WalletEntryKind.fare => AlongIcons.navigate,
                      WalletEntryKind.refund => AlongIcons.receipt,
                      WalletEntryKind.send => AlongIcons.arrowRight,
                      WalletEntryKind.pass => AlongIcons.receipt,
                      WalletEntryKind.split => AlongIcons.share,
                    },
                    title: walletEntryTitle(l10n, e),
                    detail: walletDetail(context, l10n, e.at, now),
                    value: e.amount < 0
                        ? '−${alongNaira(-e.amount)}'
                        : '+${alongNaira(e.amount)}',
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OwedCard extends StatelessWidget {
  const _OwedCard({
    required this.request,
    required this.busy,
    required this.onPay,
    required this.onDecline,
  });

  final WalletSplitRequest request;
  final bool busy;
  final VoidCallback onPay;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final name = request.requesterName.isEmpty ? '—' : request.requesterName;
    return DecoratedBox(
      key: Key('wallet_owed_${request.id}'),
      decoration: AlongCraft.surface(p, radius: AlongRadius.card.x),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                WalletInitials(name: name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.walletOwedTitle(name, alongNaira(request.amount)),
                        style: AlongType.body(p)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(l10n.walletOwedBody, style: AlongType.caption(p)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AlongButton(
                    key: Key('wallet_owed_decline_${request.id}'),
                    label: l10n.walletOwedDecline,
                    variant: AlongButtonVariant.secondary,
                    onPressed: busy ? null : onDecline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AlongButton(
                    key: Key('wallet_owed_pay_${request.id}'),
                    label: l10n.walletOwedPay,
                    visualState: busy
                        ? AlongButtonVisualState.loading
                        : AlongButtonVisualState.normal,
                    onPressed: busy ? null : onPay,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _groupIcon(AppLocalizations l10n, String day) {
  if (day == l10n.walletToday) return AlongIcons.schedule;
  if (day == l10n.walletYesterday) return AlongIcons.path;
  return AlongIcons.history;
}
