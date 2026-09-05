import 'package:along_core/src/enums/sort_criterion.dart';
import 'package:along_core/src/models/candidate.dart';
import 'package:along_core/src/models/coverage_gap.dart';

/// Planner response with sort orders keyed by criterion.
class PlanResult {
  const PlanResult({
    required this.queryId,
    required this.cityId,
    required this.degraded,
    required this.candidates,
    required this.sortOrders,
    this.coverageGap,
  });

  final String queryId;
  final String cityId;
  final bool degraded;
  final List<PlanCandidate> candidates;
  final Map<SortCriterion, List<String>> sortOrders;
  final CoverageGap? coverageGap;

  List<PlanCandidate> sortedBy(SortCriterion criterion) {
    final order = sortOrders[criterion];
    if (order == null || order.isEmpty) return List.of(candidates);
    final byId = {for (final c in candidates) c.candidateId: c};
    return order
        .map((id) => byId[id])
        .whereType<PlanCandidate>()
        .toList();
  }
}
