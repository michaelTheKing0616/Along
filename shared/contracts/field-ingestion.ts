/**
 * Field ingestion contract (doc 13 §3, doc 02 §14).
 * Consumed by data-collection/scripts/ingest.ts (P0-E-03).
 */

export type FieldEntityType =
  | 'park'
  | 'route'
  | 'stage'
  | 'leg_fare'
  | 'through_fare';

export type FieldSubmissionStatus =
  | 'received'
  | 'reconciled'
  | 'published'
  | 'rejected';

export type FieldReconciliationStatus =
  | 'awaiting_second'
  | 'matched'
  | 'discrepant'
  | 'resolved'
  | 'rejected';

/** Raw ODK/Kobo row before DB insert. */
export interface FieldSubmissionInsert {
  city_id: string;
  corridor_id?: string | null;
  scout_profile_id: string;
  form_id: string;
  form_version: string;
  submission_uid: string;
  payload: FieldSubmissionPayload;
  gpx_storage_path?: string | null;
  entity_type: FieldEntityType;
  entity_key: string;
  submitted_at: string;
}

export type FieldSubmissionPayload =
  | FieldParkPayload
  | FieldRoutePayload
  | FieldStagePayload
  | FieldLegFarePayload
  | FieldThroughFarePayload;

export interface FieldParkPayload {
  name: string;
  lat: number;
  lng: number;
  name_aliases?: string[];
}

export interface FieldRoutePayload {
  mode_code: string;
  origin_slug: string;
  destination_slug: string;
  name?: string;
  corridor_id?: string;
  stage_count?: number;
  /** Optional GPX-derived path as [lng, lat][] */
  path?: [number, number][];
}

export interface FieldStagePayload {
  route_entity_key: string;
  sequence: number;
  name?: string;
  lat: number;
  lng: number;
  is_official_park?: boolean;
}

export interface FieldLegFarePayload {
  route_entity_key: string;
  from_sequence: number;
  to_sequence: number;
  fare_amount: number;
  fare_currency?: string;
}

export interface FieldThroughFarePayload {
  route_entity_key: string;
  from_sequence: number;
  to_sequence: number;
  fare_amount: number;
  fare_currency?: string;
}

/** Variance object stored on field_reconciliations.variance (doc 13 §3). */
export interface FieldVariance {
  location_m?: number;
  fare_pct?: number;
  stage_count_diff?: number;
  name_similarity?: number;
  within_tolerance?: boolean;
}

export interface FieldPublishResult {
  target_type: FieldEntityType | 'park';
  target_id: string;
  source_id: string;
}

/** Slug helper — mirrors ingest.ts entity_key derivation (doc 13 §3 step 2). */
export function slugifyName(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

export function entityKeyForPark(citySlug: string, parkName: string): string {
  return `park:${citySlug}:${slugifyName(parkName)}`;
}

export function entityKeyForRoute(
  citySlug: string,
  originSlug: string,
  destinationSlug: string,
  modeCode: string
): string {
  return `route:${citySlug}:${originSlug}-${destinationSlug}:${modeCode}`;
}

export function entityKeyForStage(routeEntityKey: string, sequence: number): string {
  return `${routeEntityKey}:stage:${sequence}`;
}

export function entityKeyForLegFare(
  routeEntityKey: string,
  fromSequence: number,
  toSequence: number
): string {
  return `${routeEntityKey}:fare:${fromSequence}-${toSequence}`;
}

export function entityKeyForThroughFare(
  routeEntityKey: string,
  fromSequence: number,
  toSequence: number
): string {
  return `${routeEntityKey}:through_fare:${fromSequence}-${toSequence}`;
}

/** RPC names for PostgREST / Supabase client (doc 03 §11). */
export const FIELD_RPC = {
  reconcileSubmission: 'reconcile_field_submission',
  adminReconcile: 'admin_reconcile_field_entity',
  adminPublish: 'admin_publish_field_entity',
} as const;

/** Config keys read by compute_field_variance / ingest (doc 02 §2.3). */
export const FIELD_CONFIG_KEYS = {
  locationTolM: 'field.location_tol_m',
  fareTolPct: 'field.fare_tol_pct',
} as const;
