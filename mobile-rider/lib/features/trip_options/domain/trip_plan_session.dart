import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_helpers.dart';

/// Active trip-planning context passed from search → R-07 (P1-B-03).
class TripPlanSession {
  const TripPlanSession({
    required this.origin,
    required this.destination,
    required this.destinationLabel,
    this.hailIntent,
    this.itineraryStopId,
    this.placementContext,
  });

  final GeoPoint origin;
  final GeoPoint destination;
  final String destinationLabel;
  final HailIntent? hailIntent;
  final String? itineraryStopId;
  final PlacementContext? placementContext;

  bool get isHail => hailIntent != null;
}

/// Rider load flag persisted for the current planning session / day.
class LoadFlagState {
  const LoadFlagState({
    this.flagged = false,
    this.size,
    this.note,
    this.rememberForDay = false,
    this.acknowledgedWarning = false,
  });

  final bool flagged;
  final String? size;
  final String? note;
  final bool rememberForDay;
  final bool acknowledgedWarning;

  LoadFlagState copyWith({
    bool? flagged,
    String? size,
    String? note,
    bool? rememberForDay,
    bool? acknowledgedWarning,
    bool clearSize = false,
    bool clearNote = false,
  }) {
    return LoadFlagState(
      flagged: flagged ?? this.flagged,
      size: clearSize ? null : (size ?? this.size),
      note: clearNote ? null : (note ?? this.note),
      rememberForDay: rememberForDay ?? this.rememberForDay,
      acknowledgedWarning:
          acknowledgedWarning ?? this.acknowledgedWarning,
    );
  }
}
