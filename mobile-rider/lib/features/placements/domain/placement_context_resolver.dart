import 'package:along_data/along_data.dart';

PlacementContext? placementContextFromPlan({
  PlacementContext? sessionContext,
  String? recommendedAlightStageId,
  String? corridorId,
}) {
  if (sessionContext != null) return sessionContext;
  if (recommendedAlightStageId != null && recommendedAlightStageId.isNotEmpty) {
    return PlacementContext(
      type: PlacementContextType.destination,
      targetReference: recommendedAlightStageId,
    );
  }
  if (corridorId != null && corridorId.isNotEmpty) {
    return PlacementContext(
      type: PlacementContextType.corridor,
      targetReference: corridorId,
    );
  }
  return null;
}
