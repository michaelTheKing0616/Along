import 'package:along_core/src/models/trip_summary.dart';

/// Multi-leg journey grouping ordered trips.
class Journey {
  const Journey({
    required this.journeyId,
    required this.trips,
  });

  final String journeyId;
  final List<TripSummary> trips;

  List<TripSummary> get orderedTrips =>
      List.of(trips)..sort((a, b) => a.journeySequence.compareTo(b.journeySequence));

  TripSummary? get activeTrip => orderedTrips.cast<TripSummary?>().firstWhere(
        (t) => t!.isActive,
        orElse: () => null,
      );
}
