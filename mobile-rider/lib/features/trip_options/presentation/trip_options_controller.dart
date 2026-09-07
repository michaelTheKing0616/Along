import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_map/along_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/rider_prefs/rider_prefs_store.dart';
import 'package:mobile_rider/features/transfer/active_journey_monitor.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/option_card_mapper.dart';

/// UI threshold before showing planner skeletons (TS-UI-03 test constant).
const kSkeletonThreshold = Duration(milliseconds: 300);

class TripOptionsState {
  const TripOptionsState({
    this.session,
    this.plan,
    this.sort = SortCriterion.recommended,
    this.load = const LoadFlagState(),
    this.isLoading = false,
    this.showSkeleton = false,
    this.errorMessage,
    this.expandedCandidateId,
    this.pendingRequestCandidateId,
    this.pendingRequestLegIndex = 0,
    this.activeTrip,
    this.isRoamingSource = false,
    this.isStalePlan = false,
    this.planCachedAt,
  });

  final TripPlanSession? session;
  final PlanResult? plan;
  final SortCriterion sort;
  final LoadFlagState load;
  final bool isLoading;
  final bool showSkeleton;
  final String? errorMessage;
  final String? expandedCandidateId;
  final String? pendingRequestCandidateId;
  final int pendingRequestLegIndex;
  final TripSummary? activeTrip;
  final bool isRoamingSource;
  final bool isStalePlan;
  final DateTime? planCachedAt;

  bool get hasCoverageGap =>
      plan != null && plan!.candidates.isEmpty && plan!.coverageGap != null;

  List<PlanCandidate> get sortedCandidates =>
      plan?.sortedBy(sort) ?? const [];

  TripOptionsState copyWith({
    TripPlanSession? session,
    PlanResult? plan,
    SortCriterion? sort,
    LoadFlagState? load,
    bool? isLoading,
    bool? showSkeleton,
    String? errorMessage,
    String? expandedCandidateId,
    String? pendingRequestCandidateId,
    int? pendingRequestLegIndex,
    TripSummary? activeTrip,
    bool? isRoamingSource,
    bool? isStalePlan,
    DateTime? planCachedAt,
    bool clearError = false,
    bool clearActiveTrip = false,
    bool clearPending = false,
  }) {
    return TripOptionsState(
      session: session ?? this.session,
      plan: plan ?? this.plan,
      sort: sort ?? this.sort,
      load: load ?? this.load,
      isLoading: isLoading ?? this.isLoading,
      showSkeleton: showSkeleton ?? this.showSkeleton,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      expandedCandidateId:
          expandedCandidateId ?? this.expandedCandidateId,
      pendingRequestCandidateId: clearPending
          ? null
          : (pendingRequestCandidateId ?? this.pendingRequestCandidateId),
      pendingRequestLegIndex:
          pendingRequestLegIndex ?? this.pendingRequestLegIndex,
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      isRoamingSource: isRoamingSource ?? this.isRoamingSource,
      isStalePlan: isStalePlan ?? this.isStalePlan,
      planCachedAt: planCachedAt ?? this.planCachedAt,
    );
  }
}

final tripPlanSessionProvider =
    NotifierProvider<TripPlanSessionNotifier, TripPlanSession?>(
  TripPlanSessionNotifier.new,
);

class TripPlanSessionNotifier extends Notifier<TripPlanSession?> {
  @override
  TripPlanSession? build() => null;

  void setSession(TripPlanSession session) => state = session;

  void clear() => state = null;
}

final tripOptionsControllerProvider =
    NotifierProvider<TripOptionsController, TripOptionsState>(
  TripOptionsController.new,
);

class TripOptionsController extends Notifier<TripOptionsState> {
  Timer? _skeletonTimer;
  Timer? _undoTimer;

  @override
  TripOptionsState build() {
    ref.onDispose(() {
      _skeletonTimer?.cancel();
      _undoTimer?.cancel();
    });
    final session = ref.read(tripPlanSessionProvider);
    if (session != null) {
      Future.microtask(() async {
        final sort = await ref.read(riderPrefsStoreProvider).savedSort();
        state = state.copyWith(sort: sort);
        await _loadPlan(session);
      });
    }
    return TripOptionsState(session: session);
  }

  Future<void> reload() async {
    final session = state.session ?? ref.read(tripPlanSessionProvider);
    if (session == null) return;
    await _loadPlan(session);
  }

