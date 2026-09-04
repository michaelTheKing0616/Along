/// Trip lifecycle status (subset used client-side).
enum TripStatus {
  requested,
  accepted,
  boarded,
  inTransit,
  transfer,
  completed,
  declined,
  expired,
  cancelled;

  static TripStatus? tryParse(String? raw) {
    if (raw == null) return null;
    final normalized = raw.replaceAll('-', '_');
    return switch (normalized) {
      'requested' => TripStatus.requested,
      'accepted' => TripStatus.accepted,
      'boarded' => TripStatus.boarded,
      'in_transit' => TripStatus.inTransit,
      'transfer' => TripStatus.transfer,
      'completed' => TripStatus.completed,
      'declined' => TripStatus.declined,
      'expired' => TripStatus.expired,
      'cancelled' => TripStatus.cancelled,
      _ => null,
    };
  }
}
