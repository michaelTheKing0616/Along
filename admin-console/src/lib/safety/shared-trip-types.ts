export interface SharedTripVehicle {
  plate: string;
  color: string;
}

export interface SharedTripLegProgress {
  sequence?: number;
  status?: string;
  label?: string;
}

export interface SharedTripEtaValue {
  kind: 'single' | 'range' | string;
  low_s: number;
  high_s: number;
  label: string;
}

export interface SharedTripEtaStop {
  id: string;
  name: string;
  state: 'passed' | 'current' | 'upcoming' | string;
  label: string;
}

export interface SharedTripEta {
  status: 'calculating' | 'ready' | string;
  pickup?: SharedTripEtaValue | null;
  trip?: SharedTripEtaValue | null;
  stops: SharedTripEtaStop[];
  updated_at: string;
}

export interface SharedTripViewPayload {
  rider_first_name: string;
  status: string;
  mode: { code: string; label: string };
  vehicle: SharedTripVehicle;
  driver_first_name: string;
  current_location: { lat: number; lng: number };
  destination_label: string;
  eta_s: number;
  eta?: SharedTripEta | null;
  legs_progress: SharedTripLegProgress[];
}
