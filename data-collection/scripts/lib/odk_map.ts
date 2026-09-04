/**
 * Map raw ODK/Kobo submission JSON → field_submissions rows (doc 13 §2–3).
 */

import {
  entityKeyForLegFare,
  entityKeyForPark,
  entityKeyForRoute,
  entityKeyForStage,
  entityKeyForThroughFare,
  parseGeopoint,
  resolveParkSlug,
  slugifyName,
} from './entity_keys.ts';

export type FieldEntityType =
  | 'park'
  | 'route'
  | 'stage'
  | 'leg_fare'
  | 'through_fare';

export interface MappedSubmission {
  city_id: string;
  corridor_id?: string | null;
  scout_profile_id: string;
  form_id: string;
  form_version: string;
  submission_uid: string;
  payload: Record<string, unknown>;
  entity_type: FieldEntityType;
  entity_key: string;
  submitted_at: string;
  gpx_storage_path?: string | null;
}

/** Raw ODK Central / Kobo submission envelope. */
export interface OdkSubmission {
  __id?: string;
  meta?: { instanceID?: string; deviceid?: string };
  form_id?: string;
  form_version?: string;
  scout_id: string;
  corridor_id?: string;
  submitted_at?: string;
  end?: string;
  // park form
  park_name?: string;
  location?: string;
  aliases?: Array<{ alias?: string; 'alias/name'?: string }>;
  modes?: string;
  hours_from?: string;
  hours_to?: string;
  notes?: string;
  // route form
  mode?: string;
  origin_park?: string;
  origin_park_label?: string;
  destination_park?: string;
  destination_park_label?: string;
  stage?: Array<{
    stage_name?: string;
    location?: string;
    is_official_park?: string;
    price_to_end?: number | string;
    price_currency?: string;
  }>;
  through_fares?: Array<{
    from_stage_seq?: number | string;
    to_stage_seq?: number | string;
    fare?: number | string;
  }>;
  frequency_peak_per_hour?: number | string;
  frequency_offpeak_per_hour?: number | string;
  typical_wait_min?: number | string;
}

export interface MapContext {
  cityId: string;
  citySlug: string;
}

function submissionUid(raw: OdkSubmission, suffix = ''): string {
  const base = raw.__id ?? raw.meta?.instanceID ?? `generated-${Date.now()}`;
  return suffix ? `${base}:${suffix}` : base;
}

function submittedAt(raw: OdkSubmission): string {
  return raw.submitted_at ?? raw.end ?? new Date().toISOString();
}

function aliasList(raw: OdkSubmission): string[] {
  if (!raw.aliases?.length) return [];
  return raw.aliases
    .map((a) => a.alias ?? a['alias/name'] ?? '')
    .filter(Boolean);
}

export function mapParkSubmission(raw: OdkSubmission, ctx: MapContext): MappedSubmission {
  if (!raw.park_name || !raw.location) {
    throw new Error('Park submission requires park_name and location');
  }
  const { lat, lng } = parseGeopoint(raw.location);
  const formId = raw.form_id ?? 'along_park_v1';
  const formVersion = raw.form_version ?? '1';

  return {
    city_id: ctx.cityId,
    corridor_id: raw.corridor_id ?? null,
    scout_profile_id: raw.scout_id,
    form_id: formId,
    form_version: formVersion,
    submission_uid: submissionUid(raw),
    payload: {
      name: raw.park_name,
      lat,
      lng,
      name_aliases: aliasList(raw),
      modes: raw.modes?.split(/\s+/).filter(Boolean) ?? [],
      hours_from: raw.hours_from,
      hours_to: raw.hours_to,
      notes: raw.notes,
    },
    entity_type: 'park',
    entity_key: entityKeyForPark(ctx.citySlug, raw.park_name),
    submitted_at: submittedAt(raw),
  };
}

