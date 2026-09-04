import 'package:along_core/src/models/candidate.dart';

/// Saved multi-stop itinerary from the rider planner session.
class Itinerary {
  const Itinerary({
    required this.itineraryId,
    required this.stops,
    required this.selectedCandidate,
  });

  final String itineraryId;
  final List<ItineraryStop> stops;
  final PlanCandidate? selectedCandidate;

  /// Stops ordered by sequence for display and routing.
  List<ItineraryStop> get orderedStops =>
      List.of(stops)..sort((a, b) => a.sequence.compareTo(b.sequence));
}

class ItineraryStop {
  const ItineraryStop({
    required this.stopId,
    required this.sequence,
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String stopId;
  final int sequence;
  final String label;
  final double lat;
  final double lng;
}
