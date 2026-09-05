import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/trip_options/domain/load_capacity_warning.dart';
import 'package:mobile_rider/features/trip_options/presentation/coverage_gap_view.dart';
import 'package:mobile_rider/features/trip_options/presentation/load_flag_sheet.dart';
import 'package:mobile_rider/features/trip_options/presentation/option_card_mapper.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripOptionsTitle),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            key: const Key('trip_options_load_flag'),
            icon: Badge(
              isLabelVisible: state.load.flagged,
              child: const Icon(Icons.inventory_2_outlined),
            ),
            tooltip: l10n.loadFlagTitle,
            onPressed: () => _openLoadSheet(state),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Container(
                  key: const Key('trip_options_map'),
                  color: AlongColors.surface100,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.route_outlined,
                    size: 48,
                    color: AlongColors.ink500,
                  ),
                ),
                if (state.showSkeleton)
                  const Positioned(
                    top: AlongSpace.s16,
                    left: AlongSpace.s16,
                    child: AlongSkeleton(variant: SkeletonVariant.mapOverlay),
                  ),
              ],
            ),
          ),
          if (state.plan?.degraded == true)
            Container(
              width: double.infinity,
              color: AlongColors.semanticWarningTint,
              padding: const EdgeInsets.symmetric(
                horizontal: AlongSpace.s16,
                vertical: AlongSpace.s8,
              ),
              child: Text(
                l10n.tripOptionsDegradedBanner,
                style: AlongText.caption.copyWith(
                  color: AlongColors.semanticWarning,
                ),
              ),
            ),
          Expanded(
            flex: 6,
            child: _buildSheetContent(context, state, controller, l10n),
          ),
        ],
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
            // R-19 wayfinding arrives later — honest no-op for now.
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
              Text(l10n.tripOptionsHeading, style: AlongText.heading2),
              const SizedBox(height: AlongSpace.s12),
              SortChips(
                selected: _mapSort(state.sort),
                onSelected: (option) =>
                    controller.setSort(_mapSortOption(option)),
              ),
            ],
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
                child: _buildOptionCard(
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
    final fareNaira = candidate.totalFareMinorUnits;
    final loadWarning = OptionCardMapper.hasLoadCapacityWarning(
      candidate,
      state.load,
    );

    return OptionCard(
      key: Key('option_card_${candidate.candidateId}'),
      variant: candidate.isMultiLeg
          ? OptionCardVariant.multiLeg
          : OptionCardVariant.direct,
      recommended: recommended,
      mode: OptionCardMapper.mapMode(leg.mode),
      secondaryMode: candidate.legs.length > 1
          ? OptionCardMapper.mapMode(candidate.legs[1].mode)
          : null,
      boardLabel: leg.boardName,
      alightLabel: leg.alightName,
      meta: OptionCardMapper.metaForCandidate(candidate),
      fareNaira: fareNaira,
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
      requestLabel: isTier3 ? l10n.tripOptionsAgreePrice : null,
      onRequest: isTier3
          ? () => _showAgreePricePlaceholder(l10n)
          : () => ref
              .read(tripOptionsControllerProvider.notifier)
              .requestCandidate(candidate),
    );
  }

  void _showAgreePricePlaceholder(AppLocalizations l10n) {
    showAlongToast(
      context,
      message: l10n.tripOptionsAgreePricePlaceholder,
      variant: AlongToastVariant.info,
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
