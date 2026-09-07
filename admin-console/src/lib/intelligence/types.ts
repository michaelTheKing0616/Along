export type IntelligenceTab = 'parks' | 'routes' | 'geometry';

export type CandidateParkRow = {
  id: string;
  status: 'new' | 'promoted_to_stage' | 'dismissed';
  distinct_driver_count: number;
  distinct_day_count: number;
  sample_count: number;
  first_seen: string;
  last_seen: string;
  lat: number;
  lng: number;
  reviewed_at: string | null;
};

export type RouteInferenceRow = {
  id: string;
  status: 'new' | 'promoted_to_route' | 'dismissed';
  mode_code: string | null;
  supporting_trip_count: number;
  created_at: string;
  origin_lat: number | null;
  origin_lng: number | null;
  destination_lat: number | null;
  destination_lng: number | null;
  route_id: string | null;
  reviewed_at: string | null;
};

export type GeometryCorrectionRow = {
  id: string;
  status: 'candidate' | 'internal_applied' | 'reviewed_for_osm' | 'submitted_osm' | 'rejected';
  supporting_trace_count: number;
  created_at: string;
  reviewed_at: string | null;
};
