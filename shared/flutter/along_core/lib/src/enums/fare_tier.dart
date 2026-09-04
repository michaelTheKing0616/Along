/// Fare resolution tier (0 = driver profile, 1–3 = graph tiers).
enum FareTier {
  driverProfile(0),
  throughFare(1),
  summedLegs(2),
  unconfirmed(3);

  const FareTier(this.value);

  final int value;

  static FareTier fromInt(int value) => FareTier.values.firstWhere(
        (t) => t.value == value,
        orElse: () => throw ArgumentError('Unknown fare tier: $value'),
      );
}
