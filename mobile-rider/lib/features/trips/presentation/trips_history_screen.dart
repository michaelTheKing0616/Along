import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_rider/l10n/l10n_format.dart';
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
    final locale = intlLocaleOf(context);

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
                style: AlongType.title(p),
              ),
              const SizedBox(height: AlongSpace.s4),
              Text(
                l10n.tripsEmptyHint,
                textAlign: TextAlign.center,
                style: AlongType.bodyMuted(p),
              ),
              const SizedBox(height: AlongSpace.s20),
              Center(
                child: AlongButton(
                  key: const Key('trips_empty_cta'),
                  label: l10n.tripsEmptyCta,
                  fullWidth: false,
                  onPressed: () => context.push(AppRoutes.search),
                ),
              ),
            ];
          }
          final grouped = _groupByDay(entries, locale);
          final spent = Money.fromMinorUnits(
            entries.fold<int>(0, (sum, e) => sum + e.totalFare.minorUnits),
            currency: entries.first.totalFare.currency,
          );
          return [
            TripPanel(
              key: const Key('trips_summary'),
              child: Row(
                children: [
                  TripModeTile(modeCode: entries.first.modeCode, size: 40),
                  const SizedBox(width: AlongSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tripsSummaryTitle,
                          style: AlongType.caption(p),
                        ),
                        Text(
                          l10n.tripsSummaryCount(entries.length),
                          style: AlongType.title(p),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.tripsSummarySpent(formatAppMoney(ref, spent)),
                    style: AlongType.label(p),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AlongSpace.s12),
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
                    time: DateFormat.Hm(locale)
                        .format(cityTime(entry.completedAt)),
                    fare: formatAppMoney(ref, entry.totalFare),
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
      final key = DateFormat.MMMMEEEEd(locale)
          .format(cityTime(entry.completedAt));
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map;
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    super.key,
    required this.entry,
    required this.time,
    required this.fare,
    required this.onTap,
  });

  final TripHistoryEntry entry;
  final String time;
  final String fare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final who = [
      if ((entry.driverName ?? '').isNotEmpty) entry.driverName!,
      entry.modeLabel,
    ].join(' · ');
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 2),
                    Text(
                      l10n.tripsRowDetail(time, l10n.tripStatusCompleted),
                      style: AlongType.caption(p),
                    ),
                    Text(
                      who,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.caption(p),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AlongSpace.s8),
              Text(fare, style: AlongType.label(p)),
            ],
          ),
        ),
      ),
    );
  }
}
