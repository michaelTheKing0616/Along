import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/trip_options/domain/load_capacity_warning.dart';
import 'package:mobile_rider/features/placements/domain/placement_context_resolver.dart';
import 'package:mobile_rider/features/placements/presentation/placement_providers.dart';
import 'package:mobile_rider/features/placements/presentation/sponsored_placement_slot.dart';
import 'package:mobile_rider/features/trip_options/presentation/coverage_gap_view.dart';
import 'package:mobile_rider/features/trip_options/presentation/explain_popover.dart';
import 'package:mobile_rider/features/trip_options/presentation/load_flag_sheet.dart';
import 'package:mobile_rider/features/trip_options/presentation/multi_leg_option_card.dart';
import 'package:mobile_rider/features/trip_options/presentation/option_card_mapper.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_route_args.dart';
import 'package:mobile_rider/features/offline/stale_badge.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';
import 'package:mobile_rider/features/wayfinding/presentation/wayfinding_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/l10n/l10n_format.dart';
import 'package:mobile_rider/routing/routes.dart';

/// Default undo window before committing a one-tap request (UI-only, not request TTL).
const kRequestUndoSeconds = 3;

/// R-07 Trip options — direct candidates from plan-trip with one-tap request.
class TripOptionsScreen extends ConsumerStatefulWidget {
  const TripOptionsScreen({super.key});

  @override
  ConsumerState<TripOptionsScreen> createState() => _TripOptionsScreenState();
}

class _TripOptionsScreenState extends ConsumerState<TripOptionsScreen> {
  bool _coverageReportThanks = false;
  Timer? _undoTimer;
  int _undoSecondsLeft = kRequestUndoSeconds;

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(tripOptionsControllerProvider);
    final controller = ref.read(tripOptionsControllerProvider.notifier);

    ref.listen(tripOptionsControllerProvider, (prev, next) {
      if (next.pendingRequestCandidateId != null &&
          prev?.pendingRequestCandidateId == null) {
        _startUndoFlow(next.pendingRequestCandidateId!);
      }
    });

    final palette = AlongPalette.of(context);

