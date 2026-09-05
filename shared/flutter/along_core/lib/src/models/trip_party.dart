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
