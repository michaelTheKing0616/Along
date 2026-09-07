import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/day_planner/presentation/day_planner_controller.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/load_flag_sheet.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-20 Day planner — timeline of stops with Match now (doc 06, FM23).
class DayPlannerScreen extends ConsumerWidget {
  const DayPlannerScreen({super.key, required this.itineraryId});

  final String itineraryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(dayPlannerControllerProvider(itineraryId));
    final controller =
        ref.read(dayPlannerControllerProvider(itineraryId).notifier);
    final itinerary = state.itinerary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dayPlannerTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : itinerary == null
              ? Center(child: Text(l10n.dayPlannerEmpty))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      key: const Key('day_planner_load_toggle'),
                      title: Text(l10n.dayPlannerLoadToggle),
                      value: state.load.flagged,
                      onChanged: (value) {
                        if (value) {
                          showLoadFlagSheet(
                            context,
                            initial: state.load.copyWith(
                              flagged: true,
                              rememberForDay: true,
                            ),
                            warnCapacities: const {},
                            modeLoadCapacity: null,
                            onApply: controller.updateLoad,
                          );
                        } else {
                          controller.updateLoad(const LoadFlagState());
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AlongSpace.s16),
                      child: Text(
                        l10n.dayPlannerNotBookedHint,
                        style: AlongText.caption.copyWith(
                          color: AlongColors.ink500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _StopTimeline(
                        itinerary: itinerary,
                        onRemove: controller.removeStop,
                        onReorder: (oldIndex, newIndex) {
                          final pending = itinerary.stops
                              .where((s) => s.status == ItineraryStopStatus.pending)
                              .toList()
                            ..sort((a, b) => a.sequence.compareTo(b.sequence));
                          if (oldIndex >= pending.length ||
                              newIndex >= pending.length) {
                            return;
                          }
                          final stop = pending[oldIndex];
                          final target = pending[newIndex];
                          controller.reorderStop(stop.stopId, target.sequence);
                        },
                      ),
                    ),
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AlongSpace.s16,
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: AlongText.caption.copyWith(
                            color: AlongColors.semanticDanger,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(AlongSpace.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showMatchActions(itinerary)) ...[
                            if (itinerary.hasPreparedPlan)
                              AlongButton(
                                key: const Key('day_planner_match_now'),
                                label: l10n.dayPlannerMatchNow,
                                variant: AlongButtonVariant.yellow,
                                size: AlongButtonSize.secondary,
                                visualState: state.isMatching
                                    ? AlongButtonVisualState.loading
                                    : AlongButtonVisualState.normal,
                                onPressed: state.isMatching
                                    ? null
                                    : () async {
                                        final trip =
                                            await controller.matchNow();
                                        if (trip != null && context.mounted) {
                                          context.push(
                                            AppRoutes.requesting,
                                            extra: RequestingRouteArgs(
                                              trip: trip,
                                              roamingSource: false,
                                            ),
                                          );
                                        }
                                      },
                              )
                            else
                              AlongButton(
                                key: const Key('day_planner_prepare'),
                                label: l10n.dayPlannerPrepare,
                                variant: AlongButtonVariant.secondary,
                                size: AlongButtonSize.secondary,
                                visualState: state.isPreparing
                                    ? AlongButtonVisualState.loading
                                    : AlongButtonVisualState.normal,
                                onPressed: state.isPreparing
                                    ? null
                                    : controller.prepareNext,
                              ),
                            const SizedBox(height: AlongSpace.s12),
                          ],
                          TextButton(
                            key: const Key('day_planner_add_stop'),
                            onPressed: () => context.push(
                              AppRoutes.itineraryEntry,
                              extra: itineraryId,
                            ),
                            child: Text(l10n.dayPlannerAddStop),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  bool _showMatchActions(ItineraryStateView itinerary) {
    return itinerary.nextPendingStopId != null;
  }
}

class _StopTimeline extends StatelessWidget {
  const _StopTimeline({
    required this.itinerary,
    required this.onRemove,
    required this.onReorder,
  });

  final ItineraryStateView itinerary;
  final Future<void> Function(String stopId) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stops = [...itinerary.stops]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final locked = stops
        .where((s) => s.status != ItineraryStopStatus.pending)
        .toList(growable: false);
    final pending = stops
        .where((s) => s.status == ItineraryStopStatus.pending)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s16),
      children: [
        for (final stop in locked) _buildStopTile(context, l10n, stop, itinerary),
        if (pending.isNotEmpty)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: onReorder,
            children: [
              for (var i = 0; i < pending.length; i++)
                _buildPendingStopTile(
                  context,
                  l10n,
                  pending[i],
                  itinerary,
                  index: i,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildStopTile(
    BuildContext context,
    AppLocalizations l10n,
    ItineraryStopView stop,
    ItineraryStateView itinerary,
  ) {
    final isNext = stop.stopId == itinerary.nextPendingStopId;
    return ListTile(
      key: ValueKey(stop.stopId),
      leading: _leadingIcon(stop, isNext),
      title: Text(stop.destinationDescription, style: AlongText.bodyStrong),
      subtitle: _subtitleForStop(l10n, stop, isNext, itinerary) == null
          ? null
          : Text(_subtitleForStop(l10n, stop, isNext, itinerary)!),
    );
  }

  Widget _buildPendingStopTile(
    BuildContext context,
    AppLocalizations l10n,
    ItineraryStopView stop,
    ItineraryStateView itinerary, {
    required int index,
  }) {
    final isNext = stop.stopId == itinerary.nextPendingStopId;
    return ListTile(
      key: ValueKey(stop.stopId),
      leading: _leadingIcon(stop, isNext),
      title: Text(stop.destinationDescription, style: AlongText.bodyStrong),
      subtitle: _subtitleForStop(l10n, stop, isNext, itinerary) == null
          ? null
          : Text(_subtitleForStop(l10n, stop, isNext, itinerary)!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => onRemove(stop.stopId),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle_rounded),
          ),
        ],
      ),
    );
  }

  Widget _leadingIcon(ItineraryStopView stop, bool isNext) {
    return switch (stop.status) {
      ItineraryStopStatus.completed => Icon(
          Icons.check_circle,
          color: AlongColors.semanticSuccess,
        ),
      ItineraryStopStatus.inProgress => Icon(
          Icons.directions_car_filled_outlined,
          color: AlongColors.brandYellow,
        ),
      ItineraryStopStatus.pending when isNext =>
        Icon(Icons.radio_button_checked, color: AlongColors.brandYellow),
      ItineraryStopStatus.pending => Icon(
          Icons.radio_button_unchecked,
          color: AlongColors.ink300,
        ),
      ItineraryStopStatus.skipped => Icon(
          Icons.remove_circle_outline,
          color: AlongColors.ink500,
        ),
    };
  }

  String? _subtitleForStop(
    AppLocalizations l10n,
    ItineraryStopView stop,
    bool isNext,
    ItineraryStateView itinerary,
  ) {
    return switch (stop.status) {
      ItineraryStopStatus.completed => l10n.dayPlannerStopDone,
      ItineraryStopStatus.inProgress => l10n.dayPlannerStopInProgress(
          stop.etaMinutes ?? 12,
        ),
      ItineraryStopStatus.pending when isNext =>
        itinerary.hasPreparedPlan
            ? l10n.dayPlannerStopReady
            : l10n.dayPlannerStopPrepareHint,
      ItineraryStopStatus.pending => l10n.dayPlannerStopPending,
      ItineraryStopStatus.skipped => l10n.dayPlannerStopSkipped,
    };
  }
}
