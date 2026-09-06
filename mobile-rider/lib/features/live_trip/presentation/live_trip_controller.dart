import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/live_trip_config.dart';

/// Args for [LiveTripController] family provider.
class LiveTripArgs {
  const LiveTripArgs({
    required this.tripId,
    required this.initialTrip,
  });

  final String tripId;
  final TripSummary initialTrip;

  @override
  bool operator ==(Object other) =>
      other is LiveTripArgs &&
      other.tripId == tripId &&
      other.initialTrip.tripId == initialTrip.tripId;

  @override
  int get hashCode => Object.hash(tripId, initialTrip.tripId);
}

/// Shared polling state for R-11 / R-13.
class LiveTripState {
  const LiveTripState({
    required this.trip,
    this.isPolling = true,
    this.livePaused = false,
    this.driverSignalLost = false,
    this.lastLiveAt,
    this.errorMessage,
  });

  final TripSummary trip;
  final bool isPolling;
  final bool livePaused;
  final bool driverSignalLost;
  final DateTime? lastLiveAt;
  final String? errorMessage;

  LiveTripState copyWith({
    TripSummary? trip,
    bool? isPolling,
    bool? livePaused,
    bool? driverSignalLost,
    DateTime? lastLiveAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LiveTripState(
      trip: trip ?? this.trip,
      isPolling: isPolling ?? this.isPolling,
      livePaused: livePaused ?? this.livePaused,
      driverSignalLost: driverSignalLost ?? this.driverSignalLost,
      lastLiveAt: lastLiveAt ?? this.lastLiveAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final liveTripControllerFamilyProvider = NotifierProvider.family<
    LiveTripController, LiveTripState, LiveTripArgs>(
  LiveTripController.new,
);

class LiveTripController extends FamilyNotifier<LiveTripState, LiveTripArgs> {
  Timer? _pollTimer;
  LiveTripConfig? _config;

  @override
  LiveTripState build(LiveTripArgs args) {
    ref.onDispose(() => _pollTimer?.cancel());
    Future.microtask(_bootstrapPoll);
    return LiveTripState(
      trip: args.initialTrip,
      lastLiveAt: args.initialTrip.live?.asOf,
    );
  }

  Future<void> _bootstrapPoll() async {
    _config = await ref.read(liveTripConfigProvider.future);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_config!.pollInterval, (_) => _poll());
    unawaited(_poll());
  }

  Future<void> _poll() async {
    if (!state.isPolling) return;
    try {
      final summary =
          await ref.read(tripsRepositoryProvider).tripSnapshot(arg.tripId);
      final now = ref.read(clockProvider).now();
      final LiveTripConfig config =
          _config ?? await ref.read(liveTripConfigProvider.future);
      _config = config;

      final liveAt = summary.live?.asOf ?? state.lastLiveAt;
      final sinceLive = liveAt != null ? now.difference(liveAt) : null;
      final driverLost = sinceLive != null &&
          sinceLive >= config.driverOfflineAfter &&
          summary.status == TripStatus.accepted;

      state = state.copyWith(
        trip: summary,
        lastLiveAt: summary.live?.asOf ?? state.lastLiveAt,
        livePaused:
            sinceLive != null && sinceLive >= config.livePausedAfter,
        driverSignalLost: driverLost,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<TripSummary> markBoarded() async {
    final summary = await ref
        .read(tripsRepositoryProvider)
        .markBoarded(state.trip.tripId);
    state = state.copyWith(trip: summary);
    return summary;
  }

  Future<void> cancelTrip() async {
    await ref
        .read(tripsRepositoryProvider)
        .cancelTrip(state.trip.tripId, reason: 'rider_cancel');
    _pollTimer?.cancel();
    state = state.copyWith(isPolling: false);
  }

  void stopPolling() {
    _pollTimer?.cancel();
    state = state.copyWith(isPolling: false);
  }
}
