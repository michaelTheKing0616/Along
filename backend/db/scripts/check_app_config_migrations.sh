#!/usr/bin/env bash
# ADR-0016 grep gate: no raw app_config inserts or do-update in migrations.
# Only top-level (column-0) statements run at migration time; indented inserts
# live inside admin RPC bodies, which write operator values at runtime by design.
# \b keeps app_config_keys (key registry, not values) out of scope.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MIG="$ROOT/backend/db/migrations"

if rg -n -i -U '^insert into app_config\b[^;]*do update' "$MIG"; then
  echo "FAIL: migration uses insert into app_config ... do update (ADR-0016)."
  exit 1
fi

violations=$(rg -l -i '^insert into app_config\b' "$MIG" | grep -v '00000000000002_geo_and_config.sql' || true)
if [ -n "$violations" ]; then
  echo "FAIL: raw insert into app_config outside config_default() helper in:"
  echo "$violations"
  exit 1
fi

echo "OK: app_config migrations comply with ADR-0016"
