/// Client mirror of `trip_transition` in migration 53.
///
/// The server function is the authority. This table exists so a fuzz test can
/// reject illegal edges without a live database.
enum TripActorType { rider, driver, system }

class TripTransitionRequest {
  const TripTransitionRequest({
    required this.fromStatus,
    required this.toStatus,
    required this.actor,
    required this.actorIsRider,
    required this.actorIsDriver,
    required this.driverMatchable,
  });

  final String fromStatus;
  final String toStatus;
  final TripActorType actor;
  final bool actorIsRider;
  final bool actorIsDriver;
  final bool driverMatchable;
}

/// Statuses the lifecycle function knows about.
const tripTransitionStatuses = <String>[
  'requested',
  'accepted',
  'boarded',
  'in_transit',
  'transfer',
  'completed',
  'declined',
  'expired',
  'cancelled_by_rider',
  'cancelled_by_driver',
  'no_show',
  'released_before_arrival',
];

/// Returns true only for an edge `trip_transition` would commit.
bool tripTransitionAllowed(TripTransitionRequest request) {
  if (request.fromStatus == request.toStatus) return false;
  final party = switch (request.actor) {
    TripActorType.rider => request.actorIsRider,
    TripActorType.driver => request.actorIsDriver,
    TripActorType.system => true,
  };
  if (!party && request.actor != TripActorType.system) return false;

  return switch ((request.fromStatus, request.toStatus, request.actor)) {
    ('requested', 'accepted', TripActorType.driver) => request.driverMatchable,
    ('requested', 'declined', TripActorType.driver) => true,
    ('requested', 'expired', TripActorType.system) => true,
    ('requested', 'cancelled_by_rider', TripActorType.rider) => true,
    ('accepted', 'cancelled_by_rider', TripActorType.rider) => true,
    ('accepted', 'cancelled_by_driver', TripActorType.driver) => true,
    ('accepted', 'no_show', TripActorType.driver) => true,
    ('accepted', 'released_before_arrival', TripActorType.driver) => true,
    ('accepted', 'boarded', TripActorType.system) => true,
    ('accepted', 'boarded', TripActorType.rider) => true,
    ('accepted', 'boarded', TripActorType.driver) => true,
    ('boarded', 'in_transit', TripActorType.system) => true,
    ('boarded', 'in_transit', TripActorType.driver) => true,
    ('boarded', 'cancelled_by_driver', TripActorType.driver) => true,
    ('boarded', 'cancelled_by_rider', TripActorType.rider) => true,
    ('in_transit', 'completed', TripActorType.driver) => true,
    ('in_transit', 'cancelled_by_driver', TripActorType.driver) => true,
    ('in_transit', 'cancelled_by_rider', TripActorType.rider) => true,
    _ => false,
  };
}
