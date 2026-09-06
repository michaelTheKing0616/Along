/// Rider summary visible to the driver pre-accept (doc 03 §5 TripView.rider).
class RiderPreview {
  const RiderPreview({
    required this.displayName,
    required this.rating,
    required this.tripCount,
  });

  final String displayName;
  final double rating;
  final int tripCount;
}

/// Driver summary on Tier B trip screens (doc 03 §5 TripView.driver).
class DriverPreview {
  const DriverPreview({
    required this.displayName,
    required this.rating,
    required this.tripCount,
    this.photoUrl,
  });

  final String displayName;
  final double rating;
  final int tripCount;
  final String? photoUrl;
}

/// Vehicle summary on Tier B trip screens (doc 03 §5 TripView.vehicle).
class VehiclePreview {
  const VehiclePreview({
    required this.plateNumber,
    required this.color,
    required this.makeModel,
    required this.seatCapacity,
  });

  final String plateNumber;
  final String color;
  final String makeModel;
  final int seatCapacity;
}
