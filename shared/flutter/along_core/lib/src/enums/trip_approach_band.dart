/// Pre-accept coarse pickup band (FM42 — no exact distance pre-accept).
enum TripApproachBand {
  under2,
  m2_5,
  over5;

  static TripApproachBand? tryParse(String? raw) {
    if (raw == null) return null;
    return switch (raw) {
      'under_2' => TripApproachBand.under2,
      'm2_5' => TripApproachBand.m2_5,
      'over_5' => TripApproachBand.over5,
      _ => null,
    };
  }

  String get wireValue => switch (this) {
        TripApproachBand.under2 => 'under_2',
        TripApproachBand.m2_5 => 'm2_5',
        TripApproachBand.over5 => 'over_5',
      };
}
