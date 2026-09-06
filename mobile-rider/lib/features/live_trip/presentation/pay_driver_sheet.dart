import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart' as design show FareTier, formatMoney;
import 'package:along_design/along_design.dart' hide FareTier, formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/live_trip/domain/trip_ui_helpers.dart';
import 'package:mobile_rider/features/payments/data/payments_providers.dart';
import 'package:mobile_rider/features/payments/presentation/payment_methods_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-27 Pay driver — all digital payment entry points and states.
class PayDriverSheet extends ConsumerStatefulWidget {
  const PayDriverSheet({
    super.key,
    this.trip,
    this.receipt,
    this.driverCode,
    this.dynamicToken,
    this.preloadedResolve,
  });

  final TripSummary? trip;
  final TripReceipt? receipt;
  final String? driverCode;
  final String? dynamicToken;
  final QrResolveResult? preloadedResolve;

  static Future<void> show(
    BuildContext context, {
    TripSummary? trip,
    TripReceipt? receipt,
    String? driverCode,
    String? dynamicToken,
    QrResolveResult? preloadedResolve,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PayDriverSheet(
        trip: trip,
        receipt: receipt,
        driverCode: driverCode,
        dynamicToken: dynamicToken,
        preloadedResolve: preloadedResolve,
      ),
    );
  }

  @override
  ConsumerState<PayDriverSheet> createState() => _PayDriverSheetState();
}

enum _PayPhase { loading, cashOnly, inactive, ready, pending, success, failed }

class _PayDriverSheetState extends ConsumerState<PayDriverSheet> {
  _PayPhase _phase = _PayPhase.loading;
  QrResolveResult? _resolve;
  List<PaymentMethodSummary> _methods = const [];
  PaymentMethodPref _methodPref = PaymentMethodPref.bankTransfer;
  PaymentMethodSummary? _selectedMethod;
  Money? _selectedAmount;
  bool _differentDriverConfirmed = false;
  bool _busy = false;
  String? _errorMessage;
  PaymentInitiateResult? _initiateResult;
  PaymentReceipt? _paymentReceipt;
  bool _showHistoryOptIn = false;
  bool _historyOptIn = false;

  String? get _effectiveDriverCode =>
      widget.driverCode ?? widget.trip?.driver.driverQrCode;

  bool get _amountLocked =>
      widget.trip != null ||
      _resolve?.context?.locked == true ||
      widget.dynamicToken != null;

