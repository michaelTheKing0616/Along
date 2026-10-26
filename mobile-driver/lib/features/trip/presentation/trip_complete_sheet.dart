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
import 'package:mobile_driver/features/safety/domain/rating_config.dart';
import 'package:mobile_driver/routing/routes.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';

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
  final Set<String> _tags = {};
  bool _busy = false;

  int get _fareNaira => widget.result.fare.minorUnits ~/ 100;

  Future<void> _confirmCash({
    required String outcome,
    Money? paidAmount,
  }) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(tripsRepositoryProvider)
          .confirmFare(
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
      await ref
          .read(tripsRepositoryProvider)
          .rateTrip(
            tripId: widget.result.trip.tripId,
            score: _rating,
            tags: _tags.toList(growable: false),
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
    final p = AlongPalette.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AlongBottomSheet(
        size: AlongBottomSheetSize.full,
        title: l10n.tripCompleteTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == _CompleteStep.summary) ...[
              Text(
                widget.paidDigitally
                    ? l10n.tripCompleteDigitalLine(
                        formatMoney(
                          widget.driverAmountReceived ?? widget.result.fare,
                        ),
                      )
                    : l10n.tripCompleteCashHero,
                style: AlongType.caption(p),
              ),
              const SizedBox(height: AlongSpace.s4),
              Text(
                formatMoney(
                  widget.paidDigitally
                      ? (widget.driverAmountReceived ?? widget.result.fare)
                      : widget.result.fare,
                ),
                key: const Key('trip_complete_hero'),
                style: AlongType.display(
                  p,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: AlongSpace.s16),
              DrivePanel(
                child: Column(
                  children: [
                    _Line(
                      label: l10n.tripCompleteRowFare,
                      value: formatMoney(widget.result.fare),
                    ),
                    const SizedBox(height: AlongSpace.s8),
                    _Line(
                      label: widget.paidDigitally
                          ? l10n.tripCompleteDigitalFeeLine(
                              formatMoney(commission),
                            )
                          : l10n.tripCompleteRowFee,
                      value: '−${formatMoney(commission)}',
                    ),
                    if (!widget.paidDigitally) ...[
                      const SizedBox(height: AlongSpace.s8),
                      Divider(height: 1, color: p.line),
                      const SizedBox(height: AlongSpace.s8),
                      _Line(
                        label: l10n.tripCompleteRowBalance,
                        value: formatMoney(ledger.balance),
                        strong: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AlongSpace.s16),
              if (widget.paidDigitally)
                AlongButton(
                  key: const Key('trip_complete_digital_done'),
                  label: l10n.tripCompleteDone,
                  onPressed: _busy
                      ? null
                      : () => setState(() => _step = _CompleteStep.rating),
                )
              else ...[
                Text(l10n.tripCompleteCashQuestion, style: AlongType.title(p)),
                const SizedBox(height: AlongSpace.s12),
                AlongButton(
                  key: const Key('trip_complete_yes'),
                  label: l10n.tripCompleteYesAmount(
                    formatMoney(widget.result.fare),
                  ),
                  visualState: _busy
                      ? AlongButtonVisualState.loading
                      : AlongButtonVisualState.normal,
                  onPressed: _busy
                      ? null
                      : () {
                          AlongHaptics.confirm(context);
                          _confirmCash(outcome: 'as_shown');
                        },
                ),
                const SizedBox(height: AlongSpace.s8),
                Row(
                  children: [
                    Expanded(
                      child: AlongButton(
                        key: const Key('trip_complete_different'),
                        label: l10n.tripCompleteDifferent,
                        variant: AlongButtonVariant.secondary,
                        size: AlongButtonSize.secondary,
                        onPressed: _busy
                            ? null
                            : () => setState(
                                () => _step = _CompleteStep.different,
                              ),
                      ),
                    ),
                    ...digitalEnabled.maybeWhen(
                      data: (enabled) => enabled
                          ? [
                              const SizedBox(width: AlongSpace.s8),
                              Expanded(
                                child: AlongButton(
                                  key: const Key(
                                    'trip_complete_request_payment',
                                  ),
                                  label: l10n.requestPayment,
                                  variant: AlongButtonVariant.secondary,
                                  size: AlongButtonSize.secondary,
                                  onPressed: _busy
                                      ? null
                                      : () {
                                          Navigator.of(context).pop();
                                          context.push(
                                            AppRoutes.paymentRequest,
                                            extra: PaymentRequestArgs(
                                              tripId: widget.result.trip.tripId,
                                              riderName: widget
                                                  .result
                                                  .trip
                                                  .rider
                                                  .displayName,
                                            ),
                                          );
                                        },
                                ),
                              ),
                            ]
                          : const <Widget>[],
                      orElse: () => const <Widget>[],
                    ),
                  ],
                ),
              ],
            ] else if (_step == _CompleteStep.different) ...[
              Text(l10n.tripCompleteDifferentPrompt, style: AlongType.title(p)),
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
              Text(l10n.tripCompleteRateTitle, style: AlongType.title(p)),
              const SizedBox(height: AlongSpace.s12),
              _StarRow(
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: AlongSpace.s12),
              ref
                  .watch(ratingTagsProvider)
                  .when(
                    data: (tags) => Wrap(
                      spacing: AlongSpace.s8,
                      runSpacing: AlongSpace.s8,
                      children: tags
                          .map(
                            (tag) => _TagChip(
                              label: tag.replaceAll('_', ' '),
                              selected: _tags.contains(tag),
                              onTap: () => setState(() {
                                if (_tags.contains(tag)) {
                                  _tags.remove(tag);
                                } else {
                                  _tags.add(tag);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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
      shape: AlongCraft.border(AlongRadius.control.x),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: AlongCraft.border(AlongRadius.control.x),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AlongSpace.s12,
            vertical: AlongSpace.s12,
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

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AlongColors.brandYellow
          : AlongPalette.of(context).recessed,
      shape: AlongCraft.border(AlongRadius.control.x),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: AlongCraft.border(AlongRadius.control.x),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AlongSpace.s12,
            vertical: AlongSpace.s12,
          ),
          child: Text(
            label,
            style: AlongText.label.copyWith(
              color: selected
                  ? AlongColors.brandYellowOn
                  : AlongPalette.of(context).ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final style = strong ? AlongType.label(p) : AlongType.body(p);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: AlongSpace.s12),
        Text(
          value,
          style: style.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
