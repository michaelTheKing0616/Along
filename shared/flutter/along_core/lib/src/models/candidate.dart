import 'package:along_core/src/enums/transport_mode.dart';
import 'package:along_core/src/models/fare_quote.dart';
import 'package:along_core/src/models/load_warning.dart';
import 'package:along_core/src/models/plan_metrics.dart';

/// A single leg within a planner candidate.
class PlanCandidateLeg {
  const PlanCandidateLeg({
    required this.legIndex,
    required this.mode,
    required this.boardName,
    required this.alightName,
    required this.walkMeters,
    required this.walkSeconds,
    required this.inVehicleSeconds,
    required this.waitSeconds,
    required this.fare,
    this.loadWarning,
    this.alightStageId,
  });

  final int legIndex;
  final TransportMode mode;
  final String boardName;
  final String alightName;
  final int walkMeters;
  final int walkSeconds;
  final int inVehicleSeconds;
  final int waitSeconds;
  final FareQuote fare;
  final LoadWarning? loadWarning;
  final String? alightStageId;
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
    this.metrics,
    this.transfers = const [],
  });

  final String candidateId;
  final String kind;
  final String source;
  final bool viableDirect;
  final List<PlanCandidateLeg> legs;
  final int totalFareMinorUnits;
  final int totalTimeSeconds;
  final int transferCount;
  final PlanMetrics? metrics;
  final List<PlanTransfer> transfers;

  bool get isDirect => kind == 'direct';
  bool get isMultiLeg => kind == 'multi_leg';
}
