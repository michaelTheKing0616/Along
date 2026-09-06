import 'package:along_core/src/models/geo_point.dart';
import 'package:along_core/src/models/walking_directions.dart';

/// Next leg snapshot from a journey `plan_snapshot` leg row.
class JourneyPlanLeg {
  const JourneyPlanLeg({
    required this.legIndex,
    required this.modeCode,
    required this.modeLabel,
    required this.boardName,
    required this.alightName,
    this.boardLocation,
    this.waitSeconds,
    this.supplyBucket,
  });

  final int legIndex;
  final String modeCode;
  final String modeLabel;
  final String boardName;
  final String alightName;
  final GeoPoint? boardLocation;
  final int? waitSeconds;
  final String? supplyBucket;
}

/// R-14 transfer screen payload — walk to next leg boarding point.
class TransferContext {
  const TransferContext({
    required this.journeyId,
    required this.afterTripSequence,
    required this.walkHeroLabel,
    required this.nextLeg,
    this.walkDirections,
    this.cityId,
  });

  final String journeyId;
  final int afterTripSequence;
  final String walkHeroLabel;
  final JourneyPlanLeg nextLeg;
  final WalkingDirections? walkDirections;
  final String? cityId;
}
