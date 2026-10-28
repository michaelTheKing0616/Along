import 'dart:math';

import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_rider/di/providers.dart' show alongSupabaseProvider;
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Along credit over the `get_wallet` / `wallet_*` RPCs. Tests override it.
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => SupabaseWalletRepository(ref.watch(alongSupabaseProvider)),
);

/// A fresh client key for one intended money movement.
String walletKey(String kind) =>
    '$kind:${DateTime.now().microsecondsSinceEpoch}:${Random().nextInt(1 << 32)}';

/// What to tell the rider when a wallet write fails.
String walletFailureText(AppLocalizations l10n, Object error) =>
    error is WalletException && error.failure == WalletFailure.insufficientFunds
    ? l10n.walletInsufficient
    : l10n.walletActionFailed;

final walletSummaryProvider = FutureProvider.autoDispose<WalletSummary>(
  (ref) => ref.watch(walletRepositoryProvider).fetch(),
);

/// Clock for history labels; tests pin it.
final walletNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Top up Along credit with preset or custom amounts.
class WalletTopUpScreen extends ConsumerStatefulWidget {
  const WalletTopUpScreen({super.key});

  @override
  ConsumerState<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends ConsumerState<WalletTopUpScreen> {
  bool _busy = false;

  /// One key per intended top up, so a double tap or retry credits once.
  String? _pendingKey;

  Future<void> _add(int amount) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    _pendingKey ??= walletKey('topup');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(walletSummaryProvider);
    final now = ref.watch(walletNowProvider)();
    final strings = AlongTopUpStrings(
      title: l10n.walletActionTopUp,
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
      loading: () => const WalletLoadingView(),
      error: (_, _) =>
          WalletErrorView(onRetry: () => ref.invalidate(walletSummaryProvider)),
      data: (data) => AlongFlowTopUp(
        key: const Key('wallet_topup'),
        balance: data.balance,
        strings: strings,
        busy: _busy,
        onBack: Navigator.of(context).canPop()
            ? () => Navigator.of(context).maybePop()
            : null,
        onAdd: _add,
        onAddCustom: _addCustom,
        history: [
          for (final e in data.entries)
            AlongCreditEntry(
              walletEntryTitle(l10n, e),
              walletWhen(context, l10n, e.at, now),
              e.amount,
            ),
        ],
      ),
    );
  }
}

class WalletLoadingView extends StatelessWidget {
  const WalletLoadingView({super.key});

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

class WalletErrorView extends StatelessWidget {
  const WalletErrorView({super.key, required this.onRetry});

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

/// Day label for a history line: Today, Yesterday, weekday, or date.
String walletWhen(
  BuildContext context,
  AppLocalizations l10n,
  DateTime at,
  DateTime now,
) {
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

/// Second line of a history row: clock time today and yesterday (the group
/// header already names the day), otherwise the day label.
String walletDetail(
  BuildContext context,
  AppLocalizations l10n,
  DateTime at,
  DateTime now,
) {
  final day = DateTime(at.year, at.month, at.day);
  final diff = DateTime(now.year, now.month, now.day).difference(day).inDays;
  if (diff > 1) return walletWhen(context, l10n, at, now);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final tag = DateFormat.localeExists(locale) ? locale : 'en';
  return DateFormat.Hm(tag).format(at);
}

/// Title for a history line, naming the other rider on sends and splits.
String walletEntryTitle(AppLocalizations l10n, WalletEntry e) {
  final who = e.counterparty;
  return switch (e.kind) {
    WalletEntryKind.topUp => l10n.walletTopUp,
    WalletEntryKind.fare => l10n.walletFare,
    WalletEntryKind.refund => l10n.walletRefund,
    WalletEntryKind.pass => l10n.walletPassEntry,
    WalletEntryKind.send when who != null =>
      e.amount < 0 ? l10n.walletSentTo(who) : l10n.walletReceivedFrom(who),
    WalletEntryKind.send =>
      e.amount < 0 ? l10n.walletSent : l10n.walletReceived,
    WalletEntryKind.split =>
      e.amount < 0 ? l10n.walletSplitPaid : l10n.walletSplitReceived,
  };
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

/// Round initials disc for a rider with no photo.
/// Soft map tints that read in light and dark; stable per seed.
Color walletAvatarTint(AlongPalette p, String seed) {
  final tints = [p.mapPark, p.mapWater, p.mapLand, p.recessed];
  final h = seed.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
  return tints[h % tints.length];
}

class WalletInitials extends StatelessWidget {
  const WalletInitials({
    super.key,
    required this.name,
    this.size = 40,
    this.highlight = false,
    this.label,
    this.tintSeed,
    this.icon,
  });

  /// Shown instead of initials, e.g. a person glyph for an empty seat.
  final IconData? icon;

  final String name;

  /// Shown instead of initials, e.g. a seat number.
  final String? label;

  /// Picks the tint; defaults to [name] so one person keeps one colour.
  final String? tintSeed;
  final double size;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final initials = label != null
        ? label!
        : parts.isEmpty
        ? '·'
        : parts.take(2).map((w) => w.characters.first.toUpperCase()).join();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlight ? p.accent : walletAvatarTint(p, tintSeed ?? name),
          shape: BoxShape.circle,
          border: AlongElevation.hairline(p.ink),
        ),
        child: icon != null
            ? AlongIcon(icon!, size: size * 0.5, color: p.ink)
            : Text(
                initials,
                maxLines: 1,
                style: AlongType.body(p).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.36,
                  color: highlight ? p.accentInk : p.ink,
                ),
              ),
      ),
    );
  }
}

/// Page frame shared by the wallet sub-screens: back, title, subtitle, body,
/// and a pinned footer action.
class WalletPage extends StatelessWidget {
  const WalletPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (Navigator.of(context).canPop())
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: const Offset(-12, 0),
                    child: BackButton(color: p.ink),
                  ),
                )
              else
                const SizedBox(height: 16),
              Text(title, style: AlongType.display(p)),
              const SizedBox(height: 4),
              Text(subtitle, style: AlongType.bodyMuted(p)),
              const SizedBox(height: 20),
              Expanded(child: SingleChildScrollView(child: child)),
              const SizedBox(height: 12),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}
