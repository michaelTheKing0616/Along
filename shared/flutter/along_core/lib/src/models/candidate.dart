import 'package:along_core/src/enums/transport_mode.dart';
import 'package:along_core/src/models/fare_quote.dart';
import 'package:along_core/src/models/geo_point.dart';

/// A single leg within a planner candidate.
class PlanCandidateLeg {
  const PlanCandidateLeg({
    required this.legIndex,
    required this.mode,
    required this.boardName,
    required this.alightName,
    required this.inVehicleSeconds,
    required this.waitSeconds,
    required this.fare,
  });

  final int legIndex;
  final TransportMode mode;
  final String boardName;
  final String alightName;
  final int inVehicleSeconds;
  final int waitSeconds;
  final FareQuote fare;
}

/// Planner option returned from `plan-trip`.
class PlanCandidate {
  const PlanCandidate({
    required this.candidateId,
    required this.kind,
    required this.source,
    required this.viableDirect,
    required this.legs,
    required this.totalFareMinorUnits,
    required this.totalTimeSeconds,
    required this.transferCount,
  });

  final String candidateId;
  final String kind;
  final String source;
  final bool viableDirect;
  final List<PlanCandidateLeg> legs;
  final int totalFareMinorUnits;
  final int totalTimeSeconds;
  final int transferCount;

  bool get isDirect => kind == 'direct';
  bool get isMultiLeg => kind == 'multi_leg';
}
