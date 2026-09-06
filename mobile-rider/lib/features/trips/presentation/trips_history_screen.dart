import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:along_design/along_design.dart' as design show formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_rider/features/live_trip/domain/trip_ui_helpers.dart';
import 'package:mobile_rider/features/trips/presentation/trips_history_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-22 Trips history — grouped by day.
class TripsHistoryScreen extends ConsumerWidget {
  const TripsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(tripsHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTrips)),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(child: Text(l10n.tripsEmpty));
          }
          final grouped = _groupByDay(entries);
          return ListView(
            children: [
              for (final group in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AlongSpace.s16,
                    AlongSpace.s16,
                    AlongSpace.s16,
                    AlongSpace.s8,
                  ),
                  child: Text(group.key, style: AlongText.bodyStrong),
                ),
                for (final entry in group.value)
                  ListTile(
                    key: Key('trip_history_${entry.tripId}'),
                    title: Text(entry.routeLabel),
                    subtitle: Text(
                      '${DateFormat.jm().format(entry.completedAt)} · ${design.formatMoney(entry.totalFare.minorUnits ~/ 100)}',
                    ),
                    leading: ModeChip(
                      mode: designMode(entry.modeCode),
                      size: ModeChipSize.small,
                    ),
                    trailing: _StatusPill(status: entry.status),
                    onTap: () => context.push(
                      AppRoutes.tripDetail,
                      extra: entry.tripId,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Map<String, List<TripHistoryEntry>> _groupByDay(List<TripHistoryEntry> entries) {
    final map = <String, List<TripHistoryEntry>>{};
    for (final entry in entries) {
      final key = DateFormat.yMMMMd().format(entry.completedAt.toLocal());
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      TripStatus.completed => 'Completed',
      TripStatus.cancelled => 'Cancelled',
      _ => status.name,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AlongSpace.s8,
        vertical: AlongSpace.s4,
      ),
      decoration: BoxDecoration(
        color: AlongColors.surface100,
        borderRadius: BorderRadius.circular(AlongRadius.xs.x),
      ),
      child: Text(label, style: AlongText.caption),
    );
  }
}
