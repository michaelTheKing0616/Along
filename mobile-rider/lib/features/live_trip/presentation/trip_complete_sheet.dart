import 'package:along_core/along_core.dart' show FareTier, Money, TripReceipt, TripSummary;
import 'package:along_design/along_design.dart' hide FareTier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/payments_config.dart';
import 'package:mobile_rider/features/live_trip/domain/trip_ui_helpers.dart';
import 'package:mobile_rider/features/live_trip/presentation/pay_driver_sheet.dart';
import 'package:mobile_rider/features/tenant/tenant_providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-17 Trip complete — fare confirm + rating (2-tap default path).
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
  late _CompleteStep _step = widget.trip.paymentMethod == 'digital'
      ? _CompleteStep.rating
      : _CompleteStep.fare;
  int _rating = 5;
  final Set<String> _tags = {};
  bool _busy = false;

  int get _fareNaira => widget.trip.totalFare.minorUnits ~/ 100;

  bool get _isTier3 =>
      widget.trip.fare.tier == FareTier.unconfirmed ||
      widget.trip.fare.unconfirmed;

  Future<void> _confirmAsShown() async {
    setState(() => _busy = true);
    try {
      await ref.read(tripsRepositoryProvider).confirmFare(
            tripId: widget.trip.tripId,
            outcome: 'as_shown',
          );
      if (mounted) setState(() => _step = _CompleteStep.rating);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDifferent(int amountNaira) async {
    setState(() => _busy = true);
    try {
      await ref.read(tripsRepositoryProvider).confirmFare(
            tripId: widget.trip.tripId,
            outcome: 'different',
            paidAmount: Money.fromMinorUnits(
              amountNaira * 100,
              currency: widget.trip.totalFare.currency,
            ),
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
            tripId: widget.trip.tripId,
            score: _rating,
            tags: _tags.toList(growable: false),
          );
      if (mounted) {
        widget.onFinished?.call();
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    final digitalEnabled = ref.watch(digitalPaymentsEnabledProvider).maybeWhen(
          data: (value) => value,
          orElse: () => false,
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AlongBottomSheet(
        size: AlongBottomSheetSize.full,
        title: l10n.tripCompleteTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == _CompleteStep.fare) ...[
              if (digitalEnabled && !_alreadyPaidDigitally && !_isTier3) ...[
                Text(
                  l10n.tripCompletePayQuestion(
                    formatAppMoney(ref, widget.trip.totalFare),
                    widget.trip.driver.displayName,
                  ),
                  style: AlongText.heading2,
                ),
                const SizedBox(height: AlongSpace.s16),
                AlongButton(
                  key: const Key('trip_complete_pay'),
                  label: l10n.payDriverCta(formatAppMoney(ref, widget.trip.totalFare)),
                  variant: AlongButtonVariant.yellow,
                  visualState: _busy
                      ? AlongButtonVisualState.loading
                      : AlongButtonVisualState.normal,
                  onPressed: _busy ? null : _payDigitally,
                ),
                const SizedBox(height: AlongSpace.s8),
                AlongButton(
                  key: const Key('trip_complete_paid_cash'),
                  label: l10n.tripCompletePaidCash,
                  variant: AlongButtonVariant.tertiary,
                  onPressed: _busy ? null : _confirmAsShown,
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
              ] else ...[
                Text(
                  _isTier3
                      ? l10n.tripCompleteTier3Question
                      : l10n.tripCompletePaidQuestion(
                          formatAppMoney(ref, widget.trip.totalFare),
                        ),
                  style: AlongText.heading2,
                ),
                const SizedBox(height: AlongSpace.s16),
                if (!_isTier3)
                  AlongButton(
                    key: const Key('trip_complete_yes'),
                    label: l10n.tripCompleteYes,
                    visualState: _busy
                        ? AlongButtonVisualState.loading
                        : AlongButtonVisualState.normal,
                    onPressed: _busy ? null : _confirmAsShown,
                  )
                else
                  Wrap(
                    spacing: AlongSpace.s8,
                    runSpacing: AlongSpace.s8,
                    children: fareConfirmChipAmounts(_fareNaira)
                        .map(
                          (amount) => _AmountChip(
                            key: Key('trip_complete_chip_$amount'),
                            label: formatAppMoneyMajor(ref, amount),
                            onTap: _busy ? null : () => _confirmDifferent(amount),
                          ),
                        )
                        .toList(),
                  ),
                if (!_isTier3) ...[
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
              ],
            ] else if (_step == _CompleteStep.different) ...[
              Text(l10n.tripCompleteDifferentPrompt, style: AlongText.heading2),
              const SizedBox(height: AlongSpace.s16),
              Wrap(
                spacing: AlongSpace.s8,
                runSpacing: AlongSpace.s8,
                children: fareConfirmChipAmounts(_fareNaira)
                    .map(
                      (amount) => _AmountChip(
                        label: formatAppMoneyMajor(ref, amount),
                        onTap: _busy ? null : () => _confirmDifferent(amount),
                      ),
                    )
                    .toList(),
              ),
            ] else ...[
              Text(l10n.tripCompleteRateTitle, style: AlongText.heading2),
              const SizedBox(height: AlongSpace.s12),
              _StarRow(
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: AlongSpace.s12),
              ref.watch(ratingTagsProvider).when(
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
                label: l10n.loadFlagDone,
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

enum _CompleteStep { fare, different, rating }

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    super.key,
    required this.label,
    required this.onTap,
  });

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
      color: selected ? AlongColors.brandYellow : AlongColors.surface100,
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
            style: AlongText.label.copyWith(
              color: selected ? AlongColors.brandYellowOn : AlongColors.ink700,
            ),
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
