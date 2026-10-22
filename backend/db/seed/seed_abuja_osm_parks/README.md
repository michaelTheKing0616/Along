# seed_abuja_osm_parks

OSM-sourced park/terminal **candidates** for Abuja (FCT), from Overpass.

- License: ODbL 1.0 (© OpenStreetMap contributors)
- Status: `candidate` (not field_verified)
- Apply after `seed_abuja_pilot`
- Refresh: re-run Overpass (see `scripts/fetch_fct_osm_parks.sh` if present) and regenerate `00_osm_parks.sql`

```bash
# via apply_seeds helper (if wired)
DATABASE_URL=... backend/db/scripts/apply_seeds.sh abuja-osm

# or
npx supabase db query --linked -f backend/db/seed/seed_abuja_osm_parks/00_osm_parks.sql
```
