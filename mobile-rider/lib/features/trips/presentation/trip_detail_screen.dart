import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_rider/l10n/l10n_format.dart';
import 'package:mobile_rider/features/tenant/tenant_providers.dart';
import 'package:mobile_rider/features/safety/presentation/trip_thread_screen.dart';
import 'package:mobile_rider/features/trips/presentation/trips_history_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-22 Trip detail — itemised fare + text receipt share.
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final detail = ref.watch(tripDetailProvider(tripId));
    final entry = detail.valueOrNull;
    if (entry == null) {
      return TripPage(
        title: l10n.tripDetailTitle,
        children: [
          if (detail.isLoading)
            const AlongSkeleton(variant: SkeletonVariant.line)
          else
            TripNotice(icon: AlongIcons.info, text: l10n.tripDetailMissing),
        ],
      );
    }
    final receipt = entry.receipt;
    final locale = intlLocaleOf(context);
    return TripPage(
      title: receipt == null
          ? l10n.tripDetailTitle
          : formatAppMoney(ref, receipt.total),
      subtitle: l10n.tripsRowDetail(
        entry.routeLabel,
        DateFormat.yMMMd(locale).add_Hm().format(cityTime(entry.completedAt)),
      ),
      children: [
        if (entry.driverName != null) ...[
          TripPanel(
            child: Row(
              children: [
                TripDriverAvatar(name: entry.driverName!),
                const SizedBox(width: AlongSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.driverName!, style: AlongType.label(p)),
                      if ((entry.plateNumber ?? '').isNotEmpty)
                        Text(entry.plateNumber!, style: AlongType.caption(p)),
                    ],
                  ),
                ),
                TripModeTile(modeCode: entry.modeCode, size: 36),
              ],
            ),
          ),
          const SizedBox(height: AlongSpace.s16),
        ],
        if (receipt != null) ...[
          TripPanel(
            key: const Key('trip_detail_fare'),
            child: TripFareBreakdown(
              receipt: receipt,
              payable: receipt.total,
              money: (m) => formatAppMoney(ref, m),
            ),
          ),
          const SizedBox(height: AlongSpace.s16),
        ],
        Column(
          children: [
            _DetailAction(
              key: const Key('trip_detail_share_receipt'),
              icon: AlongIcons.receipt,
              label: l10n.tripDetailShareReceipt,
              onPressed: () {
                final text = receipt == null
                    ? entry.routeLabel
                    : tripReceiptShareText(
                        l10n,
                        receipt: receipt,
                        routeLabel: entry.routeLabel,
                        driverName: entry.driverName ?? l10n.tripDriverFallback,
                        plate: entry.plateNumber ?? '',
                        money: (m) => formatAppMoney(ref, m),
                      );
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.tripDetailReceiptCopied)),
                );
              },
            ),
            const SizedBox(height: AlongSpace.s8),
            _DetailAction(
              key: const Key('trip_detail_messages'),
              icon: AlongIcons.chat,
              label: l10n.tripMessagesTitle,
              onPressed: () => context.push(
                AppRoutes.tripMessages,
                extra: TripThreadArgs(
                  tripId: tripId,
                  endedAt: entry.completedAt,
                ),
              ),
            ),
            const SizedBox(height: AlongSpace.s8),
            _DetailAction(
              key: const Key('trip_detail_report'),
              icon: AlongIcons.shield,
              label: l10n.activeTripReport,
              onPressed: () =>
                  context.push(AppRoutes.reportIncident, extra: tripId),
            ),
          ],
        ),
      ],
    );
  }
}

/// A full-width squircle action row: icon, label, caret.
class _DetailAction extends StatelessWidget {
  const _DetailAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Material(
      color: p.recessed,
      shape: AlongCraft.border(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AlongHaptics.tick(context);
          onPressed();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AlongSpace.s16,
              vertical: AlongSpace.s12,
            ),
            child: Row(
              children: [
                AlongIcon(icon, size: 20, color: p.ink),
                const SizedBox(width: AlongSpace.s12),
                Expanded(child: Text(label, style: AlongType.label(p))),
                AlongIcon(AlongIcons.caretRight, size: 16, color: p.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