  Money get _amount {
    if (_resolve?.context != null) return _resolve!.context!.amount;
    if (widget.trip != null) return widget.trip!.totalFare;
    if (_selectedAmount != null) return _selectedAmount!;
    if (_resolve?.suggestedAmounts.isNotEmpty == true) {
      return _resolve!.suggestedAmounts.first;
    }
    return Money.parse('500.00', currency: 'NGN');
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final pref = await ref.read(paymentMethodPrefProvider.future);
      final methods = await ref.read(savedPaymentMethodsProvider.future);
      if (!mounted) return;
      setState(() {
        _methodPref = pref;
        _methods = methods;
        _selectedMethod = methods.cast<PaymentMethodSummary?>().firstWhere(
              (m) => m?.isDefault == true,
              orElse: () => methods.isNotEmpty ? methods.first : null,
            );
      });

      if (widget.preloadedResolve != null) {
        _applyResolve(widget.preloadedResolve!);
        return;
      }

      final code = widget.driverCode;
      if (code != null) {
        final resolved = await ref.read(paymentsRepositoryProvider).resolveQr(
              driverCode: code,
              token: widget.dynamicToken,
            );
        if (!mounted) return;
        _applyResolve(resolved);
        return;
      }

      if (widget.trip != null) {
        setState(() => _phase = _PayPhase.ready);
      } else {
        setState(() => _phase = _PayPhase.inactive);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _PayPhase.inactive;
        _errorMessage = e.toString();
      });
    }
  }

  void _applyResolve(QrResolveResult resolved) {
    _resolve = resolved;
    if (resolved.driver == null || resolved.driver!.active == false) {
      _phase = _PayPhase.inactive;
    } else if (!resolved.driver!.acceptsDigital) {
      _phase = _PayPhase.cashOnly;
    } else {
      _phase = _PayPhase.ready;
      if (resolved.context != null) {
        _selectedAmount = resolved.context!.amount;
      } else if (resolved.suggestedAmounts.isNotEmpty) {
        _selectedAmount = resolved.suggestedAmounts.first;
      }
    }
    setState(() {});
  }

  String _methodPrefWire() {
    if (_methodPref == PaymentMethodPref.savedCard && _selectedMethod != null) {
      return 'saved';
    }
    return switch (_methodPref) {
      PaymentMethodPref.bankTransfer => 'bank_transfer',
      PaymentMethodPref.ussd => 'ussd',
      PaymentMethodPref.savedCard => 'card',
    };
  }

  String _methodLabel(AppLocalizations l10n) {
    if (_methodPref == PaymentMethodPref.savedCard && _selectedMethod != null) {
      return '${_selectedMethod!.brand} ···${_selectedMethod!.last4}';
    }
    return switch (_methodPref) {
      PaymentMethodPref.bankTransfer => l10n.payDriverMethodTransfer,
      PaymentMethodPref.ussd => l10n.payDriverMethodUssd,
      PaymentMethodPref.savedCard => l10n.payDriverMethodSaved,
    };
  }

  bool get _payBlocked =>
      _resolve?.isDifferentDriver == true && !_differentDriverConfirmed;

  Future<void> _submitPay() async {
    if (_payBlocked || _busy) return;
    final code = _effectiveDriverCode;
    if (code == null && widget.trip == null) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(paymentsRepositoryProvider);
      final result = await repo.initiatePayment(
        driverCode: code ?? 'TRIP0000',
        tripId: widget.trip?.tripId ?? _resolve?.context?.tripId,
        amount: _amountLocked ? null : _amount,
        token: widget.dynamicToken,
        methodPref: _methodPrefWire(),
        confirmOtherDriver: _differentDriverConfirmed,
        paymentMethodId: _selectedMethod?.id,
      );

      if (result.isImmediateSuccess) {
        final receipt = await repo.fetchReceipt(result.paymentId);
        if (!mounted) return;
        setState(() {
          _initiateResult = result;
          _paymentReceipt = receipt;
          _phase = _PayPhase.success;
          _showHistoryOptIn =
              widget.trip == null && _resolve?.context?.tripId == null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _initiateResult = result;
          _phase = _PayPhase.pending;
        });
      }
    } on AlongException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _PayPhase.failed;
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMethods() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const PaymentMethodsScreen(),
      ),
    );
    final methods = await ref.read(savedPaymentMethodsProvider.future);
    final pref = await ref.read(paymentMethodPrefProvider.future);
    if (!mounted) return;
    setState(() {
      _methods = methods;
      _methodPref = pref;
      _selectedMethod = methods.cast<PaymentMethodSummary?>().firstWhere(
            (m) => m?.isDefault == true,
            orElse: () => methods.isNotEmpty ? methods.first : null,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final attachedTrip = widget.trip;
    final driver = _resolve?.driver;
    final amountNaira = _amount.minorUnits ~/ 100;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AlongBottomSheet(
        size: AlongBottomSheetSize.full,
        title: l10n.payDriverTitle,
        child: switch (_phase) {
          _PayPhase.loading => const Center(
              key: Key('pay_driver_loading'),
              child: Padding(
                padding: EdgeInsets.all(AlongSpace.s24),
                child: CircularProgressIndicator(color: AlongColors.brandYellow),
              ),
            ),
          _PayPhase.cashOnly => Text(
              key: const Key('pay_driver_cash_only'),
              l10n.payDriverCashOnly(driver?.firstName ?? ''),
              style: AlongText.heading2,
            ),
          _PayPhase.inactive => Text(
              key: const Key('pay_driver_inactive'),
              l10n.payDriverInactive,
              style: AlongText.heading2,
            ),
          _PayPhase.pending => _PendingView(
              result: _initiateResult!,
              onRetry: () => setState(() => _phase = _PayPhase.ready),
            ),
          _PayPhase.success => _SuccessView(
              receipt: _paymentReceipt!,
              initiate: _initiateResult!,
              showHistoryOptIn: _showHistoryOptIn,
              historyOptIn: _historyOptIn,
              onHistoryChanged: (v) => setState(() => _historyOptIn = v),
              onDone: () => Navigator.of(context).pop(),
            ),
          _PayPhase.failed => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _errorMessage ?? l10n.payDriverFailed,
                  style: AlongText.body.copyWith(color: AlongColors.semanticDanger),
                ),
                const SizedBox(height: AlongSpace.s16),
                AlongButton(
                  key: const Key('pay_driver_retry'),
                  label: l10n.payDriverRetry,
                  variant: AlongButtonVariant.yellow,
                  onPressed: () => setState(() => _phase = _PayPhase.ready),
                ),
              ],
            ),
          _PayPhase.ready => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_resolve?.isDifferentDriver == true) ...[
                  Container(
                    key: const Key('pay_driver_different_driver'),
                    padding: const EdgeInsets.all(AlongSpace.s12),
                    decoration: BoxDecoration(
                      color: AlongColors.semanticDanger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AlongRadius.md.x),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.payDriverDifferentDriver,
                          style: AlongText.bodyStrong.copyWith(
                            color: AlongColors.semanticDanger,
                          ),
                        ),
                        const SizedBox(height: AlongSpace.s8),
                        AlongButton(
                          key: const Key('pay_driver_confirm_other'),
                          label: l10n.payDriverConfirmOther,
                          variant: AlongButtonVariant.secondary,
                          onPressed: () =>
                              setState(() => _differentDriverConfirmed = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AlongSpace.s16),
                ],
                if (attachedTrip != null || driver != null) ...[
                  Text(
                    attachedTrip != null
                        ? '${attachedTrip.driver.displayName} · ${attachedTrip.vehicle.plateNumber}'
                        : '${driver!.firstName} · ${driver.plate}',
                    style: AlongText.bodyStrong,
                  ),
                  const SizedBox(height: AlongSpace.s8),
                  if (attachedTrip != null)
                    ModeChip(mode: designMode(attachedTrip.modeCode))
                  else if (driver != null)
                    Text(
                      driver.plate,
                      style: AlongText.numericL,
                    ),
                  const SizedBox(height: AlongSpace.s16),
                ],
                FareHero(
                  key: const Key('pay_driver_amount'),
                  amountNaira: amountNaira,
                  tier: attachedTrip != null
                      ? designFareTier(
                          attachedTrip.fare.tier,
                          unconfirmed: attachedTrip.fare.unconfirmed,
                        )
                      : design.FareTier.verified,
                  lineItems: widget.receipt?.lines
                          .map(
                            (line) => FareHeroLineItem(
                              label: line.label,
                              amountNaira: line.amount.minorUnits ~/ 100,
                            ),
                          )
                          .toList() ??
                      const [],
                  expanded: widget.receipt != null,
                ),
                if (_amountLocked)
                  Padding(
                    padding: const EdgeInsets.only(top: AlongSpace.s8),
                    child: Text(
                      l10n.payDriverAmountLocked,
                      style: AlongText.caption.copyWith(color: AlongColors.ink700),
                    ),
                  )
                else ...[
                  const SizedBox(height: AlongSpace.s12),
                  Wrap(
                    spacing: AlongSpace.s8,
                    children: (_resolve?.suggestedAmounts.isNotEmpty == true
                            ? _resolve!.suggestedAmounts
                            : [
                                Money.parse('400.00', currency: 'NGN'),
                                Money.parse('500.00', currency: 'NGN'),
                                Money.parse('600.00', currency: 'NGN'),
                              ])
                        .map(
                          (money) => ActionChip(
                            key: Key(
                              'pay_amount_chip_${money.minorUnits ~/ 100}',
                            ),
                            label: Text(design.formatMoney(money.minorUnits ~/ 100)),
                            onPressed: () =>
                                setState(() => _selectedAmount = money),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: AlongSpace.s16),
                Row(
                  children: [
                    Expanded(
                      child: Text(_methodLabel(l10n), style: AlongText.body),
                    ),
                    TextButton(
                      key: const Key('pay_driver_change_method'),
                      onPressed: _openMethods,
                      child: Text(l10n.payDriverChangeMethod),
                    ),
                  ],
                ),
                const SizedBox(height: AlongSpace.s16),
                AlongButton(
                  key: const Key('pay_driver_submit'),
                  label: l10n.payDriverCta(design.formatMoney(amountNaira)),
                  variant: AlongButtonVariant.yellow,
                  visualState: _busy
                      ? AlongButtonVisualState.loading
                      : AlongButtonVisualState.normal,
                  onPressed: _payBlocked || _busy ? null : _submitPay,
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _PendingView extends StatelessWidget {
  const _PendingView({required this.result, required this.onRetry});

  final PaymentInitiateResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final transfer = result.transferAccount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.payDriverPending, style: AlongText.heading2),
        if (transfer != null) ...[
          const SizedBox(height: AlongSpace.s12),
          Text(
            '${transfer['bank_name'] ?? ''} · ${transfer['account_number'] ?? ''}',
            style: AlongText.body,
          ),
        ],
        if (result.ussdCode != null) ...[
          const SizedBox(height: AlongSpace.s8),
          Text(result.ussdCode!, style: AlongText.numericM),
        ],
        const SizedBox(height: AlongSpace.s16),
        AlongButton(
          label: l10n.payDriverRetry,
          variant: AlongButtonVariant.secondary,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.receipt,
    required this.initiate,
    required this.showHistoryOptIn,
    required this.historyOptIn,
    required this.onHistoryChanged,
    required this.onDone,
  });

  final PaymentReceipt receipt;
  final PaymentInitiateResult initiate;
  final bool showHistoryOptIn;
  final bool historyOptIn;
  final ValueChanged<bool> onHistoryChanged;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driverNaira = receipt.driverAmount.minorUnits ~/ 100;
    final feeNaira = receipt.commissionAmount.minorUnits ~/ 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.payDriverSuccessTitle, style: AlongText.heading2),
        const SizedBox(height: AlongSpace.s12),
        Text(
          key: const Key('pay_driver_success_itemised'),
          l10n.payDriverSuccessItemised(
            design.formatMoney(driverNaira),
            receipt.driverFirstName,
            design.formatMoney(feeNaira),
          ),
          style: AlongText.body,
        ),
        if (showHistoryOptIn) ...[
          const SizedBox(height: AlongSpace.s16),
          CheckboxListTile(
            key: const Key('pay_driver_history_opt_in'),
            value: historyOptIn,
            onChanged: (v) => onHistoryChanged(v ?? false),
            title: Text(l10n.payDriverHistoryOptIn),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
        const SizedBox(height: AlongSpace.s16),
        AlongButton(
          key: const Key('pay_driver_done'),
          label: l10n.loadFlagDone,
          variant: AlongButtonVariant.yellow,
          onPressed: onDone,
        ),
      ],
    );
  }
}
