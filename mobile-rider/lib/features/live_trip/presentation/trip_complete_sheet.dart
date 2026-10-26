import 'package:along_core/along_core.dart'
    show FareTier, Money, TripReceipt, TripSummary;
import 'package:along_design/along_design.dart' hide FareTier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/payments_config.dart';
import 'package:mobile_rider/features/live_trip/domain/trip_ui_helpers.dart';
import 'package:mobile_rider/features/live_trip/presentation/pay_driver_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/tenant/tenant_providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-17 Trip complete — fare confirm only. Rating lives on the receipt
/// ([TripReceiptPage]) so the rider is asked once.
class TripCompleteSheet extends ConsumerStatefulWidget {
  const TripCompleteSheet({
    super.key,
    required this.trip,
    this.receipt,
    this.onFinished,
  });

  final TripSummary trip;
  final TripReceipt? receipt;
  final VoidCallback? onFinished;

  static Future<void> show(
    BuildContext context, {
    required TripSummary trip,
    TripReceipt? receipt,
    VoidCallback? onFinished,
  }) {
    if (trip.paymentMethod == 'digital') {
      // Already paid in-app: nothing to confirm, go straight to the receipt.
      onFinished?.call();
      return Future<void>.value();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripCompleteSheet(
        trip: trip,
        receipt: receipt,
        onFinished: onFinished,
      ),
    );
  }

  @override
  ConsumerState<TripCompleteSheet> createState() => _TripCompleteSheetState();
}

class _TripCompleteSheetState extends ConsumerState<TripCompleteSheet> {
  _CompleteStep _step = _CompleteStep.fare;
  bool _busy = false;

  /// What the rider owes: the server receipt total when known (fare plus
  /// surcharges), otherwise the trip's quoted total.
  Money get _payable => widget.receipt?.total ?? widget.trip.totalFare;

  int get _fareNaira => majorUnits(_payable);

  bool get _isTier3 =>
      widget.trip.fare.tier == FareTier.unconfirmed ||
      widget.trip.fare.unconfirmed;

  Future<void> _confirmAsShown() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(tripsRepositoryProvider)
          .confirmFare(tripId: widget.trip.tripId, outcome: 'as_shown');
      if (mounted) _finish();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDifferent(int amountNaira) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(tripsRepositoryProvider)
          .confirmFare(
            tripId: widget.trip.tripId,
            outcome: 'different',
            paidAmount: Money.fromMinorUnits(
              amountNaira * 100,
              currency: widget.trip.totalFare.currency,
            ),
          );
      if (mounted) _finish();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish() {
    widget.onFinished?.call();
    Navigator.of(context).pop();
  }

  bool get _alreadyPaidDigitally => widget.trip.paymentMethod == 'digital';

