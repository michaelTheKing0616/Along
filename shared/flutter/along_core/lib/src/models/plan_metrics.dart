/// Ranking explain breakdown attached to planner candidates (§4.2.2).
class PlanExplain {
  const PlanExplain({
    required this.fare,
    required this.time,
    required this.strenuous,
  });

  final double fare;
  final double time;
  final double strenuous;
}

/// Planner metrics on every candidate returned from `plan-trip`.
class PlanMetrics {
  const PlanMetrics({
    required this.totalWalkingDistanceM,
    required this.strenuousnessScore,
    required this.recommendedScore,
    required this.explain,
  });

  final int totalWalkingDistanceM;
  final double strenuousnessScore;
  final double recommendedScore;
  final PlanExplain explain;
}

/// Transfer point between legs on a multi-leg candidate.
class PlanTransfer {
  const PlanTransfer({
    required this.parkName,
    required this.walkMeters,
    required this.transferSeconds,
  });

  final String parkName;
  final int walkMeters;
  final int transferSeconds;
}
