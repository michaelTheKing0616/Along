import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
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

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setDefault(PaymentMethodSummary method) => _run(() async {
    await ref
        .read(paymentsRepositoryProvider)
        .setDefaultPaymentMethod(method.id);
    await setPaymentMethodPref(ref, PaymentMethodPref.savedCard);
    await _refresh();
  });

  Future<void> _remove(PaymentMethodSummary method) => _run(() async {
    await ref.read(paymentsRepositoryProvider).removePaymentMethod(method.id);
    await _refresh();
  });

  Future<void> _addMockCard() => _run(() async {
    await ref
        .read(paymentsRepositoryProvider)
        .addPaymentMethod(
          authorizationCode:
              'AUTH_test_${DateTime.now().millisecondsSinceEpoch}',
          brand: 'Visa',
          last4: '4242',
        );
    await _refresh();
  });

  Future<void> _preferTransfer() async {
    await setPaymentMethodPref(ref, PaymentMethodPref.bankTransfer);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).payMethodsTransferDefault),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final methodsAsync = ref.watch(savedPaymentMethodsProvider);
    final pref =
        ref.watch(paymentMethodPrefProvider).valueOrNull ??
        PaymentMethodPref.bankTransfer;

    return TripPage(
      title: l10n.payMethodsTitle,
      subtitle: l10n.payMethodsSubtitle,
      footer: AlongButton(
        key: const Key('pay_methods_add'),
        label: l10n.payMethodsAdd,
        visualState: _busy
            ? AlongButtonVisualState.loading
            : AlongButtonVisualState.normal,
        onPressed: _busy ? null : _addMockCard,
      ),
      children: [
        Text(l10n.payMethodsSectionDefault, style: AlongType.label(p)),
        const SizedBox(height: AlongSpace.s8),
        _MethodRow(
          key: const Key('pay_methods_transfer_pref'),
          icon: AlongIcons.bank,
          label: l10n.payDriverMethodTransfer,
          caption: l10n.payMethodsTransferHint,
          selected: pref == PaymentMethodPref.bankTransfer,
          onTap: _busy ? null : _preferTransfer,
        ),
        const SizedBox(height: AlongSpace.s24),
        Text(l10n.payMethodsCards, style: AlongType.label(p)),
        const SizedBox(height: AlongSpace.s8),
        ...methodsAsync.when(
          loading: () => [
            const AlongSkeleton(height: 72, width: double.infinity),
          ],
          error: (_, __) => [
            TripNotice(
              icon: AlongIcons.info,
              text: l10n.errorGeneric,
              warn: true,
            ),
          ],
          data: (methods) => methods.isEmpty
              ? [
                  TripPanel(
                    child: Row(
                      children: [
                        AlongIcon(AlongIcons.card, size: 24, color: p.muted),
                        const SizedBox(width: AlongSpace.s12),
                        Expanded(
                          child: Text(
                            l10n.payMethodsCardsEmpty,
                            style: AlongType.bodyMuted(p),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : [
                  for (final m in methods) ...[
                    _MethodRow(
                      key: Key('pay_method_${m.id}'),
                      icon: AlongIcons.card,
                      label: '${m.brand} ···${m.last4}',
                      caption: m.isDefault ? l10n.payMethodsDefault : null,
                      selected:
                          pref == PaymentMethodPref.savedCard && m.isDefault,
                      onTap: _busy ? null : () => _setDefault(m),
                      trailing: IconButton(
                        key: Key('pay_method_remove_${m.id}'),
                        tooltip: l10n.payMethodsRemove,
                        onPressed: _busy ? null : () => _remove(m),
                        icon: AlongIcon(
                          AlongIcons.trash,
                          size: 20,
                          color: p.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: AlongSpace.s8),
                  ],
                ],
        ),
        const SizedBox(height: AlongSpace.s8),
        Row(
          children: [
            AlongIcon(AlongIcons.lock, size: 20, color: p.muted),
            const SizedBox(width: AlongSpace.s8),
            Expanded(
              child: Text(l10n.payMethodsSecure, style: AlongType.caption(p)),
            ),
          ],
        ),
      ],
    );
  }
}

/// One payment method: icon, label, caption, and a check when it is the
/// default for paying drivers.
class _MethodRow extends StatelessWidget {
  const _MethodRow({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.caption,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? caption;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: p.recessed,
        shape: AlongCraft.border(
          20,
          side: selected ? BorderSide(color: p.ink, width: 2) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AlongSpace.s16,
                AlongSpace.s12,
                AlongSpace.s8,
                AlongSpace.s12,
              ),
              child: Row(
                children: [
                  AlongIcon(icon, size: 24, color: p.ink),
                  const SizedBox(width: AlongSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: AlongType.label(p)),
                        if (caption != null)
                          Text(caption!, style: AlongType.caption(p)),
                      ],
                    ),
                  ),
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AlongSpace.s8,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: p.ink,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            AlongIcons.check,
                            size: 16,
                            color: p.onInk,
                          ),
                        ),
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
