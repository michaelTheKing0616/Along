/** Format a 0–1 rate as a percentage string for display-only KPI tiles (FM13). */
export function formatRate(rate: number | null | undefined, digits = 1): string {
  if (rate == null || Number.isNaN(rate)) return '—';
  return `${(rate * 100).toFixed(digits)}%`;
}

export function formatCount(value: number | null | undefined): string {
  if (value == null || Number.isNaN(value)) return '—';
  return value.toLocaleString('en-NG');
}

export function formatSeconds(value: number | null | undefined): string {
  if (value == null || Number.isNaN(value)) return '—';
  if (value < 60) return `${Math.round(value)}s`;
  const mins = Math.round(value / 60);
  return `${mins} min`;
}

export function aggregateSummaries(
  summaries: Array<{ summary: import('./types').CorridorAnalyticsSummary }>
): import('./types').CorridorAnalyticsSummary {
  if (summaries.length === 0) {
    return {
      searches: 0,
      ambient_views: 0,
      commits: 0,
      ambient_to_commit_rate: null,
      ambient_to_commit_diagnostic: true,
      requests: 0,
      accept_rate: null,
      completed_trips: 0,
      fulfilment_rate: null,
      median_wait_s: 0,
      fare_discrepancy_rate: null,
      avg_candidates_per_search: 0,
      avg_direct_candidates: 0,
      coverage_gap_count: 0,
    };
  }

  const totals = summaries.reduce(
    (acc, row) => {
      const s = row.summary;
      acc.searches += s.searches;
      acc.ambient_views += s.ambient_views;
      acc.commits += s.commits;
      acc.requests += s.requests;
      acc.accepts += Math.round((s.accept_rate ?? 0) * s.requests);
      acc.completed_trips += s.completed_trips;
      acc.coverage_gap_count += s.coverage_gap_count;
      acc.candidate_sum += s.avg_candidates_per_search * s.searches;
      acc.direct_sum += s.avg_direct_candidates * s.searches;
      if (s.fare_discrepancy_rate != null && s.completed_trips > 0) {
        acc.discrepancy_weighted += s.fare_discrepancy_rate * s.completed_trips;
        acc.discrepancy_trips += s.completed_trips;
      }
      if (s.median_wait_s > 0) {
        acc.wait_samples.push(s.median_wait_s);
      }
      return acc;
    },
    {
      searches: 0,
      ambient_views: 0,
      commits: 0,
      requests: 0,
      accepts: 0,
      completed_trips: 0,
      coverage_gap_count: 0,
      candidate_sum: 0,
      direct_sum: 0,
      discrepancy_weighted: 0,
      discrepancy_trips: 0,
      wait_samples: [] as number[],
    }
  );

  const waitSorted = [...totals.wait_samples].sort((a, b) => a - b);
  const medianWait =
    waitSorted.length === 0
      ? 0
      : waitSorted.length % 2 === 1
        ? waitSorted[(waitSorted.length - 1) / 2]
        : (waitSorted[waitSorted.length / 2 - 1] + waitSorted[waitSorted.length / 2]) / 2;

  return {
    searches: totals.searches,
    ambient_views: totals.ambient_views,
    commits: totals.commits,
    ambient_to_commit_rate:
      totals.ambient_views > 0 ? totals.commits / totals.ambient_views : null,
    ambient_to_commit_diagnostic: true,
    requests: totals.requests,
    accept_rate: totals.requests > 0 ? totals.accepts / totals.requests : null,
    completed_trips: totals.completed_trips,
    fulfilment_rate:
      totals.accepts > 0 ? totals.completed_trips / totals.accepts : null,
    median_wait_s: medianWait,
    fare_discrepancy_rate:
      totals.discrepancy_trips > 0 ? totals.discrepancy_weighted / totals.discrepancy_trips : null,
    avg_candidates_per_search:
      totals.searches > 0 ? totals.candidate_sum / totals.searches : 0,
    avg_direct_candidates:
      totals.searches > 0 ? totals.direct_sum / totals.searches : 0,
    coverage_gap_count: totals.coverage_gap_count,
  };
}

/** Guardrail copy — conversion is ops review signal, never an automatic action trigger. */
export const CONVERSION_DIAGNOSTIC_NOTE =
  'Ambient→commit is a diagnostic signal for ops review. It does not trigger driver or rider consequences.';