  Future<void> _payDigitally() async {
    final paid = await PayDriverSheet.show(
      context,
      trip: widget.trip,
      receipt: widget.receipt,
      autoInitiate: true,
    );
    if (paid && mounted) {
      await _confirmAsShown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final digitalEnabled = ref
        .watch(digitalPaymentsEnabledProvider)
        .maybeWhen(data: (value) => value, orElse: () => false);
    final fare = formatAppMoney(ref, _payable);
    final surcharge = widget.receipt?.surcharge;
    final itemised = surcharge != null && surcharge.minorUnits > 0;
    final offerPay = digitalEnabled && !_alreadyPaidDigitally && !_isTier3;
    final loading = _busy
        ? AlongButtonVisualState.loading
        : AlongButtonVisualState.normal;
    void toDifferent() {
      AlongHaptics.tick(context);
      setState(() => _step = _CompleteStep.different);
    }

    final List<Widget> body;
    if (_step == _CompleteStep.different || _isTier3) {
      body = [
        Text(
          _isTier3
              ? l10n.tripCompleteTier3Question
              : l10n.tripCompleteDifferentPrompt,
          style: AlongType.title(p),
        ),
        const SizedBox(height: AlongSpace.s16),
        _AmountGrid(
          amounts: fareConfirmChipAmounts(_fareNaira),
          label: (amount) => formatAppMoneyMajor(ref, amount),
          keyed: true,
          onPick: _busy ? null : _confirmDifferent,
        ),
      ];
    } else {
      body = [
        // One statement of the fare, then the question about it. The amount
        // is not repeated in the question.
        DecoratedBox(
          decoration: AlongCraft.compactFill(p.recessed, 96, corner: 20),
          child: Padding(
            padding: const EdgeInsets.all(AlongSpace.s16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemised
                            ? l10n.receiptTotal
                            : l10n.tripCompleteFareLabel,
                        style: AlongType.caption(p),
                      ),
                      Text(
                        fare,
                        key: const Key('trip_complete_fare'),
                        style: AlongType.display(p),
                      ),
                      if (itemised)
                        Text(
                          '${l10n.receiptFare} '
                          '${formatAppMoney(ref, widget.receipt!.fare)} · '
                          '${l10n.receiptLoadSurcharge} '
                          '${formatAppMoney(ref, surcharge)}',
                          key: const Key('trip_complete_breakdown'),
                          style: AlongType.caption(p),
                        ),
                    ],
                  ),
                ),
                TripDriverAvatar(name: widget.trip.driver.displayName),
              ],
            ),
          ),
        ),
        const SizedBox(height: AlongSpace.s16),
        Text(
          offerPay
              ? l10n.tripCompletePayHint(widget.trip.driver.displayName)
              : l10n.tripCompleteSettleQuestion,
          style: AlongType.label(p),
        ),
        const SizedBox(height: AlongSpace.s20),
        if (offerPay) ...[
          AlongButton(
            key: const Key('trip_complete_pay'),
            label: l10n.payDriverCta(fare),
            variant: AlongButtonVariant.yellow,
            visualState: loading,
            onPressed: _busy ? null : _payDigitally,
          ),
          const SizedBox(height: AlongSpace.s8),
          AlongButton(
            key: const Key('trip_complete_paid_cash'),
            label: l10n.tripCompletePaidCash,
            variant: AlongButtonVariant.secondary,
            onPressed: _busy ? null : _confirmAsShown,
          ),
        ] else
          AlongButton(
            key: const Key('trip_complete_yes'),
            label: l10n.tripCompleteYes,
            visualState: loading,
            onPressed: _busy ? null : _confirmAsShown,
          ),
        const SizedBox(height: AlongSpace.s4),
        AlongButton(
          key: const Key('trip_complete_different'),
          label: l10n.tripCompleteDifferent,
          variant: AlongButtonVariant.tertiary,
          onPressed: _busy ? null : toDifferent,
        ),
      ];
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: AlongRadius.dialog),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AlongSpace.s20,
              AlongSpace.s12,
              AlongSpace.s20,
              AlongSpace.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: AlongCraft.compactFill(p.line, 4, corner: 2),
                  ),
                ),
                const SizedBox(height: AlongSpace.s16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: AlongCraft.compactFill(
                        p.success.withValues(alpha: 0.14),
                        40,
                      ),
                      child: AlongIcon(
                        AlongIcons.check,
                        size: 20,
                        color: p.success,
                      ),
                    ),
                    const SizedBox(width: AlongSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.tripCompleteTitle,
                            style: AlongType.title(p),
                          ),
                          Text(
                            l10n.tripCompleteRoute(
                              widget.trip.board.name,
                              widget.trip.alight.name,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AlongType.caption(p),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AlongSpace.s20),
                AnimatedSwitcher(
                  duration: AlongMoves.arrive.of(context),
                  switchInCurve: AlongMoves.arrive.curve,
                  layoutBuilder: (current, previous) =>
                      current ?? const SizedBox.shrink(),
                  child: Column(
                    key: ValueKey(_step),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CompleteStep { fare, different }

/// Likely amounts as a three-up grid of squircle tiles.
class _AmountGrid extends StatelessWidget {
  const _AmountGrid({
    required this.amounts,
    required this.label,
    required this.keyed,
    required this.onPick,
  });

  final List<int> amounts;
  final String Function(int amount) label;
  final bool keyed;
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        const gap = AlongSpace.s8;
        final width = (box.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final amount in amounts)
              SizedBox(
                width: width,
                child: Material(
                  key: keyed ? Key('trip_complete_chip_$amount') : null,
                  color: Colors.transparent,
                  shape: AlongCraft.border(16),
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    decoration: AlongCraft.compactFill(p.recessed, 52),
                    child: InkWell(
                      onTap: onPick == null
                          ? null
                          : () {
                              AlongHaptics.tick(context);
                              onPick!(amount);
                            },
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: Text(label(amount), style: AlongType.label(p)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
