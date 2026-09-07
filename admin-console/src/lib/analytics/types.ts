export type CorridorAnalyticsSummary = {
  searches: number;
  ambient_views: number;
  commits: number;
  ambient_to_commit_rate: number | null;
  ambient_to_commit_diagnostic: boolean;
  requests: number;
  accept_rate: number | null;
  completed_trips: number;
  fulfilment_rate: number | null;
  median_wait_s: number;
  fare_discrepancy_rate: number | null;
  avg_candidates_per_search: number;
  avg_direct_candidates: number;
  coverage_gap_count: number;
};

export type CorridorAnalyticsSeriesRow = {
  bucket_start: string;
  bucket_end: string;
  searches: number;
  ambient_views: number;
  commits: number;
  ambient_to_commit_rate: number | null;
  requests: number;
  completed_trips: number;
};

export type CoverageGapRow = {
  id: string;
  searched_at: string;
  nearest_stage_id: string | null;
  nearest_stage_name: string | null;
  nearest_stage_distance_m: number | null;
  ambient_vehicle_count: number;
  location: { lat: number; lng: number };
};

export type CorridorAnalyticsResponse = {
  corridor_id: string;
  corridor_name: string;
  city_id: string;
  from: string;
  to: string;
  summary: CorridorAnalyticsSummary;
  series: CorridorAnalyticsSeriesRow[];
  coverage_gaps: CoverageGapRow[];
  meta: {
    next_cursor: string | null;
    page_size: number;
    bucket_interval_s: number;
    diagnostic_only: boolean;
  };
};

export type OpsDashboardCounts = {
  openSos: number;
  openFlags: number;
  verificationQueue: number;
  driversOnline: number;
  driversAtPark: number;
  driversRoaming: number;
};

export type CorridorOption = {
  id: string;
  name: string;
  slug: string;
};

export type OpsDashboardKpis = CorridorAnalyticsSummary & {
  corridors: number;
};
