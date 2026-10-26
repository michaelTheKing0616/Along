import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/placements/presentation/placement_providers.dart';
import 'package:mobile_rider/features/placements/presentation/sponsored_placement_slot.dart';
import 'package:mobile_rider/features/tenant/tenant_providers.dart';
import 'package:mobile_rider/features/trips/presentation/trips_history_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-22 Trips history — grouped by day.
class TripsHistoryScreen extends ConsumerWidget {
  const TripsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final history = ref.watch(tripsHistoryProvider);
    final placementsAsync = ref.watch(tripsHistoryPlacementProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return TripPage(
      title: l10n.navTrips,
      children: history.when(
        loading: () => const [
          AlongSkeleton(variant: SkeletonVariant.line),
          SizedBox(height: AlongSpace.s12),
          AlongSkeleton(variant: SkeletonVariant.line),
        ],
        error: (error, _) => [
          TripNotice(
            icon: AlongIcons.info,
            text: l10n.tripsLoadFailed,
            warn: true,
          ),
        ],
        data: (entries) {
          if (entries.isEmpty) {
            return [
              const SizedBox(height: AlongSpace.s48),
              Center(
                child: AlongIcon(AlongIcons.history, size: 40, color: p.muted),
              ),
              const SizedBox(height: AlongSpace.s12),
              Text(
                l10n.tripsEmpty,
                textAlign: TextAlign.center,
                style: AlongType.bodyMuted(p),
              ),
            ];
          }
          final grouped = _groupByDay(entries, locale);
          return [
            placementsAsync.maybeWhen(
              data: (placements) => Padding(
                padding: const EdgeInsets.only(bottom: AlongSpace.s16),
                child: SponsoredPlacementSlot(placements: placements),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            for (final group in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: AlongSpace.s8,
                  bottom: AlongSpace.s8,
                ),
                child: Text(group.key, style: AlongType.label(p)),
              ),
              for (final entry in group.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: AlongSpace.s8),
                  child: _HistoryRow(
                    key: Key('trip_history_${entry.tripId}'),
                    entry: entry,
                    detail: l10n.tripsRowDetail(
                      DateFormat.Hm(locale).format(cityTime(entry.completedAt)),
                      formatAppMoney(ref, entry.totalFare),
                    ),
                    onTap: () =>
                        context.push(AppRoutes.tripDetail, extra: entry.tripId),
                  ),
                ),
            ],
          ];
        },
      ),
    );
  }

  Map<String, List<TripHistoryEntry>> _groupByDay(
    List<TripHistoryEntry> entries,
    String locale,
  ) {
    final map = <String, List<TripHistoryEntry>>{};
    for (final entry in entries) {
      final key = DateFormat.yMMMMd(locale).format(cityTime(entry.completedAt));
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map;
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    super.key,
    required this.entry,
    required this.detail,
    required this.onTap,
  });

  final TripHistoryEntry entry;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final cancelled = entry.status == TripStatus.cancelled;
    return Material(
      color: p.recessed,
      shape: AlongCraft.border(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AlongHaptics.tick(context);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s12),
          child: Row(
            children: [
              TripModeTile(modeCode: entry.modeCode, size: 40),
              const SizedBox(width: AlongSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.routeLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.label(p),
                    ),
                    Text(detail, style: AlongType.caption(p)),
                  ],
                ),
              ),
              if (cancelled) ...[
                const SizedBox(width: AlongSpace.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: AlongCraft.compactFill(
                    p.danger.withValues(alpha: 0.12),
                    24,
                    corner: 8,
                  ),
                  child: Text(
                    l10n.tripStatusCancelled,
                    style: AlongType.caption(p).copyWith(color: p.danger),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
