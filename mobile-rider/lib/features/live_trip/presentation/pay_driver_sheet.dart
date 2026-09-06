import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' as design show FareTier, formatMoney;
import 'package:along_design/along_design.dart' hide FareTier, formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/trip_ui_helpers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-27 Pay driver sheet — flag-gated, amount locked when trip attached.
class PayDriverSheet extends ConsumerWidget {
  const PayDriverSheet({
    super.key,
    required this.trip,
    this.receipt,
    this.suggestedAmountNaira,
  });

  final TripSummary? trip;
  final TripReceipt? receipt;
  final int? suggestedAmountNaira;

  static Future<void> show(
    BuildContext context, {
    TripSummary? trip,
    TripReceipt? receipt,
    int? suggestedAmountNaira,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PayDriverSheet(
        trip: trip,
        receipt: receipt,
        suggestedAmountNaira: suggestedAmountNaira,
      ),
    );
  }

  bool get _amountLocked => trip != null;

  int get _amountNaira {
    if (trip != null) return trip!.totalFare.minorUnits ~/ 100;
    return suggestedAmountNaira ?? 500;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final attachedTrip = trip;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AlongBottomSheet(
        size: AlongBottomSheetSize.full,
        title: l10n.payDriverTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (attachedTrip != null) ...[
              Text(
                '${attachedTrip.driver.displayName} · ${attachedTrip.vehicle.plateNumber}',
                style: AlongText.bodyStrong,
              ),
              const SizedBox(height: AlongSpace.s8),
              ModeChip(mode: designMode(attachedTrip.modeCode)),
              const SizedBox(height: AlongSpace.s16),
            ],
            FareHero(
              key: const Key('pay_driver_amount'),
              amountNaira: _amountNaira,
              tier: attachedTrip != null
                  ? designFareTier(
                      attachedTrip.fare.tier,
                      unconfirmed: attachedTrip.fare.unconfirmed,
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
                children: [400, 500, 600]
                    .map(
                      (amount) => ActionChip(
                        label: Text(design.formatMoney(amount)),
                        onPressed: () {},
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: AlongSpace.s16),
            Text(l10n.payDriverMethodSaved, style: AlongText.body),
            const SizedBox(height: AlongSpace.s16),
            AlongButton(
              key: const Key('pay_driver_submit'),
              label: l10n.payDriverCta(design.formatMoney(_amountNaira)),
              variant: AlongButtonVariant.yellow,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.payDriverPending)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
