export type TraceActorType = 'driver' | 'rider';

export type TraceSample = {
  lng: number;
  lat: number;
  ts: Date;
  accuracyM: number | null;
};

export type MatchedTraceRecord = {
  tripId: string;
  actorType: TraceActorType;
  confidence: number;
  geometryGeoJson: GeoJsonLineString;
  osmWayIds: number[];
  matchMeta: Record<string, unknown>;
};

export type GeoJsonLineString = {
  type: 'LineString';
  coordinates: [number, number][];
};

export type OsrmMatchResult = {
  confidence: number;
  geometry: GeoJsonLineString;
  osmWayIds: number[];
  matchMeta: Record<string, unknown>;
  degraded: boolean;
};

export type MapMatchJobConfig = {
  minSamples: number;
  minConfidence: number;
  osrmBaseUrl: string;
  osrmTimeoutMs: number;
  defaultRadiusM: number;
};

export type PendingTraceMatch = {
  tripId: string;
  cityId: string;
  actorType: TraceActorType;
  sampleCount: number;
};

export type TraceProposalKind = 'geometry_correction' | 'route_inference';

export type TraceProposal = {
  kind: TraceProposalKind;
  tripId: string;
  actorType: TraceActorType;
};
