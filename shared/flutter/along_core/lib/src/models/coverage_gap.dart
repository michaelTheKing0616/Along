import 'package:along_core/src/models/geo_point.dart';

/// Nearest known stage when planner finds no mapped routes (R-18).
class NearestStage {
  const NearestStage({
    required this.stageId,
    required this.name,
    required this.location,
    required this.distanceM,
  });

  final String stageId;
  final String name;
  final GeoPoint location;
  final int distanceM;
}

/// Coverage gap payload from `plan-trip` when no candidates exist.
class CoverageGap {
  const CoverageGap({
    required this.reportId,
    required this.nearestStage,
    required this.ambientVehicleCount,
  });

  final String reportId;
  final NearestStage nearestStage;
  final int ambientVehicleCount;
}
