import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/live_trip/domain/trip_ui_helpers.dart';
import 'package:mobile_rider/features/safety/presentation/trip_thread_screen.dart';
import 'package:mobile_rider/features/trips/presentation/trips_history_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-22 Trip detail — itemised fare + text receipt share.
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(tripDetailProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripDetailTitle)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (entry) {
          if (entry == null) {
            return Center(child: Text(l10n.tripDetailMissing));
          }
          final receipt = entry.receipt;
          return ListView(
            padding: const EdgeInsets.all(AlongSpace.s16),
            children: [
              Text(entry.routeLabel, style: AlongText.heading2),
              const SizedBox(height: AlongSpace.s8),
              ModeChip(mode: designMode(entry.modeCode)),
              const SizedBox(height: AlongSpace.s16),
              if (entry.driverName != null)
                Text(
                  '${entry.driverName} · ${entry.plateNumber ?? ''}',
                  style: AlongText.body,
                ),
              const SizedBox(height: AlongSpace.s16),
              if (receipt != null)
                FareHero(
                  key: const Key('trip_detail_fare'),
                  amountNaira: receipt.total.minorUnits ~/ 100,
                  lineItems: receipt.lines
                      .map(
                        (line) => FareHeroLineItem(
                          label: line.label,
                          amountNaira: line.amount.minorUnits ~/ 100,
                        ),
                      )
                      .toList(),
                  expanded: true,
                ),
              const SizedBox(height: AlongSpace.s16),
              AlongButton(
                key: const Key('trip_detail_share_receipt'),
                label: l10n.tripDetailShareReceipt,
                variant: AlongButtonVariant.secondary,
                onPressed: () {
                  final text =
                      receipt?.toShareText(
                        routeLabel: entry.routeLabel,
                        driverName: entry.driverName ?? 'Driver',
                        plate: entry.plateNumber ?? '',
                      ) ??
                      entry.routeLabel;
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.tripDetailReceiptCopied)),
                  );
                },
              ),
              const SizedBox(height: AlongSpace.s8),
              AlongButton(
                key: const Key('trip_detail_messages'),
                label: l10n.tripMessagesTitle,
                variant: AlongButtonVariant.secondary,
                onPressed: () => context.push(
                  AppRoutes.tripMessages,
                  extra: TripThreadArgs(
                    tripId: tripId,
                    endedAt: entry.completedAt,
                  ),
                ),
              ),
              const SizedBox(height: AlongSpace.s8),
              AlongButton(
                key: const Key('trip_detail_report'),
                label: l10n.activeTripReport,
                variant: AlongButtonVariant.tertiary,
                onPressed: () =>
                    context.push(AppRoutes.reportIncident, extra: tripId),
              ),
            ],
          );
        },
      ),
    );
  }
}
