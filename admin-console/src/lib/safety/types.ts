export type SosStatus = 'open' | 'acknowledged' | 'resolved' | 'false_alarm';
export type IncidentStatus = 'open' | 'triaged' | 'resolved' | 'dismissed';
export type IncidentType =
  | 'safety'
  | 'fare_dispute'
  | 'vehicle_quality'
  | 'driver_behavior'
  | 'rider_behavior'
  | 'lost_item'
  | 'other';

export type SlaTier = 'normal' | 'warning' | 'critical';

export type SosBoardRow = {
  id: string;
  trip_id: string | null;
  journey_id: string | null;
  raised_by: string;
  raised_role: string;
  raiser_name: string | null;
  status: SosStatus;
  created_at: string;
  acknowledged_at: string | null;
  age_s: number;
  lat: number | null;
  lng: number | null;
  accuracy_m: number | null;
  trip_status: string | null;
  rider_name: string | null;
  driver_name: string | null;
  vehicle_plate: string | null;
  destination_label: string | null;
  /** True when raise_sos minted a trip share. The token itself is not stored. */
  share_issued: boolean;
};

export type IncidentQueueRow = {
  id: string;
  trip_id: string | null;
  type: IncidentType;
  severity: number;
  status: IncidentStatus;
  description: string | null;
  reported_by: string;
  reporter_name: string | null;
  reported_role: string;
  reported_at: string;
  assigned_to: string | null;
};

export type SafetySlaConfig = {
  ackSlaS: number;
  escalateSlaS: number;
};

export type AdminAssignee = {
  id: string;
  role: string;
  display_name: string | null;
};
