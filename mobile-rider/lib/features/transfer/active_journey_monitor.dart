import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/transfer/presentation/transfer_screen.dart';

/// Reads [client.trip_poll_interval_s] — shared by [ActiveJourneyMonitor] and [RequestingController].
Future<Duration> readTripPollInterval(Ref ref) async {
  final seconds = (await ref
          .read(configRepositoryProvider)
          .configNum('client.trip_poll_interval_s'))
      .toInt();
  return Duration(seconds: seconds);
}

class ActiveJourneyMonitorState {
  const ActiveJourneyMonitorState({
    this.journeyId,
    this.trackedTripId,
    this.afterTripSequence,
    this.candidateId,
    this.transferNavigation,
  });

  final String? journeyId;
  final String? trackedTripId;
  final int? afterTripSequence;
  final String? candidateId;
  final TransferRouteArgs? transferNavigation;

  ActiveJourneyMonitorState copyWith({
    String? journeyId,
    String? trackedTripId,
    int? afterTripSequence,
    String? candidateId,
    TransferRouteArgs? transferNavigation,
    bool clearTransferNavigation = false,
  }) {
    return ActiveJourneyMonitorState(
      journeyId: journeyId ?? this.journeyId,
      trackedTripId: trackedTripId ?? this.trackedTripId,
      afterTripSequence: afterTripSequence ?? this.afterTripSequence,
      candidateId: candidateId ?? this.candidateId,
      transferNavigation: clearTransferNavigation
          ? null
          : (transferNavigation ?? this.transferNavigation),
    );
  }
}

final activeJourneyMonitorProvider =
    NotifierProvider<ActiveJourneyMonitor, ActiveJourneyMonitorState>(
  ActiveJourneyMonitor.new,
);

/// Watches an active multi-leg journey and surfaces R-14 when status → transfer.
class ActiveJourneyMonitor extends Notifier<ActiveJourneyMonitorState> {
  Timer? _pollTimer;

  @override
  ActiveJourneyMonitorState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    return const ActiveJourneyMonitorState();
  }

  void trackFromTrip(TripSummary trip, {String? candidateId}) {
    _pollTimer?.cancel();
    state = ActiveJourneyMonitorState(
      journeyId: trip.journeyId,
      trackedTripId: trip.tripId,
      afterTripSequence: trip.journeySequence,
      candidateId: candidateId,
    );
    unawaited(_startPolling());
  }

  Future<void> _startPolling() async {
    final interval = await readTripPollInterval(ref);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _poll());
    unawaited(_poll());
  }

  void stopTracking() {
    _pollTimer?.cancel();
    _pollTimer = null;
    state = const ActiveJourneyMonitorState();
  }

  void clearTransferNavigation() {
    if (state.transferNavigation == null) return;
    state = state.copyWith(clearTransferNavigation: true);
  }

  Future<void> _poll() async {
    final journeyId = state.journeyId;
    if (journeyId == null) return;

    try {
      final tripsRepo = ref.read(tripsRepositoryProvider);
      final journeyRepo = ref.read(journeyRepositoryProvider);

      final trackedTripId = state.trackedTripId;
      if (trackedTripId != null) {
        final trip = await tripsRepo.tripSnapshot(trackedTripId);
        if (trip.status == TripStatus.completed ||
            trip.status == TripStatus.transfer) {
          state = state.copyWith(afterTripSequence: trip.journeySequence);
        }
      }

      final snapshot = await journeyRepo.journeyStatusSnapshot(journeyId);
      if (snapshot == null || snapshot.status != 'transfer') return;
      if (state.transferNavigation != null) return;

      final candidateId =
          state.candidateId ?? snapshot.candidateId ?? await journeyRepo.planCandidateId(journeyId);
      if (candidateId == null) return;

      final afterSeq = state.afterTripSequence ??
          (snapshot.currentTripSequence != null
              ? snapshot.currentTripSequence! - 1
              : 1);

      state = state.copyWith(
        transferNavigation: TransferRouteArgs(
          journeyId: journeyId,
          afterTripSequence: afterSeq,
          candidateId: candidateId,
        ),
      );
    } catch (_) {}
  }
}
