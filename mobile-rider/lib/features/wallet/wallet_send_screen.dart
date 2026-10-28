import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/wallet/wallet_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Send Along credit to another rider by phone number.
class WalletSendScreen extends ConsumerStatefulWidget {
  const WalletSendScreen({super.key});

  @override
  ConsumerState<WalletSendScreen> createState() => _WalletSendScreenState();
}

class _WalletSendScreenState extends ConsumerState<WalletSendScreen> {
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  bool _busy = false;
  bool _submitted = false;
  String? _serverError;

  /// Kept until the send succeeds or the rider changes the request.
  String? _key;

  @override
  void initState() {
    super.initState();
    void reset() => setState(() {
      _key = null;
      _serverError = null;
    });
    _phone.addListener(reset);
    _amount.addListener(reset);
  }

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _send(String phone, int amount) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final key = _key ??= walletKey('send');
    setState(() => _busy = true);
    try {
      await ref
          .read(walletRepositoryProvider)
          .send(phone: phone, amount: amount, idempotencyKey: key);
      ref.invalidate(walletSummaryProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.walletSentSnack(alongNaira(amount)))),
      );
      if (navigator.canPop()) navigator.pop();
    } on WalletException catch (e) {
      setState(
        () => _serverError = switch (e.failure) {
          WalletFailure.notFound => l10n.walletSendNotFound,
          WalletFailure.insufficientFunds => l10n.walletInsufficient,
          _ => l10n.walletActionFailed,
        },
      );
    } catch (_) {
      setState(() => _serverError = l10n.walletActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final balance = ref.watch(walletSummaryProvider).value?.balance ?? 0;
    final phone = normaliseNgPhone(_phone.text);
    final amount = int.tryParse(_amount.text);
    final amountError = validateSendAmount(amount, balance);
    final phoneMsg = _submitted && phone == null
        ? l10n.walletSendPhoneInvalid
        : null;
    final amountMsg = (_submitted || amount != null)
        ? switch (amountError) {
            'tooSmall' => l10n.walletSendTooSmall,
            'tooLarge' => l10n.walletSendTooLarge,
            'insufficient' => l10n.walletSendOverBalance,
            _ => null,
          }
        : null;
    final ready = phone != null && amountError == null;
    return WalletPage(
      title: l10n.walletSendTitle,
      subtitle: l10n.walletSendSubtitle,
      footer: AlongButton(
        key: const Key('wallet_send_cta'),
        label: amount != null && amountError == null
            ? l10n.walletSendCta(alongNaira(amount))
            : l10n.walletSendCtaEmpty,
        visualState: _busy
            ? AlongButtonVisualState.loading
            : AlongButtonVisualState.normal,
        onPressed: _busy
            ? null
            : () {
                if (!ready) {
                  setState(() => _submitted = true);
                  return;
                }
                _send(phone, amount!);
              },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('wallet_send_phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.walletSendPhone,
              hintText: l10n.walletSendPhoneHint,
              errorText: phoneMsg,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('wallet_send_amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.walletSendAmount,
              prefixText: '₦',
              helperText: l10n.walletAvailable(alongNaira(balance)),
              errorText: amountMsg,
            ),
          ),
          if (_serverError != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                _serverError!,
                key: const Key('wallet_send_error'),
                style: AlongType.body(p).copyWith(color: p.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
