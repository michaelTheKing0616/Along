export type FieldSubmissionPayload = {
  name?: string;
  lat?: number;
  lng?: number;
  name_aliases?: string[];
  fare_amount?: number;
  [key: string]: unknown;
};

export type FieldSubmissionSummary = {
  id: string;
  payload: FieldSubmissionPayload;
  scout_profile_id: string;
  submitted_at: string;
  status: string;
};

export type FieldVariance = {
  location_m?: number;
  fare_pct?: number;
  name_similarity?: number;
  within_tolerance?: boolean;
};

export type FieldReconciliationRow = {
  id: string;
  entity_type: string;
  entity_key: string;
  status: string;
  variance: FieldVariance | null;
  published_target_type: string | null;
  published_target_id: string | null;
  resolution: { payload?: FieldSubmissionPayload } | null;
  sub_a: FieldSubmissionSummary | null;
  sub_b: FieldSubmissionSummary | null;
};
