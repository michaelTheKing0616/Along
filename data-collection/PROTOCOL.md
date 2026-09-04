# Along field scout protocol

Spec: blueprint doc 13 §1. Payment triggers on `reconciled`, not raw submission.

## Two-scout verification

1. **Two independent scouts** cover each corridor on **different days**, without sharing notes.
2. A **third scout** resolves discrepancies beyond tolerance (location, fare, stage count, name).
3. Scouts are paid per verified entity when reconciliation reaches `matched` or admin `resolved`.

## Per park

Collect:

| Field | Requirement |
|---|---|
| Name | As locals say it; capture aliases in repeat group |
| GPS | ≥ 30 s averaging; accuracy ≤ 10 m |
| Photo | Signage or landmark (optional but encouraged) |
| Modes | All modes present at the park (`select_multiple` from synced `mode_config`) |
| Hours | Typical operating window |
| Corridor | From synced `corridors` list |

Form: `forms/along_park_v1.xlsx` (`along_park_v1`).

## Per route (per mode)

Collect:

| Field | Requirement |
|---|---|
| Origin / destination | From synced parks list or mark as new (admin resolves before publish) |
| Stages | Ordered repeat: local name, GPS, official-park flag |
| Fares | **Quoted standard** price from each stage to route end — not haggled price; note haggle range in notes |
| Through-fares | Optional repeat for known non-sum pairs |
| Frequency | Vehicles/hour peak and off-peak |
| Wait | Typical wait at origin (minutes) |
| GPX | One full ride trace (uploaded to `field/{city}/{submission}.gpx` on ingest) |

Form: `forms/along_route_v1.xlsx` (`along_route_v1`).

## Before fieldwork

1. Run `pnpm --filter @along/data-collection export:choices` against the target environment DB.
2. Run `pnpm --filter @along/data-collection build:forms` to refresh XLSForms with current corridor/park/mode ids.
3. Deploy forms to ODK Central or Kobo; verify `scout_id` hidden/default matches each scout's `profiles.id`.

## After field day

Run ingestion (service-role credentials required):

```bash
export SUPABASE_URL=https://<project>.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=<service-role-key>

# From Kobo export
pnpm --filter @along/data-collection ingest -- --city-id <city-uuid> --kobo-asset <asset-uid>

# From local fixture (dev/CI)
pnpm --filter @along/data-collection ingest -- --city-id <city-uuid> --fixture fixtures/park_matched_pair.json
```

Ingestion:

1. Inserts raw payload into `field_submissions`.
2. Derives deterministic `entity_key` (doc 13 §3 step 2).
3. Calls `reconcile_field_submission` — first scout → `awaiting_second`; second → variance + `matched`/`discrepant`.
4. Admin publishes matched rows via `admin_publish_field_entity` (P0-A-07).

## Tolerance (from `app_config`)

| Key | Default | Applies to |
|---|---|---|
| `field.location_tol_m` | 50 m | GPS between scouts |
| `field.fare_tol_pct` | 0.15 (15%) | Leg / through fare amounts |

## Do not

- Share scout notes or compare GPS fixes in the field before both submissions are in.
- Record haggled fares as the standard fare.
- Edit submissions after upload — file a new submission or admin resolution instead.
