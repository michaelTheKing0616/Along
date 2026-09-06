import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:along_design/along_design.dart' as design show formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/ledger/presentation/ledger_controller.dart';
import 'package:mobile_driver/features/payments/data/payments_providers.dart';
import 'package:mobile_driver/features/payments/presentation/payment_request_controller.dart';
import 'package:mobile_driver/routing/routes.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// D-18 Trip complete summary — fare, Along fee, balance, cash confirm, rate (doc 06).
class TripCompleteSheet extends ConsumerStatefulWidget {
  const TripCompleteSheet({
    super.key,
    required this.result,
    this.onFinished,
    this.paidDigitally = false,
    this.driverAmountReceived,
  });

  final CompleteTripResult result;
  final VoidCallback? onFinished;
  final bool paidDigitally;
  final Money? driverAmountReceived;

  static Future<void> show(
    BuildContext context, {
    required CompleteTripResult result,
    VoidCallback? onFinished,
    bool paidDigitally = false,
    Money? driverAmountReceived,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => TripCompleteSheet(
        result: result,
        onFinished: onFinished,
        paidDigitally: paidDigitally,
        driverAmountReceived: driverAmountReceived,
      ),
    );
  }

  @override
  ConsumerState<TripCompleteSheet> createState() => _TripCompleteSheetState();
}

class _TripCompleteSheetState extends ConsumerState<TripCompleteSheet> {
  _CompleteStep _step = _CompleteStep.summary;
  int _rating = 5;
  bool _busy = false;

  int get _fareNaira => widget.result.fare.minorUnits ~/ 100;

  Future<void> _confirmCash({required String outcome, Money? paidAmount}) async {
    setState(() => _busy = true);
    try {
      await ref.read(tripsRepositoryProvider).confirmFare(
            tripId: widget.result.trip.tripId,
            outcome: outcome,
            paidAmount: paidAmount,
          );
      if (mounted) setState(() => _step = _CompleteStep.rating);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitRating() async {
    setState(() => _busy = true);
    try {
      await ref.read(tripsRepositoryProvider).rateTrip(
            tripId: widget.result.trip.tripId,
            score: _rating,
            tags: const [],
          );
      await ref.read(driverLedgerControllerProvider.notifier).refresh();
      if (mounted) {
        widget.onFinished?.call();
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledger = ref.watch(driverLedgerControllerProvider);
    final commission = widget.result.commission;
    final digitalEnabled = ref.watch(digitalPaymentsEnabledProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AlongBottomSheet(
        size: AlongBottomSheetSize.full,
        title: l10n.tripCompleteTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == _CompleteStep.summary) ...[
              if (widget.paidDigitally) ...[
                Text(
                  l10n.tripCompleteDigitalLine(
                    formatMoney(widget.driverAmountReceived ?? widget.result.fare),
                  ),
                  style: AlongText.bodyStrong,
                ),
                Text(
                  l10n.tripCompleteDigitalFeeLine(formatMoney(commission)),
                  style: AlongText.caption.copyWith(color: AlongColors.ink500),
                ),
                const SizedBox(height: AlongSpace.s16),
                AlongButton(
                  key: const Key('trip_complete_digital_done'),
                  label: l10n.tripCompleteDone,
                  onPressed: _busy
                      ? null
                      : () => setState(() => _step = _CompleteStep.rating),
                ),
              ] else ...[
                Text(l10n.tripCompleteFareLine(formatMoney(widget.result.fare)),
                    style: AlongText.body),
                Text(
                  l10n.tripCompleteAlongFeeLine(formatMoney(commission)),
                  style: AlongText.caption.copyWith(color: AlongColors.ink500),
                ),
                const SizedBox(height: AlongSpace.s8),
                Text(
                  l10n.tripCompleteNewBalance(formatMoney(ledger.balance)),
                  style: AlongText.bodyStrong,
                ),
                const SizedBox(height: AlongSpace.s16),
                digitalEnabled.maybeWhen(
                  data: (enabled) {
                    if (!enabled) return const SizedBox.shrink();
                    return Column(
                      children: [
                        AlongButton(
                          key: const Key('trip_complete_request_payment'),
                          label: l10n.requestPayment,
                          variant: AlongButtonVariant.secondary,
                          onPressed: _busy
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  context.push(
                                    AppRoutes.paymentRequest,
                                    extra: PaymentRequestArgs(
                                      tripId: widget.result.trip.tripId,
                                      riderName:
                                          widget.result.trip.rider.displayName,
                                    ),
                                  );
                                },
                        ),
                        const SizedBox(height: AlongSpace.s8),
                      ],
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                Text(l10n.tripCompleteCashQuestion, style: AlongText.heading2),
                const SizedBox(height: AlongSpace.s12),
                AlongButton(
                  key: const Key('trip_complete_yes'),
                  label: l10n.tripCompleteYes,
                  visualState: _busy
                      ? AlongButtonVisualState.loading
                      : AlongButtonVisualState.normal,
                  onPressed: _busy ? null : () => _confirmCash(outcome: 'as_shown'),
                ),
                const SizedBox(height: AlongSpace.s8),
                AlongButton(
                  key: const Key('trip_complete_different'),
                  label: l10n.tripCompleteDifferent,
                  variant: AlongButtonVariant.secondary,
                  onPressed: _busy
                      ? null
                      : () => setState(() => _step = _CompleteStep.different),
                ),
              ],
            ] else if (_step == _CompleteStep.different) ...[
              Text(l10n.tripCompleteDifferentPrompt, style: AlongText.heading2),
              const SizedBox(height: AlongSpace.s16),
              Wrap(
                spacing: AlongSpace.s8,
                runSpacing: AlongSpace.s8,
                children: [
                  for (final amount in [
                    _fareNaira - 50,
                    _fareNaira,
                    _fareNaira + 50,
                  ])
                    _AmountChip(
                      label: design.formatMoney(amount),
                      onTap: _busy
                          ? null
                          : () => _confirmCash(
                                outcome: 'different',
                                paidAmount: Money.fromMinorUnits(
                                  amount * 100,
                                  currency: widget.result.fare.currency,
                                ),
                              ),
                    ),
                ],
              ),
            ] else ...[
              Text(l10n.tripCompleteRateTitle, style: AlongText.heading2),
              const SizedBox(height: AlongSpace.s12),
              _StarRow(
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: AlongSpace.s16),
              AlongButton(
                key: const Key('trip_complete_done'),
                label: l10n.tripCompleteDone,
                visualState: _busy
                    ? AlongButtonVisualState.loading
                    : AlongButtonVisualState.normal,
                onPressed: _busy ? null : _submitRating,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _CompleteStep { summary, different, rating }

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AlongColors.brandYellow,
      borderRadius: BorderRadius.circular(AlongRadius.sm.x),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AlongRadius.sm.x),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AlongSpace.s12,
            vertical: AlongSpace.s8,
          ),
          child: Text(
            label,
            style: AlongText.label.copyWith(color: AlongColors.brandYellowOn),
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final star = index + 1;
        return IconButton(
          key: Key('trip_complete_star_$star'),
          iconSize: 40,
          onPressed: () => onChanged(star),
          icon: Icon(
            star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AlongColors.brandYellow,
          ),
        );
      }),
    );
  }
}
