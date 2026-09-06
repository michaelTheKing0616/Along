export type Point = { lat: number; lng: number };

export type LoadFilter = {
  flagged: boolean;
  size?: 'small' | 'medium' | 'large';
};

export type PlanTripFilters = {
  women_only: boolean;
  load: LoadFilter;
  modes?: string[] | null;
};

export type Money = { amount: string; currency: string };

export type FareComponent = {
  kind: string;
  amount: Money;
  label: string;
  ref_id?: string;
};

export type Fare = {
  total: Money;
  tier: number;
  confidence: number;
  unconfirmed: boolean;
  components: FareComponent[];
  quote_id: string;
  expires_at: string;
};

export type ModeRef = {
  code: string;
  label: string;
  icon_key: string;
  color_token: string;
};

export type Metrics = {
  total_fare: Money;
  total_time_s: number;
  in_vehicle_s: number;
  wait_s: number;
  walk_s: number;
  transfer_count: number;
  total_walking_distance_m: number;
  strenuousness_score: number;
  recommended_score: number;
  explain: Record<string, number>;
};

export type PlanCandidateLeg = {
  leg_index: number;
  mode: ModeRef;
  board: Record<string, unknown>;
  alight: Record<string, unknown>;
  route_id: string | null;
  route_leg_ids: string[];
  in_vehicle_s: number;
  wait_s: number;
  fare: Fare;
  supply: Record<string, unknown>;
  load_warning?: { reason: string; mode_capacity: string } | null;
};

export type PlanCandidate = {
  candidate_id: string;
  kind: 'direct' | 'multi_leg';
  source: 'parked' | 'roaming' | 'driver_profile' | 'graph';
  viable_direct: boolean;
  legs: PlanCandidateLeg[];
  transfers: Record<string, unknown>[];
  metrics: Metrics;
};

export type SortOrders = {
  recommended: string[];
  cheapest: string[];
  fastest: string[];
  least_strenuous: string[];
};

export type PlannerCfg = {
  maxCandidates: number;
  walkSpeedMps: number;
  sharedVehicleFactor: number;
  defaultWaitS: number;
  directViabilityFactor: number;
  directViabilitySlackS: number;
  baselineSpeedMps: number;
  speedProfileMinSamples: number;
  recommendedWeights: { fare: number; time: number; strenuous: number };
  strenuousWeights: { transfer: number; walk_per_100m: number; mode: number };
  warnCapacities: Record<string, string[]>;
};

export type RawDirectCandidate = {
  source: string;
  route_id: string | null;
  profile_id: string | null;
  board_stage_id: string;
  alight_stage_id: string;
  mode_code: string;
  route_leg_ids: string[];
  segment_keys?: string[];
  in_vehicle_time_estimate_s: number;
  avg_wait_time_estimate_s: number;
  supply: Record<string, unknown>;
};

export type StageRow = {
  id: string;
  name: string;
  lat: number;
  lng: number;
};

export type ModeRow = ModeRef & {
  comfort_weight: number;
  load_capacity: string;
  default_dwell_s: number;
};

export type PlaceResult = {
  kind: 'park' | 'stage' | 'place';
  id?: string;
  name: string;
  area: string;
  location: Point;
  distance_m: number;
};

export type WalkingStep = {
  instruction: string;
  distance_m: number;
  bearing: number;
  maneuver: string;
  geometry: Point[];
};

export type PlacesCfg = {
  searchRadiusM: number;
  trigramMinSimilarity: number;
  photonTimeoutMs: number;
};
