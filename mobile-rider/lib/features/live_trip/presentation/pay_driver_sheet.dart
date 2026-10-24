import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart' as design show FareTier, formatMoney;
import 'package:along_design/along_design.dart' hide FareTier, formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/live_trip/domain/trip_ui_helpers.dart';
import 'package:mobile_rider/features/payments/data/payments_providers.dart';
import 'package:mobile_rider/features/payments/domain/informal_pay_amount.dart';
import 'package:mobile_rider/features/payments/presentation/payment_methods_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// R-27 Pay driver — transfer-first digital payment entry.
class PayDriverSheet extends ConsumerStatefulWidget {
  const PayDriverSheet({
    super.key,
    this.trip,
    this.receipt,
    this.driverCode,
    this.dynamicToken,
    this.preloadedResolve,
    this.autoInitiate = false,
  });

  final TripSummary? trip;
  final TripReceipt? receipt;
  final String? driverCode;
  final String? dynamicToken;
  final QrResolveResult? preloadedResolve;

  /// When true (in-trip Pay), start the transfer as soon as the amount is known.
  final bool autoInitiate;

  static Future<bool> show(
    BuildContext context, {
    TripSummary? trip,
    TripReceipt? receipt,
    String? driverCode,
    String? dynamicToken,
    QrResolveResult? preloadedResolve,
    bool autoInitiate = false,
  }) async {
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PayDriverSheet(
        trip: trip,
        receipt: receipt,
        driverCode: driverCode,
        dynamicToken: dynamicToken,
        preloadedResolve: preloadedResolve,
        autoInitiate: autoInitiate,
      ),
    );
    return paid ?? false;
  }

  @override
  ConsumerState<PayDriverSheet> createState() => _PayDriverSheetState();
}

enum _PayPhase { loading, cashOnly, inactive, ready, pending, success, failed }

class _PayDriverSheetState extends ConsumerState<PayDriverSheet> {
  _PayPhase _phase = _PayPhase.loading;
  QrResolveResult? _resolve;
  PaymentMethodPref _methodPref = PaymentMethodPref.bankTransfer;
  PaymentMethodSummary? _selectedMethod;
  Money? _selectedAmount;
  bool _differentDriverConfirmed = false;
  bool _busy = false;
  bool _showOtherKeypad = false;
  String? _errorMessage;
  PaymentInitiateResult? _initiateResult;
  PaymentReceipt? _paymentReceipt;
  bool _showHistoryOptIn = false;
  bool _historyOptIn = false;
  Timer? _receiptPoll;

  String? get _effectiveDriverCode =>
      widget.driverCode ?? widget.trip?.driver.driverQrCode;

  bool get _amountLocked =>
      widget.trip != null ||
      _resolve?.context?.locked == true ||
      widget.dynamicToken != null;

  InformalPayAmountMode get _amountMode => informalPayAmountMode(
        amountLocked: _amountLocked,
        suggestedAmounts: _resolve?.suggestedAmounts ?? const [],
      );

  Money get _amount {
    if (_resolve?.context != null) return _resolve!.context!.amount;
    if (widget.trip != null) return widget.trip!.totalFare;
    if (_selectedAmount != null) return _selectedAmount!;
    final unique = uniqueSuggestedAmount(_resolve?.suggestedAmounts ?? const []);
    if (unique != null) return unique;
    return Money.zero(currency: _resolve?.currency ?? 'NGN');
  }

  int get _minMinor =>
      _resolve?.minAmount?.minorUnits ?? 10000;

  bool get _amountReady => _amount.minorUnits >= _minMinor;

  bool get _payBlocked =>
      _resolve?.isDifferentDriver == true && !_differentDriverConfirmed;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _receiptPoll?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final pref = await ref.read(paymentMethodPrefProvider.future);
      final methods = await ref.read(savedPaymentMethodsProvider.future);
      if (!mounted) return;
      setState(() {
        _methodPref = pref;
        if (pref == PaymentMethodPref.savedCard) {
          _selectedMethod = methods.cast<PaymentMethodSummary?>().firstWhere(
                (m) => m?.isDefault == true,
                orElse: () => methods.isNotEmpty ? methods.first : null,
              );
        }
      });

