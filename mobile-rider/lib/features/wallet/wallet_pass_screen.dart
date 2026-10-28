import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/wallet/wallet_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Buy this month's Along Pass from wallet credit.
class WalletPassScreen extends ConsumerStatefulWidget {
  const WalletPassScreen({super.key});

  @override
  ConsumerState<WalletPassScreen> createState() => _WalletPassScreenState();
}

class _WalletPassScreenState extends ConsumerState<WalletPassScreen> {
  bool _busy = false;
  bool _bought = false;
  String? _key;
  String? _error;

  Future<void> _buy() async {
    final l10n = AppLocalizations.of(context);
    final key = _key ??= walletKey('pass');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(walletRepositoryProvider).buyPass(idempotencyKey: key);
      ref.invalidate(walletSummaryProvider);
      setState(() => _bought = true);
    } catch (e) {
      setState(() => _error = walletFailureText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final balance = ref.watch(walletSummaryProvider).value?.balance;
    final short = balance == null || _bought
        ? 0
        : (walletPassPrice - balance).clamp(0, walletPassPrice);
    final Widget footer;
    if (_bought) {
      footer = AlongButton(
        key: const Key('wallet_pass_done'),
        label: l10n.walletPassBought,
        variant: AlongButtonVariant.secondary,
        onPressed: () => Navigator.of(context).maybePop(),
      );
    } else if (short > 0) {
      footer = AlongButton(
        key: const Key('wallet_pass_topup'),
        label: l10n.walletPassShort(alongNaira(short)),
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const WalletTopUpScreen()),
        ),
      );
    } else {
      footer = AlongButton(
        key: const Key('wallet_pass_cta'),
        label: l10n.walletPassCta(alongNaira(walletPassPrice)),
        visualState: _busy
            ? AlongButtonVisualState.loading
            : AlongButtonVisualState.normal,
        onPressed: _busy ? null : _buy,
      );
    }
    return WalletPage(
      title: l10n.walletPassTitle,
      subtitle: l10n.walletPassSubtitle,
      footer: footer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: const Key('wallet_pass_card'),
            decoration: AlongCraft.surface(p, radius: AlongRadius.card.x),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AlongIcon(
                        _bought ? AlongIcons.verified : AlongIcons.receipt,
                        size: 24,
                        color: p.ink,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.walletPassTitle,
                          style: AlongType.title(p),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.walletPassPrice(alongNaira(walletPassPrice)),
                    style: AlongType.display(p).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.walletPassBody, style: AlongType.bodyMuted(p)),
                  if (balance != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.walletAvailable(alongNaira(balance)),
                      key: const Key('wallet_pass_balance'),
                      style: AlongType.caption(p),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                key: const Key('wallet_pass_error'),
                style: AlongType.body(p).copyWith(color: p.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
