export type CorrectionStatus = 'pending' | 'approved' | 'rejected';

export interface FareCorrectionQueueRow {
  id: string;
  status: CorrectionStatus;
  created_at: string;
  proposed_fare: number;
  current_fare: number | null;
  fare_shown: number | null;
  currency: string;
  delta_pct: number | null;
  submitter_role: string;
  submitter_trust: number | null;
  submitter_label: string;
  trip_id: string | null;
  is_mad_outlier: boolean;
  is_negotiation: boolean;
  route_label: string | null;
  stage_from: string | null;
  stage_to: string | null;
  target_type: string | null;
  target_id: string | null;
}