      if (widget.preloadedResolve != null) {
        _applyResolve(widget.preloadedResolve!);
        await _maybeAutoInitiate();
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
        await _maybeAutoInitiate();
        return;
      }

      if (widget.trip != null) {
        setState(() => _phase = _PayPhase.ready);
        await _maybeAutoInitiate();
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
      } else {
        _selectedAmount = uniqueSuggestedAmount(resolved.suggestedAmounts);
      }
    }
    setState(() {});
  }

  Future<void> _maybeAutoInitiate() async {
    if (!widget.autoInitiate || !mounted) return;
    if (_phase != _PayPhase.ready || _payBlocked || !_amountReady) return;
    await _submitPay();
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

  Future<void> _submitPay() async {
    if (_payBlocked || _busy || !_amountReady) return;
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
        paymentMethodId: _methodPref == PaymentMethodPref.savedCard
            ? _selectedMethod?.id
            : null,
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
        _startReceiptPoll(result.paymentId);
        final checkout = result.authorizationUrl;
        if (checkout != null &&
            result.transferAccount == null &&
            result.ussdCode == null) {
          final uri = Uri.tryParse(checkout);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
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

  void _startReceiptPoll(String paymentId) {
    _receiptPoll?.cancel();
    _receiptPoll = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_checkReceipt(paymentId));
    });
  }

  Future<void> _checkReceipt(String paymentId) async {
    try {
      final receipt =
          await ref.read(paymentsRepositoryProvider).fetchReceipt(paymentId);
      if (!mounted || !receipt.isSucceeded) return;
      _receiptPoll?.cancel();
      setState(() {
        _paymentReceipt = receipt;
        _phase = _PayPhase.success;
        _showHistoryOptIn =
            widget.trip == null && _resolve?.context?.tripId == null;
      });
    } catch (_) {
      // Keep waiting — webhook may still be in flight.
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
      _methodPref = pref;
      if (pref == PaymentMethodPref.savedCard) {
        _selectedMethod = methods.cast<PaymentMethodSummary?>().firstWhere(
              (m) => m?.isDefault == true,
              orElse: () => methods.isNotEmpty ? methods.first : null,
            );
      } else {
        _selectedMethod = null;
      }
    });
  }

  void _popPaid() => Navigator.of(context).pop(true);

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
              amountLabel: design.formatMoney(amountNaira),
              onRetry: () {
                _receiptPoll?.cancel();
                setState(() => _phase = _PayPhase.ready);
              },
            ),
          _PayPhase.success => _SuccessView(
              receipt: _paymentReceipt!,
              initiate: _initiateResult!,
              showHistoryOptIn: _showHistoryOptIn,
              historyOptIn: _historyOptIn,
              onHistoryChanged: (v) => setState(() => _historyOptIn = v),
              onDone: _popPaid,
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
          _PayPhase.ready => _ReadyView(
              attachedTrip: attachedTrip,
              driver: driver,
              receipt: widget.receipt,
              amountNaira: amountNaira,
              hideAmountPicker: _amountMode == InformalPayAmountMode.uniqueFare,
              showLockedCaption: _amountLocked,
              amountMode: _amountMode,
              suggested: _resolve?.suggestedAmounts ?? const [],
              selectedAmount: _selectedAmount,
              showOtherKeypad: _showOtherKeypad ||
                  _amountMode == InformalPayAmountMode.keypadOnly,
              methodLabel: _methodLabel(l10n),
              busy: _busy,
              payBlocked: _payBlocked || !_amountReady,
              isDifferentDriver: _resolve?.isDifferentDriver == true,
              onConfirmOther: () =>
                  setState(() => _differentDriverConfirmed = true),
              onSelectAmount: (money) => setState(() {
                _selectedAmount = money;
                _showOtherKeypad = false;
              }),
              onShowOther: () => setState(() => _showOtherKeypad = true),
              onOtherChanged: (naira) => setState(() {
                _selectedAmount = Money.fromMinorUnits(
                  naira * 100,
                  currency: _resolve?.currency ?? 'NGN',
                );
              }),
              onChangeMethod: _openMethods,
              onPay: _submitPay,
            ),
        },
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({
    required this.attachedTrip,
    required this.driver,
    required this.receipt,
    required this.amountNaira,
    required this.hideAmountPicker,
    required this.showLockedCaption,
    required this.amountMode,
    required this.suggested,
    required this.selectedAmount,
    required this.showOtherKeypad,
    required this.methodLabel,
    required this.busy,
    required this.payBlocked,
    required this.isDifferentDriver,
    required this.onConfirmOther,
    required this.onSelectAmount,
    required this.onShowOther,
    required this.onOtherChanged,
    required this.onChangeMethod,
    required this.onPay,
  });

  final TripSummary? attachedTrip;
  final QrDriverInfo? driver;
  final TripReceipt? receipt;
  final int amountNaira;
  final bool hideAmountPicker;
  final bool showLockedCaption;
  final InformalPayAmountMode amountMode;
  final List<Money> suggested;
  final Money? selectedAmount;
  final bool showOtherKeypad;
  final String methodLabel;
  final bool busy;
  final bool payBlocked;
  final bool isDifferentDriver;
  final VoidCallback onConfirmOther;
  final ValueChanged<Money> onSelectAmount;
  final VoidCallback onShowOther;
  final ValueChanged<int> onOtherChanged;
  final VoidCallback onChangeMethod;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDifferentDriver) ...[
          Container(
            key: const Key('pay_driver_different_driver'),
            padding: const EdgeInsets.all(AlongSpace.s12),
            clipBehavior: Clip.antiAlias,
            decoration: AlongCraft.fill(
              AlongColors.semanticDanger.withValues(alpha: 0.12),
              corner: AlongRadius.row.x,
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
                  onPressed: onConfirmOther,
                ),
              ],
            ),
          ),
          const SizedBox(height: AlongSpace.s16),
        ],
        if (attachedTrip != null || driver != null) ...[
          Text(
            attachedTrip != null
                ? '${attachedTrip!.driver.displayName} · ${attachedTrip!.vehicle.plateNumber}'
                : '${driver!.firstName} · ${driver!.plate}',
            style: AlongText.bodyStrong,
          ),
          const SizedBox(height: AlongSpace.s8),
          if (attachedTrip != null)
            ModeChip(mode: designMode(attachedTrip!.modeCode))
          else if (driver != null)
            Text(
              driver!.plate,
              style: AlongText.numericL,
            ),
          const SizedBox(height: AlongSpace.s16),
        ],
        FareHero(
          key: const Key('pay_driver_amount'),
          amountNaira: amountNaira,
          tier: attachedTrip != null
              ? designFareTier(
                  attachedTrip!.fare.tier,
                  unconfirmed: attachedTrip!.fare.unconfirmed,
                )
              : design.FareTier.verified,
          lineItems: receipt?.lines
                  .map(
                    (line) => FareHeroLineItem(
                      label: line.label,
                      amountNaira: line.amount.minorUnits ~/ 100,
                    ),
                  )
                  .toList() ??
              const [],
          expanded: receipt != null,
        ),
        if (hideAmountPicker && !showLockedCaption) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('pay_driver_other_amount'),
              onPressed: onShowOther,
              child: Text(l10n.payDriverOtherAmount),
            ),
          ),
        ],
        if (showOtherKeypad && (hideAmountPicker && !showLockedCaption)) ...[
          TextField(
            key: const Key('pay_driver_other_field'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: l10n.payDriverOtherHint,
              prefixText: '₦ ',
            ),
            onChanged: (value) {
              final naira = int.tryParse(value);
              if (naira != null) onOtherChanged(naira);
            },
          ),
        ],
        if (showLockedCaption)
          Padding(
            padding: const EdgeInsets.only(top: AlongSpace.s8),
            child: Text(
              l10n.payDriverAmountLocked,
              style: AlongText.caption.copyWith(color: AlongColors.ink700),
            ),
          )
        else if (!hideAmountPicker) ...[
          if (amountMode == InformalPayAmountMode.chips) ...[
            const SizedBox(height: AlongSpace.s12),
            Wrap(
              spacing: AlongSpace.s8,
              children: [
                ...suggested.map(
                  (money) => ActionChip(
                    key: Key('pay_amount_chip_${money.minorUnits ~/ 100}'),
                    label: Text(design.formatMoney(money.minorUnits ~/ 100)),
                    onPressed: () => onSelectAmount(money),
                  ),
                ),
                ActionChip(
                  key: const Key('pay_driver_other_amount'),
                  label: Text(l10n.payDriverOtherAmount),
                  onPressed: onShowOther,
                ),
              ],
            ),
          ],
          if (showOtherKeypad) ...[
            const SizedBox(height: AlongSpace.s12),
            TextField(
              key: const Key('pay_driver_other_field'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: l10n.payDriverOtherHint,
                prefixText: '₦ ',
              ),
              onChanged: (value) {
                final naira = int.tryParse(value);
                if (naira != null) onOtherChanged(naira);
              },
            ),
          ],
        ],
        const SizedBox(height: AlongSpace.s16),
        Row(
          children: [
            Expanded(
              child: Text(methodLabel, style: AlongText.body),
            ),
            TextButton(
              key: const Key('pay_driver_change_method'),
              onPressed: onChangeMethod,
              child: Text(l10n.payDriverChangeMethod),
            ),
          ],
        ),
        const SizedBox(height: AlongSpace.s16),
        AlongButton(
          key: const Key('pay_driver_submit'),
          label: l10n.payDriverCta(design.formatMoney(amountNaira)),
          variant: AlongButtonVariant.yellow,
          visualState: busy
              ? AlongButtonVisualState.loading
              : AlongButtonVisualState.normal,
          onPressed: payBlocked || busy ? null : onPay,
        ),
      ],
    );
  }
}

