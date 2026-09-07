/// Post-accept walking wait state (Tier B, doc 03 §5).
class TripWaitInfo {
  const TripWaitInfo({
    required this.walkEtaS,
    required this.approach,
    required this.updatedAt,
  });

  final int walkEtaS;
  final TripWaitApproach approach;
  final DateTime updatedAt;

  int get walkEtaMinutes => (walkEtaS / 60).ceil().clamp(1, 999);
}

enum TripWaitApproach {
  approaching,
  stalled,
  unknown;

  static TripWaitApproach? tryParse(String? raw) {
    if (raw == null) return null;
    return switch (raw) {
      'approaching' => TripWaitApproach.approaching,
      'stalled' => TripWaitApproach.stalled,
      'unknown' => TripWaitApproach.unknown,
      _ => null,
    };
  }
}
