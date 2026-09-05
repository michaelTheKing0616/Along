/// Load flag on a trip request (FM35 — visible to driver pre-accept).
class TripLoadInfo {
  const TripLoadInfo({
    required this.flagged,
    this.size,
    this.note,
  });

  final bool flagged;
  final String? size;
  final String? note;
}
