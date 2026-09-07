export interface SharedTripVehicle {
  plate: string;
  color: string;
}

export interface SharedTripLegProgress {
  sequence?: number;
  status?: string;
  label?: string;
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
  legs_progress: SharedTripLegProgress[];
}
