import 'package:along_core/src/models/geo_point.dart';
import 'package:along_core/src/models/plan_result.dart';

/// Server-side stop lifecycle (itinerary_stops.status).
enum ItineraryStopStatus {
  pending,
  inProgress,
  completed,
  skipped;

  static ItineraryStopStatus fromString(String raw) => switch (raw) {
        'pending' => ItineraryStopStatus.pending,
        'in_progress' => ItineraryStopStatus.inProgress,
        'completed' => ItineraryStopStatus.completed,
        'skipped' => ItineraryStopStatus.skipped,
        _ => ItineraryStopStatus.pending,
      };
}

/// Full itinerary view from `itinerary_state` / create RPCs (P5-A-03).
class ItineraryStateView {
  const ItineraryStateView({
    required this.itineraryId,
    required this.status,
    required this.planDate,
    required this.loadFlagged,
    required this.stops,
    this.loadSize,
    this.loadNote,
    this.nextPendingStopId,
    this.nextPreparedPlan,
    this.notBooked = true,
    this.matchAction = 'request_trip',
  });

  final String itineraryId;
  final String status;
  final DateTime planDate;
  final bool loadFlagged;
  final String? loadSize;
  final String? loadNote;
  final List<ItineraryStopView> stops;
  final String? nextPendingStopId;
  final PlanResult? nextPreparedPlan;
  final bool notBooked;
  final String matchAction;

  ItineraryStopView? get nextPendingStop {
    final id = nextPendingStopId;
    if (id == null) return null;
    for (final stop in stops) {
      if (stop.stopId == id) return stop;
    }
    return null;
  }

  bool get hasPreparedPlan =>
      nextPreparedPlan != null && nextPreparedPlan!.candidates.isNotEmpty;
}

/// One row in the day planner timeline.
class ItineraryStopView {
  const ItineraryStopView({
    required this.stopId,
    required this.sequence,
    required this.destinationDescription,
    required this.status,
    this.destinationLocation,
    this.preparedPlan,
    this.linkedJourneyId,
    this.etaMinutes,
  });

  final String stopId;
  final int sequence;
  final String destinationDescription;
  final ItineraryStopStatus status;
  final GeoPoint? destinationLocation;
  final PlanResult? preparedPlan;
  final String? linkedJourneyId;
  final int? etaMinutes;
}

/// Parsed NL proposal item from `parse-itinerary` (never persisted until confirm).
class ParseItineraryProposalItem {
  const ParseItineraryProposalItem({
    required this.sequence,
    required this.destinationDescription,
    required this.resolved,
    this.resolvedLabel,
    this.resolvedLocation,
    this.confidence,
  });

  final int sequence;
  final String destinationDescription;
  final bool resolved;
  final String? resolvedLabel;
  final GeoPoint? resolvedLocation;
  final double? confidence;
}

/// Edge `parse-itinerary` response — proposal only (§5.3).
class ParseItineraryResult {
  const ParseItineraryResult({
    required this.proposal,
    required this.needsConfirmation,
  });

  final List<ParseItineraryProposalItem> proposal;
  final bool needsConfirmation;
}