    return Scaffold(
      backgroundColor: palette.surface,
      body: LayoutBuilder(
        builder: (context, box) {
          // Map takes a third, so the fare and Request button of the first
          // card sit above the fold even at 1.3x text. With one option the
          // map grows into the space a second card would use.
          final few = state.sortedCandidates.length <= 1;
          final mapHeight = box.maxHeight * (few ? 0.5 : 0.34);
          final session = state.session;
          final recommendedId = state
              .plan
              ?.sortOrders[SortCriterion.recommended]
              ?.firstOrNull;
          final lead =
              state.sortedCandidates
                  .where((c) => c.candidateId == recommendedId)
                  .firstOrNull ??
              state.sortedCandidates.firstOrNull;
          final summary = lead == null || session == null
              ? null
              : l10n.tripOptionsSummary(
                  (lead.totalTimeSeconds / 60).ceil(),
                  l10n.distance(
                    haversineDistanceM(session.origin, session.destination),
                  ),
                );
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: mapHeight + AlongRadius.dialog.x,
                child: AlongRoutePreview(
                  key: const Key('trip_options_map'),
                  semanticLabel: summary == null
                      ? session?.destinationLabel
                      : '${session?.destinationLabel}, $summary',
                  from: lead?.legs.firstOrNull?.boardName,
                  to: session?.destinationLabel,
                  summary: summary,
                  pickup: session == null
                      ? null
                      : Offset(session.origin.lng, session.origin.lat),
                  drop: session == null
                      ? null
                      : Offset(
                          session.destination.lng,
                          session.destination.lat,
                        ),
                  topInset: MediaQuery.paddingOf(context).top + 64,
                  bottomInset: AlongRadius.dialog.x,
                ),
              ),
              if (state.showSkeleton)
                Positioned(
                  top: mapHeight - 56,
                  left: AlongSpace.s16,
                  child: const AlongSkeleton(
                    variant: SkeletonVariant.mapOverlay,
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AlongSpace.s16),
                    child: Row(
                      children: [
                        AlongMapButton(
                          key: const Key('trip_options_back'),
                          icon: AlongIcons.back,
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        Badge(
                          isLabelVisible: state.load.flagged,
                          backgroundColor: palette.accent,
                          smallSize: 10,
                          child: AlongMapButton(
                            key: const Key('trip_options_load_flag'),
                            icon: AlongIcons.luggage,
                            tooltip: l10n.loadFlagTitle,
                            onPressed: () => _openLoadSheet(state),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                top: mapHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: AlongRadius.dialog,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (state.plan?.degraded == true)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AlongSpace.s16,
                            AlongSpace.s16,
                            AlongSpace.s16,
                            0,
                          ),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AlongColors.semanticWarningTint,
                              borderRadius: const BorderRadius.all(
                                AlongRadius.control,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AlongSpace.s12,
                              vertical: AlongSpace.s8,
                            ),
                            child: Text(
                              l10n.tripOptionsDegradedBanner,
                              style: AlongText.caption.copyWith(
                                color: AlongColors.semanticWarning,
                              ),
                            ),
                          ),
                        ),
                      if (state.isStalePlan)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AlongSpace.s16,
                            AlongSpace.s8,
                            AlongSpace.s16,
                            0,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: StaleBadge(
                              label: l10n.cachedOptionsStaleBadge,
                            ),
                          ),
                        ),
                      Expanded(
                        child: _buildSheetContent(
                          context,
                          state,
                          controller,
                          l10n,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSheetContent(
    BuildContext context,
    TripOptionsState state,
    TripOptionsController controller,
    AppLocalizations l10n,
  ) {
    if (state.showSkeleton) {
      return ListView(
        key: const Key('trip_options_skeleton_list'),
        padding: const EdgeInsets.all(AlongSpace.s16),
        children: const [
          AlongSkeleton(variant: SkeletonVariant.card, height: 140),
          SizedBox(height: AlongSpace.s12),
          AlongSkeleton(variant: SkeletonVariant.card, height: 140),
          SizedBox(height: AlongSpace.s12),
          AlongSkeleton(variant: SkeletonVariant.card, height: 140),
        ],
      );
    }

    if (state.hasCoverageGap) {
      return SingleChildScrollView(
        child: CoverageGapView(
          gap: state.plan!.coverageGap!,
          reportThanks: _coverageReportThanks,
          onWalkThere: () {
            final gap = state.plan!.coverageGap!;
            final nearest = gap.nearestStage;
            context.push(
              AppRoutes.wayfinding,
              extra: WayfindingRouteArgs(
                from: state.session?.origin ??
                    const GeoPoint(lat: 9.0765, lng: 7.3986),
                to: nearest.location,
                cityId: state.plan?.cityId,
                destinationLabel: nearest.name,
                cacheTripId: 'coverage-${gap.reportId}',
              ),
            );
          },
          onTellUs: () {
            setState(() => _coverageReportThanks = true);
          },
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s24),
          child: Text(state.errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    if (state.isLoading && !state.showSkeleton) {
      return const SizedBox.shrink();
    }

    final candidates = state.sortedCandidates;
    final recommendedId = state.plan?.sortOrders[SortCriterion.recommended]
        ?.firstOrNull;
    final recommended = candidates
        .where((c) => c.candidateId == recommendedId)
        .firstOrNull;
    final alightStageId = recommended?.legs.lastOrNull?.alightStageId;
    final placementContext = placementContextFromPlan(
      sessionContext: state.session?.placementContext,
      recommendedAlightStageId: alightStageId,
    );
    final placementsAsync =
        ref.watch(tripOptionsPlacementProvider(placementContext));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AlongSpace.s16,
            AlongSpace.s16,
            AlongSpace.s16,
            AlongSpace.s8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tripOptionsHeading,
                style: AlongType.heading(AlongPalette.of(context)),
              ),
              // Sorting one option is noise; chips appear from two.
              if ((state.plan?.candidates.length ?? 0) > 1) ...[
              const SizedBox(height: AlongSpace.s12),
              SortChips(
                labels: {
                  SortOption.recommended: l10n.tripOptionsRecommended,
                  SortOption.cheapest: l10n.tripSortCheapest,
                  SortOption.fastest: l10n.tripSortFastest,
                  SortOption.leastStrenuous: l10n.tripSortEasiest,
                },
                selected: _mapSort(state.sort),
                onSelected: (option) =>
                    controller.setSort(_mapSortOption(option)),
              ),
              ],
            ],
          ),
        ),
        placementsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (placements) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s16),
            child: SponsoredPlacementSlot(placements: placements),
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const Key('trip_options_list'),
            padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s16),
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AlongSpace.s12),
                child: candidate.isMultiLeg
                    ? MultiLegOptionCard(
                        candidate: candidate,
                        recommended: candidate.candidateId == recommendedId,
                        recommendedBand:
                            state.sort != SortCriterion.recommended,
                        expanded:
                            state.expandedCandidateId == candidate.candidateId,
                        onToggleExpanded: () => ref
                            .read(tripOptionsControllerProvider.notifier)
                            .toggleExpanded(candidate.candidateId),
                        onRequestLeg: (legIndex) => ref
                            .read(tripOptionsControllerProvider.notifier)
                            .requestCandidate(candidate, legIndex: legIndex),
                        onWhy: candidate.candidateId == recommendedId &&
                                candidate.metrics != null
                            ? () => showExplainPopover(
                                  context,
                                  explain: candidate.metrics!.explain,
                                )
                            : null,
                        loadWarning: OptionCardMapper.hasLoadCapacityWarning(
                          candidate,
                          state.load,
                        )
                            ? l10n.loadFlagCapacityWarning
                            : null,
                        l10n: l10n,
                      )
                    : _buildOptionCard(
                        context,
                        candidate,
                        recommended: candidate.candidateId == recommendedId,
                        state: state,
                        l10n: l10n,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    PlanCandidate candidate,
    {
    required bool recommended,
    required TripOptionsState state,
    required AppLocalizations l10n,
  }) {
    final leg = candidate.legs.first;
    final isTier3 = leg.fare.unconfirmed;
    final loadWarning = OptionCardMapper.hasLoadCapacityWarning(
      candidate,
      state.load,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OptionCard(
          key: Key('option_card_${candidate.candidateId}'),
          variant: OptionCardVariant.direct,
          recommended: recommended,
          recommendedBand: state.sort != SortCriterion.recommended,
          mode: OptionCardMapper.mapMode(leg.mode),
          boardLabel: leg.boardName,
          alightLabel: leg.alightName,
          meta: OptionCardMapper.metaForCandidate(candidate, l10n),
          fareNaira: candidate.totalFareMinorUnits ~/ 100,
          tier: OptionCardMapper.mapFareTier(
            leg.fare.tier,
            unconfirmed: leg.fare.unconfirmed,
          ),
          visualState: loadWarning
              ? OptionCardVisualState.warning
              : OptionCardVisualState.normal,
          loadWarning: loadWarning ? l10n.loadFlagCapacityWarning : null,
          unavailableReason: !candidate.viableDirect
              ? l10n.tripOptionsSlowerDirectCaption
              : null,
          recommendedLabel: l10n.tripOptionsRecommended,
          tierLabel: l10n.fareTier(
            OptionCardMapper.mapFareTier(
              leg.fare.tier,
              unconfirmed: leg.fare.unconfirmed,
            ),
          ),
          requestLabel: isTier3 ? l10n.tripOptionsAgreePrice : null,
          requestLabelFor: l10n.tripOptionsRequest,
          onRequest: isTier3
              ? () => state.session?.isHail == true
                  ? _openPricingForHail(candidate, state)
                  : _openPricingForTier3(candidate, state)
              : () => ref
                  .read(tripOptionsControllerProvider.notifier)
                  .requestCandidate(candidate),
        ),
        if (recommended && candidate.metrics != null)
          Padding(
            padding: const EdgeInsets.only(top: AlongSpace.s8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AlongTextLink(
                key: Key('why_${candidate.candidateId}'),
                label: l10n.tripOptionsWhy,
                onPressed: () => showExplainPopover(
                  context,
                  explain: candidate.metrics!.explain,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openPricingForTier3(PlanCandidate candidate, TripOptionsState state) {
    final session = state.session;
    if (session == null) return;
    context.push(
      AppRoutes.pricing,
      extra: PricingRouteArgs(
        context: 'park',
        from: session.origin,
        to: session.destination,
        clientRef: 'park-${candidate.candidateId}-${DateTime.now().microsecondsSinceEpoch}',
        destinationLabel: session.destinationLabel,
      ),
    );
  }

  void _openPricingForHail(PlanCandidate candidate, TripOptionsState state) {
    final session = state.session;
    final hail = session?.hailIntent;
    if (session == null || hail == null) return;
    context.push(
      AppRoutes.pricing,
      extra: PricingRouteArgs(
        context: 'roaming',
        from: session.origin,
        to: session.destination,
        clientRef:
            'hail-${hail.candidateToken}-${DateTime.now().microsecondsSinceEpoch}',
        destinationLabel: session.destinationLabel,
        candidateToken: hail.candidateToken,
        hailIntent: hail,
      ),
    );
  }

  Future<void> _openLoadSheet(TripOptionsState state) async {
    final recommendedId =
        state.plan?.sortOrders[SortCriterion.recommended]?.firstOrNull;
    final selectedCandidate = state.sortedCandidates
        .where((candidate) => candidate.candidateId == recommendedId)
        .firstOrNull;

    Map<String, List<String>> warnCapacities = const {};
    String? modeLoadCapacity;

    if (selectedCandidate != null) {
      try {
        final configRepo = ref.read(configRepositoryProvider);
        final catalogRepo = ref.read(catalogRepositoryProvider);
        final rawWarnCapacities = await configRepo.configJson(
          'load.warn_capacities',
          cityId: state.plan?.cityId,
        );
        warnCapacities = parseWarnCapacities(rawWarnCapacities);
        final modeCode = selectedCandidate.legs.first.mode.code;
        final modeConfigs = await catalogRepo.modeConfigs();
        modeLoadCapacity = modeConfigs
            .where((mode) => mode.code == modeCode)
            .map((mode) => mode.loadCapacity)
            .firstOrNull;
      } catch (_) {
        warnCapacities = const {};
        modeLoadCapacity = null;
      }
    }

    if (!mounted) return;

    showLoadFlagSheet(
      context,
      initial: state.load,
      warnCapacities: warnCapacities,
      modeLoadCapacity: modeLoadCapacity,
      onApply: (load) {
        ref.read(tripOptionsControllerProvider.notifier).updateLoad(load);
      },
    );
  }

  void _startUndoFlow(String candidateId) {
    _undoTimer?.cancel();
    _undoSecondsLeft = kRequestUndoSeconds;

    showAlongToast(
      context,
      message: AppLocalizations.of(context).requestUndoMessage,
      variant: AlongToastVariant.undo,
      countdownSeconds: _undoSecondsLeft,
      onUndo: () {
        _undoTimer?.cancel();
        ref.read(tripOptionsControllerProvider.notifier).cancelPendingRequest();
      },
    );

    _undoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _undoSecondsLeft--;
      if (_undoSecondsLeft <= 0) {
        timer.cancel();
        unawaited(_commitRequest());
      }
    });
  }

  Future<void> _commitRequest() async {
    final controller = ref.read(tripOptionsControllerProvider.notifier);
    final roaming = ref.read(tripOptionsControllerProvider).isRoamingSource;
    try {
      final trip = await controller.commitPendingRequest();
      if (trip != null && mounted) {
        context.push(
          AppRoutes.requesting,
          extra: RequestingRouteArgs(trip: trip, roamingSource: roaming),
        );
      }
    } catch (e) {
      if (mounted) {
        showAlongToast(
          context,
          message: AppLocalizations.of(context).errorGeneric,
          variant: AlongToastVariant.info,
        );
      }
    }
  }

  SortOption _mapSort(SortCriterion sort) => switch (sort) {
        SortCriterion.recommended => SortOption.recommended,
        SortCriterion.cheapest => SortOption.cheapest,
        SortCriterion.fastest => SortOption.fastest,
        SortCriterion.leastStrenuous => SortOption.leastStrenuous,
      };

  SortCriterion _mapSortOption(SortOption option) => switch (option) {
        SortOption.recommended => SortCriterion.recommended,
        SortOption.cheapest => SortCriterion.cheapest,
        SortOption.fastest => SortCriterion.fastest,
        SortOption.leastStrenuous => SortCriterion.leastStrenuous,
      };
}

/// Route extra for [AppRoutes.requesting].
class RequestingRouteArgs {
  const RequestingRouteArgs({
    required this.trip,
    required this.roamingSource,
  });

  final TripSummary trip;
  final bool roamingSource;
}
