#!/usr/bin/env bash
# supabase db lint, failing only on app-owned functions.
# postgis/pgtap live in `public`; their functions trip plpgsql_check false
# positives (pgtap temp tables, optional GDAL, legacy catalog columns) that we
# do not own. Those are excluded via pg_depend (extension members); every
# other error-level issue fails the job.
set -euo pipefail
DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
out="$(mktemp)"; ext="$(mktemp)"
supabase db lint --level error -o json >"$out" || true
psql "$DB_URL" -At -c "
  select n.nspname || '.' || p.proname
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  join pg_depend d on d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e'
" >"$ext"
python3 - "$out" "$ext" <<'PY'
import json, sys
raw = open(sys.argv[1]).read()
ext = set(l.strip() for l in open(sys.argv[2]) if l.strip())
i = raw.find('[')
items = json.loads(raw[i:]) if i >= 0 else []
bad, skipped = [], 0
for f in items:
    errs = [x for x in f.get('issues', []) if x.get('level') == 'error']
    if not errs:
        continue
    if f.get('function') in ext:
        skipped += 1
        continue
    bad += [(f.get('function'), x.get('message')) for x in errs]
print(f'db lint: {skipped} extension-owned function(s) skipped')
for fn, msg in bad:
    print(f'ERROR {fn}: {msg}')
sys.exit(1 if bad else 0)
PY