class _PendingView extends StatelessWidget {
  const _PendingView({
    required this.result,
    required this.amountLabel,
    required this.onRetry,
  });

  final PaymentInitiateResult result;
  final String amountLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final transfer = result.transfer;
    final remaining = result.expiresAt.difference(DateTime.now()).inSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.payDriverPending(amountLabel),
          style: AlongText.heading2,
        ),
        if (transfer != null && transfer.accountNumber.isNotEmpty) ...[
          const SizedBox(height: AlongSpace.s16),
          if (transfer.bankName.isNotEmpty)
            Text(
              transfer.bankName,
              style: AlongText.bodyStrong,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AlongSpace.s8),
          Text(
            key: const Key('pay_driver_account_number'),
            transfer.accountNumber,
            style: AlongText.numericL,
            textAlign: TextAlign.center,
          ),
          if (transfer.accountName.isNotEmpty) ...[
            const SizedBox(height: AlongSpace.s4),
            Text(
              transfer.accountName,
              style: AlongText.caption.copyWith(color: AlongColors.ink700),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AlongSpace.s16),
          AlongButton(
            key: const Key('pay_driver_copy_account'),
            label: l10n.payDriverCopyAccount,
            variant: AlongButtonVariant.yellow,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: transfer.accountNumber),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.payDriverAccountCopied)),
              );
            },
          ),
        ],
        if (result.ussdCode != null) ...[
          const SizedBox(height: AlongSpace.s8),
          Text(result.ussdCode!, style: AlongText.numericM),
        ],
        if (result.authorizationUrl != null &&
            (transfer == null || transfer.accountNumber.isEmpty)) ...[
          const SizedBox(height: AlongSpace.s16),
          AlongButton(
            key: const Key('pay_driver_open_checkout'),
            label: l10n.payDriverOpenCheckout,
            variant: AlongButtonVariant.yellow,
            onPressed: () {
              final uri = Uri.tryParse(result.authorizationUrl!);
              if (uri != null) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
        const SizedBox(height: AlongSpace.s16),
        Text(
          l10n.payDriverWaitingTransfer,
          style: AlongText.bodyStrong,
          textAlign: TextAlign.center,
        ),
        if (remaining > 0) ...[
          const SizedBox(height: AlongSpace.s8),
          Text(
            l10n.payDriverExpires(remaining),
            style: AlongText.caption.copyWith(color: AlongColors.ink700),
            textAlign: TextAlign.center,
          ),
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
