import 'dart:math';

import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Along credit. There is no wallet API yet, so the app overrides this with a
/// real repository once it ships; until then the screen shows its error state.
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => throw UnimplementedError('Wallet API not wired yet'),
);

final walletSummaryProvider = FutureProvider.autoDispose<WalletSummary>(
  (ref) => ref.watch(walletRepositoryProvider).fetch(),
);

/// Clock for history labels; tests pin it.
final walletNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _busy = false;

  /// One key per intended top up, so a double tap or retry credits once.
  String? _pendingKey;

  Future<void> _add(int amount) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    _pendingKey ??=
        'topup:${DateTime.now().microsecondsSinceEpoch}:${Random().nextInt(1 << 32)}';
    setState(() => _busy = true);
    try {
      await ref
          .read(walletRepositoryProvider)
          .topUp(amount: amount, idempotencyKey: _pendingKey!);
      _pendingKey = null;
      ref.invalidate(walletSummaryProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.walletAdded(alongNaira(amount)))),
      );
    } catch (_) {
      // Keep the key: the retry is the same top up, not a second one.
      messenger.showSnackBar(SnackBar(content: Text(l10n.walletTopUpFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addCustom() async {
    final amount = await showDialog<int>(
      context: context,
      builder: (_) => const _CustomAmountDialog(),
    );
    if (amount != null && mounted) await _add(amount);
  }

  String _when(AppLocalizations l10n, DateTime at, DateTime now) {
    final day = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.walletToday;
    if (diff == 1) return l10n.walletYesterday;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final tag = DateFormat.localeExists(locale) ? locale : 'en';
    return diff < 7
        ? DateFormat.EEEE(tag).format(at)
        : DateFormat.MMMd(tag).format(at);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(walletSummaryProvider);
    final now = ref.watch(walletNowProvider)();
    final strings = AlongTopUpStrings(
      title: l10n.walletTitle,
      subtitle: l10n.walletSubtitle,
      balance: l10n.walletBalance,
      balanceNote: l10n.walletBalanceNote,
      addCredit: l10n.walletAddCredit,
      custom: l10n.walletCustom,
      history: l10n.walletHistory,
      emptyHistory: l10n.walletHistoryEmpty,
      addCustom: l10n.walletAddCustom,
      add: l10n.walletAdd,
    );
    return summary.when(
      loading: () => const _WalletLoading(),
      error: (_, _) =>
          _WalletError(onRetry: () => ref.invalidate(walletSummaryProvider)),
      data: (data) => AlongFlowTopUp(
        key: const Key('wallet_topup'),
        balance: data.balance,
        strings: strings,
        busy: _busy,
        onAdd: _add,
        onAddCustom: _addCustom,
        history: [
          for (final e in data.entries)
            AlongCreditEntry(
              switch (e.kind) {
                WalletEntryKind.topUp => l10n.walletTopUp,
                WalletEntryKind.fare => l10n.walletFare,
                WalletEntryKind.refund => l10n.walletRefund,
              },
              _when(l10n, e.at, now),
              e.amount,
            ),
        ],
      ),
    );
  }
}

class _WalletLoading extends StatelessWidget {
  const _WalletLoading();

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AlongSkeleton(height: 36, width: 140),
              SizedBox(height: 16),
              AlongSkeleton(height: 120),
              SizedBox(height: 20),
              AlongSkeleton(height: 132),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletError extends StatelessWidget {
  const _WalletError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('wallet_error'),
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.walletTitle, style: AlongType.display(p)),
              const SizedBox(height: 4),
              Text(l10n.walletSubtitle, style: AlongType.bodyMuted(p)),
              const Spacer(),
              Semantics(
                liveRegion: true,
                child: Text(l10n.walletUnavailable, style: AlongType.title(p)),
              ),
              const SizedBox(height: 8),
              Text(l10n.walletUnavailableBody, style: AlongType.bodyMuted(p)),
              const Spacer(),
              AlongButton(
                key: const Key('wallet_retry'),
                label: l10n.walletRetry,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomAmountDialog extends StatefulWidget {
  const _CustomAmountDialog();

  @override
  State<_CustomAmountDialog> createState() => _CustomAmountDialogState();
}

class _CustomAmountDialogState extends State<_CustomAmountDialog> {
  final _field = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final amount = int.tryParse(_field.text);
    final error = validateTopUpAmount(amount);
    if (error == null) {
      Navigator.of(context).pop(amount);
      return;
    }
    setState(
      () => _error = error == 'tooLarge'
          ? l10n.walletCustomTooLarge
          : l10n.walletCustomTooSmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.walletCustomTitle),
      content: TextField(
        key: const Key('wallet_custom_field'),
        controller: _field,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          prefixText: '₦',
          hintText: l10n.walletCustomHint,
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.walletCancel),
        ),
        TextButton(
          key: const Key('wallet_custom_add'),
          onPressed: _submit,
          child: Text(l10n.walletAddCredit),
        ),
      ],
    );
  }
}
