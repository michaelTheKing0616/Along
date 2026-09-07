export type GraphVerificationStatus =
  | 'field_verified'
  | 'crowd_verified'
  | 'candidate'
  | 'estimate';

export type PresenceStatus = 'at_park' | 'roaming_available' | 'roaming_full';

export type LiveMapLayerId =
  | 'routes'
  | 'parks'
  | 'stages'
  | 'presence'
  | 'trips'
  | 'sos'
  | 'coverageGaps';

export type LiveMapLayerVisibility = Record<LiveMapLayerId, boolean>;

export type LiveMapPark = {
  id: string;
  name: string;
  lat: number;
  lng: number;
  verification_status: GraphVerificationStatus;
};

export type LiveMapStage = {
  id: string;
  route_id: string;
  name: string | null;
  lat: number;
  lng: number;
  verification_status: GraphVerificationStatus;
  is_official_park: boolean;
  sequence: number;
};

export type LiveMapRoute = {
  id: string;
  mode_code: string;
  verification_status: GraphVerificationStatus;
  coordinates: [number, number][];
};

export type LiveMapCoverageGap = {
  id: string;
  lat: number;
  lng: number;
  ambient_vehicle_count: number;
  nearest_known_stage_distance_m: number | null;
  searched_at: string;
};

export type LiveMapSos = {
  id: string;
  trip_id: string | null;
  status: string;
  lat: number;
  lng: number;
  age_s: number;
  raiser_name: string | null;
  rider_name: string | null;
  driver_name: string | null;
  vehicle_plate: string | null;
};

export type LiveMapPresenceVehicle = {
  driver_id: string;
  lat: number;
  lng: number;
  heading: number | null;
  speed_mps: number;
  status: PresenceStatus;
  mode: string;
  plate: string;
  seats_available: number;
};

export type LiveMapActiveTrip = {
  trip_id: string;
  status: string;
  na_me_color: string;
  na_me_shape: string;
  rider_id: string;
  driver_id: string | null;
  rider_name: string | null;
  driver_name: string | null;
  plate: string | null;
  rider: { lat: number; lng: number } | null;
  driver: { lat: number; lng: number } | null;
};

export type LiveMapStaticPayload = {
  parks: LiveMapPark[];
  stages: LiveMapStage[];
  routes: LiveMapRoute[];
  coverageGaps: LiveMapCoverageGap[];
  sos: LiveMapSos[];
};

export type LiveMapSelection =
  | { kind: 'presence'; driverId: string }
  | { kind: 'trip'; tripId: string }
  | { kind: 'sos'; sosId: string }
  | { kind: 'park'; parkId: string }
  | { kind: 'stage'; stageId: string }
  | null;