export function mapRouteSubmissions(raw: OdkSubmission, ctx: MapContext): MappedSubmission[] {
  if (!raw.mode || !raw.origin_park || !raw.destination_park || !raw.stage?.length) {
    throw new Error('Route submission requires mode, origin_park, destination_park, and stage group');
  }

  const formId = raw.form_id ?? 'along_route_v1';
  const formVersion = raw.form_version ?? '1';
  const originSlug = resolveParkSlug(raw.origin_park, raw.origin_park_label);
  const destSlug = resolveParkSlug(raw.destination_park, raw.destination_park_label);
  const routeKey = entityKeyForRoute(ctx.citySlug, originSlug, destSlug, raw.mode);
  const stageCount = raw.stage.length;
  const endSeq = stageCount;
  const base = submittedAt(raw);
  const rows: MappedSubmission[] = [];

  rows.push({
    city_id: ctx.cityId,
    corridor_id: raw.corridor_id ?? null,
    scout_profile_id: raw.scout_id,
    form_id: formId,
    form_version: formVersion,
    submission_uid: submissionUid(raw, 'route'),
    payload: {
      mode_code: raw.mode,
      origin_slug: originSlug,
      destination_slug: destSlug,
      corridor_id: raw.corridor_id,
      stage_count: stageCount,
      frequency_peak_per_hour: Number(raw.frequency_peak_per_hour ?? 0),
      frequency_offpeak_per_hour: Number(raw.frequency_offpeak_per_hour ?? 0),
      typical_wait_min: Number(raw.typical_wait_min ?? 0),
      notes: raw.notes,
    },
    entity_type: 'route',
    entity_key: routeKey,
    submitted_at: base,
  });

  raw.stage.forEach((st, idx) => {
    const seq = idx + 1;
    if (!st.location) {
      throw new Error(`Stage ${seq} missing location`);
    }
    const { lat, lng } = parseGeopoint(st.location);
    rows.push({
      city_id: ctx.cityId,
      corridor_id: raw.corridor_id ?? null,
      scout_profile_id: raw.scout_id,
      form_id: formId,
      form_version: formVersion,
      submission_uid: submissionUid(raw, `stage-${seq}`),
      payload: {
        route_entity_key: routeKey,
        sequence: seq,
        name: st.stage_name ?? `Stage ${seq}`,
        lat,
        lng,
        is_official_park: st.is_official_park === 'yes' || st.is_official_park === '1',
      },
      entity_type: 'stage',
      entity_key: entityKeyForStage(routeKey, seq),
      submitted_at: base,
    });

    if (st.price_to_end !== undefined && st.price_to_end !== '') {
      rows.push({
        city_id: ctx.cityId,
        corridor_id: raw.corridor_id ?? null,
        scout_profile_id: raw.scout_id,
        form_id: formId,
        form_version: formVersion,
        submission_uid: submissionUid(raw, `fare-${seq}-${endSeq}`),
        payload: {
          route_entity_key: routeKey,
          from_sequence: seq,
          to_sequence: endSeq,
          fare_amount: Number(st.price_to_end),
          fare_currency: st.price_currency ?? 'NGN',
        },
        entity_type: 'leg_fare',
        entity_key: entityKeyForLegFare(routeKey, seq, endSeq),
        submitted_at: base,
      });
    }
  });

  for (const tf of raw.through_fares ?? []) {
    const fromSeq = Number(tf.from_stage_seq);
    const toSeq = Number(tf.to_stage_seq);
    if (!fromSeq || !toSeq || tf.fare === undefined) continue;
    rows.push({
      city_id: ctx.cityId,
      corridor_id: raw.corridor_id ?? null,
      scout_profile_id: raw.scout_id,
      form_id: formId,
      form_version: formVersion,
      submission_uid: submissionUid(raw, `through-${fromSeq}-${toSeq}`),
      payload: {
        route_entity_key: routeKey,
        from_sequence: fromSeq,
        to_sequence: toSeq,
        fare_amount: Number(tf.fare),
        fare_currency: 'NGN',
      },
      entity_type: 'through_fare',
      entity_key: entityKeyForThroughFare(routeKey, fromSeq, toSeq),
      submitted_at: base,
    });
  }

  return rows;
}

export function mapOdkSubmission(raw: OdkSubmission, ctx: MapContext): MappedSubmission[] {
  const formId = raw.form_id ?? '';
  if (formId === 'along_park_v1' || raw.park_name) {
    return [mapParkSubmission(raw, ctx)];
  }
  if (formId === 'along_route_v1' || raw.stage) {
    return mapRouteSubmissions(raw, ctx);
  }
  throw new Error(`Unknown ODK form: ${formId || '(missing form_id)'}`);
}

/** Lookup city slug by id via preloaded map. */
export function citySlugFromMap(cityId: string, cities: Map<string, string>): string {
  const slug = cities.get(cityId);
  if (!slug) throw new Error(`Unknown city_id: ${cityId}`);
  return slug;
}

export { slugifyName };
