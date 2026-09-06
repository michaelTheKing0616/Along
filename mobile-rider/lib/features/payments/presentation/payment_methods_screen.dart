import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/payments/data/payments_providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-32 Payment methods — brand/last4 only, never PAN.
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _busy = false;

  Future<void> _refresh() async {
    ref.invalidate(savedPaymentMethodsProvider);
    await ref.read(savedPaymentMethodsProvider.future);
  }

  Future<void> _setDefault(PaymentMethodSummary method) async {
    setState(() => _busy = true);
    try {
      await ref.read(paymentsRepositoryProvider).setDefaultPaymentMethod(method.id);
      await setPaymentMethodPref(ref, PaymentMethodPref.savedCard);
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(PaymentMethodSummary method) async {
    setState(() => _busy = true);
    try {
      await ref.read(paymentsRepositoryProvider).removePaymentMethod(method.id);
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addMockCard() async {
    setState(() => _busy = true);
    try {
      await ref.read(paymentsRepositoryProvider).addPaymentMethod(
            authorizationCode: 'AUTH_test_${DateTime.now().millisecondsSinceEpoch}',
            brand: 'Visa',
            last4: '4242',
          );
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preferTransfer() async {
    await setPaymentMethodPref(ref, PaymentMethodPref.bankTransfer);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).payMethodsTransferDefault)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final methodsAsync = ref.watch(savedPaymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.payMethodsTitle)),
      body: methodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (methods) => ListView(
          padding: const EdgeInsets.all(AlongSpace.s16),
          children: [
            ListTile(
              key: const Key('pay_methods_transfer_pref'),
              title: Text(l10n.payMethodsTransferDefault),
              trailing: const Icon(Icons.account_balance),
              onTap: _busy ? null : _preferTransfer,
            ),
            const Divider(),
            ...methods.map(
              (m) => ListTile(
                key: Key('pay_method_${m.id}'),
                title: Text('${m.brand} ···${m.last4}'),
                subtitle: m.isDefault ? Text(l10n.payMethodsDefault) : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'default') _setDefault(m);
                    if (action == 'remove') _remove(m);
                  },
                  itemBuilder: (context) => [
                    if (!m.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Text(l10n.payMethodsSetDefault),
                      ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(l10n.payMethodsRemove),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AlongSpace.s16),
            AlongButton(
              key: const Key('pay_methods_add'),
              label: l10n.payMethodsAdd,
              variant: AlongButtonVariant.yellow,
              visualState: _busy
                  ? AlongButtonVisualState.loading
                  : AlongButtonVisualState.normal,
              onPressed: _busy ? null : _addMockCard,
            ),
          ],
        ),
      ),
    );
  }
}
