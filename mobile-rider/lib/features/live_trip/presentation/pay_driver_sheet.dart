import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart' hide FareTier, formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/payments/data/payments_providers.dart';
import 'package:mobile_rider/features/payments/domain/informal_pay_amount.dart';
import 'package:mobile_rider/features/payments/presentation/payment_methods_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/tenant/tenant_providers.dart';
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
    final unique = uniqueSuggestedAmount(
      _resolve?.suggestedAmounts ?? const [],
    );
    if (unique != null) return unique;
    return Money.zero(currency: _resolve?.currency ?? 'NGN');
  }

  int get _minMinor => _resolve?.minAmount?.minorUnits ?? 10000;

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
        final resolved = await ref
            .read(paymentsRepositoryProvider)
            .resolveQr(driverCode: code, token: widget.dynamicToken);
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
      final receipt = await ref
          .read(paymentsRepositoryProvider)
          .fetchReceipt(paymentId);
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
    final amountNaira = majorUnits(_amount);

    return TripModalSheet(
      title: l10n.payDriverTitle,
      icon: AlongIcons.wallet,
      children: [
        switch (_phase) {
          _PayPhase.loading => const Center(
            key: Key('pay_driver_loading'),
            child: Padding(
              padding: EdgeInsets.all(AlongSpace.s24),
              child: AlongSkeleton(variant: SkeletonVariant.line),
            ),
          ),
          _PayPhase.cashOnly => TripNotice(
            key: const Key('pay_driver_cash_only'),
            icon: AlongIcons.wallet,
            text: l10n.payDriverCashOnly(driver?.firstName ?? ''),
          ),
          _PayPhase.inactive => TripNotice(
            key: const Key('pay_driver_inactive'),
            icon: AlongIcons.info,
            text: l10n.payDriverInactive,
            warn: true,
          ),
          _PayPhase.pending => _PendingView(
            result: _initiateResult!,
            amountLabel: formatAppMoneyMajor(ref, amountNaira),
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
              TripNotice(
                icon: AlongIcons.info,
                text: _errorMessage ?? l10n.payDriverFailed,
                warn: true,
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
            showOtherKeypad:
                _showOtherKeypad ||
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
      ],
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
    final p = AlongPalette.of(context);
    String money(int major) =>
        ProviderScope.containerOf(context)
            .read(appMoneyFormatterProvider)
            .formatMajor(major);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDifferentDriver) ...[
          Container(
            key: const Key('pay_driver_different_driver'),
            padding: const EdgeInsets.all(AlongSpace.s12),
            decoration: AlongCraft.compactFill(
              p.danger.withValues(alpha: 0.10),
              96,
              corner: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.payDriverDifferentDriver,
                  style: AlongType.label(p).copyWith(color: p.danger),
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
        TripPanel(
          key: const Key('pay_driver_amount'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (attachedTrip != null || driver != null) ...[
                Row(
                  children: [
                    TripDriverAvatar(
                      name:
                          attachedTrip?.driver.displayName ?? driver!.firstName,
                      size: 40,
                    ),
                    const SizedBox(width: AlongSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attachedTrip?.driver.displayName ??
                                driver!.firstName,
                            style: AlongType.label(p),
                          ),
                          Text(
                            attachedTrip?.vehicle.plateNumber ?? driver!.plate,
                            style: AlongType.caption(p),
                          ),
                        ],
                      ),
                    ),
                    if (attachedTrip != null)
                      TripModeTile(modeCode: attachedTrip!.modeCode, size: 36),
                  ],
                ),
                const SizedBox(height: AlongSpace.s16),
              ],
              Text(l10n.tripCompleteFareLabel, style: AlongType.caption(p)),
              Text(money(amountNaira), style: AlongType.display(p)),
              if (receipt != null) ...[
                const SizedBox(height: AlongSpace.s8),
                for (final line in receipt!.lines)
                  Padding(
                    padding: const EdgeInsets.only(top: AlongSpace.s4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(line.label, style: AlongType.caption(p)),
                        ),
                        Text(
                          money(majorUnits(line.amount)),
                          style: AlongType.caption(p),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (hideAmountPicker && !showLockedCaption) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('pay_driver_other_amount'),
              style: TextButton.styleFrom(
                foregroundColor: p.ink,
                shape: AlongCraft.border(12),
              ),
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
            style: AlongType.body(p),
            decoration: tripInputDecoration(p, hint: l10n.payDriverOtherHint)
                .copyWith(
                  prefixText:
                      '${ProviderScope.containerOf(context).read(appMoneyFormatterProvider).currencySymbol} ',
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
              style: AlongType.caption(p),
            ),
          )
        else if (!hideAmountPicker) ...[
          if (amountMode == InformalPayAmountMode.chips) ...[
            const SizedBox(height: AlongSpace.s12),
            Wrap(
              spacing: AlongSpace.s8,
              runSpacing: AlongSpace.s8,
              children: [
                for (final m in suggested)
                  _AmountChoice(
                    key: Key('pay_amount_chip_${majorUnits(m)}'),
                    label: ProviderScope.containerOf(context)
                        .read(appMoneyFormatterProvider)
                        .format(m),
                    selected: selectedAmount == m,
                    onTap: () => onSelectAmount(m),
                  ),
                _AmountChoice(
                  key: const Key('pay_driver_other_amount'),
                  label: l10n.payDriverOtherAmount,
                  selected: showOtherKeypad,
                  onTap: onShowOther,
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
              style: AlongType.body(p),
              decoration: tripInputDecoration(p, hint: l10n.payDriverOtherHint)
                  .copyWith(
                    prefixText:
                        '${ProviderScope.containerOf(context).read(appMoneyFormatterProvider).currencySymbol} ',
                  ),
              onChanged: (value) {
                final naira = int.tryParse(value);
                if (naira != null) onOtherChanged(naira);
              },
            ),
          ],
        ],
        const SizedBox(height: AlongSpace.s16),
        TripPanel(
          padding: const EdgeInsets.fromLTRB(
            AlongSpace.s16,
            AlongSpace.s4,
            AlongSpace.s4,
            AlongSpace.s4,
          ),
          child: Row(
            children: [
              AlongIcon(AlongIcons.wallet, size: 20, color: p.ink),
              const SizedBox(width: AlongSpace.s12),
              Expanded(child: Text(methodLabel, style: AlongType.label(p))),
              TextButton(
                key: const Key('pay_driver_change_method'),
                style: TextButton.styleFrom(
                  foregroundColor: p.ink,
                  minimumSize: const Size(48, 48),
                  shape: AlongCraft.border(12),
                ),
                onPressed: onChangeMethod,
                child: Text(l10n.payDriverChangeMethod),
              ),
            ],
          ),
        ),
        const SizedBox(height: AlongSpace.s16),
        AlongButton(
          key: const Key('pay_driver_submit'),
          label: l10n.payDriverCta(money(amountNaira)),
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
    final p = AlongPalette.of(context);
    final transfer = result.transfer;
    final remaining = result.expiresAt.difference(DateTime.now()).inSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.payDriverPending(amountLabel), style: AlongType.title(p)),
        if (transfer != null && transfer.accountNumber.isNotEmpty) ...[
          const SizedBox(height: AlongSpace.s16),
          if (transfer.bankName.isNotEmpty)
            Text(
              transfer.bankName,
              style: AlongType.label(p),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AlongSpace.s8),
          Text(
            key: const Key('pay_driver_account_number'),
            transfer.accountNumber,
            style: AlongType.numeric(p),
            textAlign: TextAlign.center,
          ),
          if (transfer.accountName.isNotEmpty) ...[
            const SizedBox(height: AlongSpace.s4),
            Text(
              transfer.accountName,
              style: AlongType.caption(p),
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
          Text(
            result.ussdCode!,
            style: AlongType.numeric(p).copyWith(fontSize: 22),
          ),
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
          style: AlongType.label(p),
          textAlign: TextAlign.center,
        ),
        if (remaining > 0) ...[
          const SizedBox(height: AlongSpace.s8),
          Text(
            l10n.payDriverExpires(remaining),
            style: AlongType.caption(p),
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
    final p = AlongPalette.of(context);
    String money(int major) =>
        ProviderScope.containerOf(context)
            .read(appMoneyFormatterProvider)
            .formatMajor(major);
    final driverNaira = majorUnits(receipt.driverAmount);
    final feeNaira = majorUnits(receipt.commissionAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.payDriverSuccessTitle, style: AlongType.title(p)),
        const SizedBox(height: AlongSpace.s12),
        Text(
          key: const Key('pay_driver_success_itemised'),
          l10n.payDriverSuccessItemised(
            money(driverNaira),
            receipt.driverFirstName,
            money(feeNaira),
          ),
          style: AlongType.body(p),
        ),
        if (showHistoryOptIn) ...[
          const SizedBox(height: AlongSpace.s16),
          CheckboxListTile(
            key: const Key('pay_driver_history_opt_in'),
            activeColor: p.ink,
            checkColor: p.onInk,
            value: historyOptIn,
            onChanged: (v) => onHistoryChanged(v ?? false),
            title: Text(l10n.payDriverHistoryOptIn, style: AlongType.body(p)),
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

/// A squircle amount choice; ink when selected.
class _AmountChoice extends StatelessWidget {
  const _AmountChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? p.ink : p.recessed,
        shape: AlongCraft.border(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AlongHaptics.tick(context);
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AlongSpace.s16,
                vertical: AlongSpace.s12,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AlongType.label(p)
                    .copyWith(color: selected ? p.onInk : p.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
