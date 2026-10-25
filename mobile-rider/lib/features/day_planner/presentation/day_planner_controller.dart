import 'package:along_core/along_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';

class DayPlannerState {
  const DayPlannerState({
    this.itinerary,
    this.isLoading = false,
    this.isPreparing = false,
    this.isMatching = false,
    this.errorMessage,
  });

  final ItineraryStateView? itinerary;
  final bool isLoading;
  final bool isPreparing;
  final bool isMatching;
  final String? errorMessage;

  DayPlannerState copyWith({
    ItineraryStateView? itinerary,
    bool? isLoading,
    bool? isPreparing,
    bool? isMatching,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DayPlannerState(
      itinerary: itinerary ?? this.itinerary,
      isLoading: isLoading ?? this.isLoading,
      isPreparing: isPreparing ?? this.isPreparing,
      isMatching: isMatching ?? this.isMatching,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final dayPlannerControllerProvider =
    NotifierProvider.family<DayPlannerController, DayPlannerState, String>(
  DayPlannerController.new,
);

class DayPlannerController extends FamilyNotifier<DayPlannerState, String> {
  late String _itineraryId;

  @override
  DayPlannerState build(String itineraryId) {
    _itineraryId = itineraryId;
    Future.microtask(() => refresh());
    return const DayPlannerState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(itineraryRepositoryProvider);
      final view = await repo.itineraryState(state.itinerary?.itineraryId ?? _itineraryId);
      state = state.copyWith(itinerary: view, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> prepareNext() async {
    final id = state.itinerary?.itineraryId ?? _itineraryId;
    state = state.copyWith(isPreparing: true, clearError: true);
    try {
      final repo = ref.read(itineraryRepositoryProvider);
      final view = await repo.itineraryMatchNext(id);
      state = state.copyWith(itinerary: view, isPreparing: false);
    } catch (e) {
      state = state.copyWith(isPreparing: false, errorMessage: e.toString());
    }
  }

  Future<TripSummary?> matchNow() async {
    final itinerary = state.itinerary;
    if (itinerary == null || !itinerary.hasPreparedPlan) return null;

    final stop = itinerary.nextPendingStop;
    final plan = itinerary.nextPreparedPlan!;
    if (stop == null || stop.destinationLocation == null) return null;

    final candidateId = plan.sortOrders[SortCriterion.recommended]?.firstOrNull ??
        plan.candidates.first.candidateId;
    final candidate = plan.candidates
        .where((c) => c.candidateId == candidateId)
        .firstOrNull ??
        plan.candidates.first;

    final origin = GeoPoint(lat: 9.0765, lng: 7.3986);

    final session = TripPlanSession(
      origin: origin,
      destination: stop.destinationLocation!,
      destinationLabel: stop.destinationDescription,
      itineraryStopId: stop.stopId,
    );

    ref.read(tripPlanSessionProvider.notifier).setSession(session);
    final tripOptions = ref.read(tripOptionsControllerProvider.notifier);
    tripOptions.loadPreparedPlan(
      session: session,
      plan: plan,
      load: _loadFromItinerary(itinerary),
    );
    tripOptions.requestCandidate(candidate);

    state = state.copyWith(isMatching: true, clearError: true);
    try {
      final summary = await tripOptions.commitPendingRequest();
      state = state.copyWith(isMatching: false);
      return summary;
    } catch (e) {
      state = state.copyWith(isMatching: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> reorderStop(String stopId, int newSequence) async {
    final id = state.itinerary?.itineraryId ?? _itineraryId;
    try {
      final repo = ref.read(itineraryRepositoryProvider);
      final view = await repo.updateItineraryStops(
        itineraryId: id,
        ops: [
          {'op': 'reorder', 'stop_id': stopId, 'sequence': newSequence},
        ],
      );
      state = state.copyWith(itinerary: view);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> removeStop(String stopId) async {
    final id = state.itinerary?.itineraryId ?? _itineraryId;
    try {
      final repo = ref.read(itineraryRepositoryProvider);
      final view = await repo.updateItineraryStops(
        itineraryId: id,
        ops: [
          {'op': 'remove', 'stop_id': stopId},
        ],
      );
      state = state.copyWith(itinerary: view);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> addStop({
    required String description,
    required GeoPoint location,
    required int sequence,
  }) async {
    final id = state.itinerary?.itineraryId ?? _itineraryId;
    try {
      final repo = ref.read(itineraryRepositoryProvider);
      final view = await repo.updateItineraryStops(
        itineraryId: id,
        ops: [
          {
            'op': 'add',
            'sequence': sequence,
            'destination_description': description,
            'location': {'lat': location.lat, 'lng': location.lng},
          },
        ],
      );
      state = state.copyWith(itinerary: view);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

LoadFlagState _loadFromItinerary(ItineraryStateView itinerary) {
  if (!itinerary.loadFlagged) return const LoadFlagState();
  return LoadFlagState(
    flagged: true,
    size: itinerary.loadSize,
    note: itinerary.loadNote,
    rememberForDay: true,
  );
}
