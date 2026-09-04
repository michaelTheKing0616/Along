import 'package:along_core/along_core.dart';

/// A filtered GPS sample ready for publish or display.
class LocationSample {
  const LocationSample({
    required this.point,
    required this.accuracyM,
    required this.recordedAt,
    this.headingDegrees,
    this.speedMps,
  });

  final GeoPoint point;
  final double accuracyM;
  final DateTime recordedAt;
  final double? headingDegrees;
  final double? speedMps;

  bool get isDisplayQuality => accuracyM <= 500;
  bool get isBoardingQuality => accuracyM <= 50;
}
