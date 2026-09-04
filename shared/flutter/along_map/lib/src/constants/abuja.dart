/// Abuja pilot corridor map constants (doc 13 §5, P0-E-04 seed).
abstract final class AbujaMapConstants {
  /// Central Business District area — default map center.
  static const centerLat = 9.0765;
  static const centerLng = 7.3986;
  static const defaultZoom = 12.0;

  /// Small fixture bbox covering CBD + Nyanya corridor (~20 km clip).
  static const fixtureMinLat = 9.00;
  static const fixtureMinLng = 7.35;
  static const fixtureMaxLat = 9.20;
  static const fixtureMaxLng = 7.55;
}
