import 'package:along_core/src/models/geo_point.dart';

/// One OSRM foot step from `walking-directions`.
class WalkingStep {
  const WalkingStep({
    required this.instruction,
    required this.distanceM,
    this.maneuver,
    this.bearing,
  });

  final String instruction;
  final int distanceM;
  final String? maneuver;
  final double? bearing;
}

/// Walking route payload from `walking-directions` Edge function.
class WalkingDirections {
  const WalkingDirections({
    required this.distanceM,
    required this.durationS,
    required this.steps,
    required this.polyline,
    this.ttsScript = const [],
    this.degraded = false,
  });

  final int distanceM;
  final int durationS;
  final List<WalkingStep> steps;
  final List<GeoPoint> polyline;
  final List<String> ttsScript;
  final bool degraded;
}