  Future<void> _loadPlan(TripPlanSession session) async {
    _skeletonTimer?.cancel();
    state = state.copyWith(
      isLoading: true,
      showSkeleton: false,
      clearError: true,
    );
    _skeletonTimer = Timer(kSkeletonThreshold, () {
      if (state.isLoading) {
        state = state.copyWith(showSkeleton: true);
      }
    });

    final body = {
        'origin': {
          'lat': session.origin.lat,
          'lng': session.origin.lng,
        },
        'destination': {
          'lat': session.destination.lat,
          'lng': session.destination.lng,
        },
        'destination_label': session.destinationLabel,
        'filters': {
          'women_only': false,
          'load': state.load.flagged
              ? {
                  'flagged': true,
                  if (state.load.size != null) 'size': state.load.size,
                  if (state.load.note != null) 'note': state.load.note,
                }
              : {'flagged': false},
          'modes': null,
        },
        'session_id': session.hashCode.toString(),
        'itinerary_stop_id': session.itineraryStopId,
      };

    try {
      final planner = ref.read(plannerRepositoryProvider);
      final outcome = await planner.planTrip(requestBody: body);
      _skeletonTimer?.cancel();
      state = state.copyWith(
        plan: outcome.result,
        isLoading: false,
        showSkeleton: false,
        isStalePlan: outcome.fromCache,
        planCachedAt: outcome.cachedAt,
      );
      if (!outcome.fromCache && outcome.result.cityId.isNotEmpty) {
        unawaited(_precacheCorridor(outcome.result));
        unawaited(
          ref.read(graphCacheStoreProvider).refreshIfNeeded(
                cityId: outcome.result.cityId,
              ),
        );
      }
    } catch (e) {
      _skeletonTimer?.cancel();
      final cached = await ref.read(plannerRepositoryProvider).readCachedPlan(
            requestBody: body,
          );
      if (cached != null) {
        state = state.copyWith(
          plan: cached.result,
          isLoading: false,
          showSkeleton: false,
          isStalePlan: true,
          planCachedAt: cached.cachedAt,
          clearError: true,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        showSkeleton: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _precacheCorridor(PlanResult plan) async {
    if (plan.candidates.isEmpty) return;
    final session = state.session;
    if (session == null) return;
    final precache = ref.read(corridorTilePrecacheProvider);
    await precache.precacheCorridor(
      CorridorPrecacheRequest(
        corridorId: plan.cityId,
        bbox: CorridorBbox(
          minLat: session.origin.lat < session.destination.lat
              ? session.origin.lat
              : session.destination.lat,
          minLng: session.origin.lng < session.destination.lng
              ? session.origin.lng
              : session.destination.lng,
          maxLat: session.origin.lat > session.destination.lat
              ? session.origin.lat
              : session.destination.lat,
          maxLng: session.origin.lng > session.destination.lng
              ? session.origin.lng
              : session.destination.lng,
        ),
      ),
    );
  }

  void setSort(SortCriterion sort) {
    state = state.copyWith(sort: sort);
    unawaited(ref.read(riderPrefsStoreProvider).setSavedSort(sort));
  }

  void toggleExpanded(String candidateId) {
    state = state.copyWith(
      expandedCandidateId:
          state.expandedCandidateId == candidateId ? null : candidateId,
    );
  }

  void updateLoad(LoadFlagState load) {
    state = state.copyWith(load: load);
    unawaited(reload());
  }

  /// One-tap request with undo window (TS-UI-01, doc 06 Part C).
  void requestCandidate(PlanCandidate candidate, {int legIndex = 0}) {
    if (state.pendingRequestCandidateId != null) return;

    if (legIndex < 0 || legIndex >= candidate.legs.length) return;

    final leg = candidate.legs[legIndex];
    if (leg.fare.unconfirmed) return;

    state = state.copyWith(
      pendingRequestCandidateId: candidate.candidateId,
      pendingRequestLegIndex: legIndex,
      isRoamingSource: candidate.source == 'roaming',
    );
  }

  void cancelPendingRequest() {
    _undoTimer?.cancel();
    state = state.copyWith(clearPending: true);
  }

  Future<TripSummary?> commitPendingRequest() async {
    final candidateId = state.pendingRequestCandidateId;
    if (candidateId == null) return null;

    final candidate = state.sortedCandidates
        .where((c) => c.candidateId == candidateId)
        .firstOrNull;
    if (candidate == null) {
      state = state.copyWith(clearPending: true);
      return null;
    }

    try {
      final trips = ref.read(tripsRepositoryProvider);
      final loadFlag = state.load.flagged
          ? LoadFlag(
              flagged: true,
              size: state.load.size,
              note: state.load.note,
              acknowledged_warning: state.load.acknowledgedWarning ||
                  !OptionCardMapper.hasLoadCapacityWarning(
                    candidate,
                    state.load,
                  ),
            )
          : null;

      final summary = await trips.requestTrip(
        RequestTripRequest(
          p_candidate_id: candidate.candidateId,
          p_leg_index: state.pendingRequestLegIndex,
          p_load: loadFlag,
          p_women_only: false,
          p_client_ref: '${candidate.candidateId}-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      state = state.copyWith(
        activeTrip: summary,
        clearPending: true,
      );
      ref.read(activeJourneyMonitorProvider.notifier).trackFromTrip(
            summary,
            candidateId: candidateId,
          );
      return summary;
    } catch (e) {
      state = state.copyWith(clearPending: true);
      rethrow;
    }
  }

  void clearActiveTrip() {
    state = state.copyWith(clearActiveTrip: true);
  }

  void preservePlanFrom(TripOptionsState preserved) {
    state = state.copyWith(
      plan: preserved.plan,
      sort: preserved.sort,
      load: preserved.load,
      session: preserved.session,
      clearActiveTrip: true,
      clearPending: true,
    );
  }

  /// Loads a precomputed prepared_plan (itinerary Match now path).
  void loadPreparedPlan({
    required TripPlanSession session,
    required PlanResult plan,
    LoadFlagState? load,
  }) {
    state = state.copyWith(
      session: session,
      plan: plan,
      load: load ?? state.load,
      isLoading: false,
      showSkeleton: false,
      clearError: true,
      clearPending: true,
      clearActiveTrip: true,
      isStalePlan: false,
      planCachedAt: null,
    );
  }
}

class RequestingState {
  const RequestingState({
    required this.trip,
    this.remainingSeconds = 0,
    this.cascadeMessage = false,
    this.expired = false,
    this.accepted = false,
    this.cancelled = false,
  });

  final TripSummary trip;
  final int remainingSeconds;
  final bool cascadeMessage;
  final bool expired;
  final bool accepted;
  final bool cancelled;

  RequestingState copyWith({
    TripSummary? trip,
    int? remainingSeconds,
    bool? cascadeMessage,
    bool? expired,
    bool? accepted,
    bool? cancelled,
  }) {
    return RequestingState(
      trip: trip ?? this.trip,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      cascadeMessage: cascadeMessage ?? this.cascadeMessage,
      expired: expired ?? this.expired,
      accepted: accepted ?? this.accepted,
      cancelled: cancelled ?? this.cancelled,
    );
  }
}

final requestingControllerFamilyProvider = NotifierProvider.family<
    RequestingController, RequestingState, RequestingArgs>(
  RequestingController.new,
);

class RequestingArgs {
  const RequestingArgs({required this.trip, required this.roamingSource});

  final TripSummary trip;
  final bool roamingSource;

  @override
  bool operator ==(Object other) =>
      other is RequestingArgs &&
      other.trip.tripId == trip.tripId &&
      other.roamingSource == roamingSource;

  @override
  int get hashCode => Object.hash(trip.tripId, roamingSource);
}

class RequestingController extends FamilyNotifier<RequestingState, RequestingArgs> {
  Timer? _tickTimer;
  Timer? _pollTimer;

  @override
  RequestingState build(RequestingArgs args) {
    ref.onDispose(() {
      _tickTimer?.cancel();
      _pollTimer?.cancel();
    });
    Future.microtask(() => _start(args));
    return RequestingState(
      trip: args.trip,
      remainingSeconds: _secondsUntilExpiry(args.trip),
      cascadeMessage: args.roamingSource,
    );
  }

  void _start(RequestingArgs args) {
    _tickTimer?.cancel();
    _pollTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    unawaited(_startPollTimer());
  }

  Future<void> _startPollTimer() async {
    final interval = await readTripPollInterval(ref);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _pollTrip());
  }

  int _secondsUntilExpiry(TripSummary trip) {
    final now = ref.read(clockProvider).now();
    final diff = trip.expiresAt.difference(now);
    return diff.inSeconds.clamp(0, diff.inSeconds);
  }

  void _onTick() {
    final remaining = _secondsUntilExpiry(state.trip);
    if (remaining <= 0) {
      _tickTimer?.cancel();
      state = state.copyWith(remainingSeconds: 0, expired: true);
      return;
    }
    state = state.copyWith(remainingSeconds: remaining);
  }

  Future<void> _pollTrip() async {
    if (state.expired || state.accepted || state.cancelled) return;
    try {
      final summary = await ref
          .read(tripsRepositoryProvider)
          .tripSnapshot(state.trip.tripId);
      if (summary.status == TripStatus.accepted) {
        _tickTimer?.cancel();
        _pollTimer?.cancel();
        state = state.copyWith(accepted: true, trip: summary);
      } else if (summary.status == TripStatus.expired ||
          summary.status == TripStatus.declined) {
        _tickTimer?.cancel();
        _pollTimer?.cancel();
        state = state.copyWith(expired: true, trip: summary);
      }
    } catch (_) {}
  }

  Future<void> cancel() async {
    await ref
        .read(tripsRepositoryProvider)
        .cancelTrip(state.trip.tripId);
    _tickTimer?.cancel();
    _pollTimer?.cancel();
    state = state.copyWith(cancelled: true);
  }
}
