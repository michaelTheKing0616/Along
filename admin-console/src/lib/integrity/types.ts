export type FlagStatus = 'open' | 'cleared' | 'actioned';

export type FlagType =
  | 'premature_conversion'
  | 'undeclared_extension'
  | 'route_deviation'
  | 'profile_price_mismatch';

export interface IntegrityFlagRow {
  id: string;
  trip_id: string;
  driver_id: string;
  driver_name: string | null;
  driver_code: string | null;
  flag_type: FlagType;
  score: number;
  evidence: Record<string, unknown>;
  rider_trace_quality: string;
  corroborating_rider_count: number;
  status: FlagStatus;
  created_at: string;
  risk_cancel_rate: number | null;
  risk_open_flags: number | null;
}

export const STANDING_OPTIONS = [
  { value: 'guarantor_referred', label: 'Guarantor referred' },
  { value: 'deactivated', label: 'Deactivated' },
  { value: 'good_standing', label: 'Good standing (restore)' },
] as const;
