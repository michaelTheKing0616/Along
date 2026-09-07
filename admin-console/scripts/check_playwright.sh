#!/usr/bin/env bash
# Playwright E2E gate (doc 09 §2, P0-D-01).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ADMIN="$ROOT/admin-console"
CONFIG="$ADMIN/playwright.config.mjs"

if [ ! -f "$CONFIG" ]; then
  echo "FAIL: admin-console/playwright.config.mjs is missing."
  exit 1
fi

if ! grep -q '"@playwright/test"' "$ADMIN/package.json" 2>/dev/null; then
  echo "FAIL: @playwright/test is not listed in admin-console/package.json."
  exit 1
fi

if ! command -v supabase >/dev/null 2>&1; then
  if [ -f "$ROOT/node_modules/.bin/supabase" ]; then
    export PATH="$ROOT/node_modules/.bin:$PATH"
  else
    echo "FAIL: supabase CLI not found."
    exit 1
  fi
fi

cd "$ROOT"

if ! supabase status >/dev/null 2>&1; then
  echo "Starting local Supabase stack..."
  supabase start
else
  echo "Restarting Supabase to apply auth config..."
  supabase stop
  supabase start
fi

echo "Resetting database with migrations and core seed..."
supabase db reset --yes

DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
echo "Seeding Abuja city for E2E routes..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ROOT/backend/db/seed/seed_abuja_pilot/00_city_and_corridors.sql"
echo "Seeding E2E admin users..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ADMIN/e2e/seed-e2e-admins.sql"
echo "Seeding E2E field reconciliation queue..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ADMIN/e2e/seed-field-reconciliation.sql"
echo "Seeding E2E verification queue..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ADMIN/e2e/seed-verification-queue.sql"
echo "Seeding E2E fare corrections queue..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ADMIN/e2e/seed-fare-corrections.sql"
echo "Seeding E2E finance dual-control fixture..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ADMIN/e2e/seed-finance-dual-control.sql"
echo "Seeding E2E agent settlement fixture..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ADMIN/e2e/seed-agent-settlement.sql"
echo "Seeding E2E W-04 pay fixture..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ADMIN/e2e/seed-w04-pay.sql"
echo "Seeding E2E safety board fixture..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ADMIN/e2e/seed-safety-board.sql"
chmod +x "$ADMIN/e2e/seed-verification-storage.sh"
"$ADMIN/e2e/seed-verification-storage.sh"

echo "Reloading PostgREST schema cache..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "NOTIFY pgrst, 'reload schema';"
sleep 2

LOCAL_SUPABASE_URL="http://127.0.0.1:54321"
LOCAL_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
echo "Verifying resolve_qr_driver RPC via PostgREST..."
RPC_OK=0
for _ in $(seq 1 15); do
  if curl -sf "${LOCAL_SUPABASE_URL}/rest/v1/rpc/resolve_qr_driver" \
    -H "apikey: ${LOCAL_ANON_KEY}" \
    -H "Authorization: Bearer ${LOCAL_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"p_driver_code":"W04TEST1"}' \
    | grep -q '"first_name"'; then
    RPC_OK=1
    break
  fi
  sleep 1
done
if [ "$RPC_OK" -ne 1 ]; then
  echo "FAIL: resolve_qr_driver not available in PostgREST schema cache after reload."
  exit 1
fi
echo "PostgREST resolve_qr_driver RPC OK."

echo "Running Playwright E2E..."
cd "$ADMIN"
if [ -f "$ADMIN/.env.local" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$ADMIN/.env.local"
  set +a
fi
# E2E always targets local Supabase (overrides .env.local remote project).
export NEXT_PUBLIC_SUPABASE_URL="$LOCAL_SUPABASE_URL"
export NEXT_PUBLIC_SUPABASE_ANON_KEY="$LOCAL_ANON_KEY"
export DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
pnpm build
pnpm test:e2e:setup

if lsof -ti:3000 >/dev/null 2>&1; then
  echo "Stopping existing process on port 3000 before E2E server start..."
  lsof -ti:3000 | xargs kill -9 2>/dev/null || true
  sleep 1
fi

NODE_BIN=""
if [ -x "$ADMIN/.tools/node-v22.15.0-darwin-arm64/bin/node" ]; then
  NODE_BIN="$ADMIN/.tools/node-v22.15.0-darwin-arm64/bin/node"
elif command -v node >/dev/null 2>&1 && node -e 'process.exit(Number(process.version.match(/^v(\\d+)/)?.[1] < 23))' 2>/dev/null; then
  NODE_BIN="node"
fi

if [ -z "$NODE_BIN" ]; then
  echo "Installing Node 22.15.0 to admin-console/.tools for Playwright (ADR-0013 pin)..."
  mkdir -p "$ADMIN/.tools"
  ARCH="$(uname -m)"
  case "$ARCH" in
    arm64) NODE_ARCH="darwin-arm64" ;;
    x86_64) NODE_ARCH="darwin-x64" ;;
    *) echo "FAIL: unsupported arch $ARCH for bundled Node 22."; exit 1 ;;
  esac
  curl -fsSL "https://nodejs.org/dist/v22.15.0/node-v22.15.0-${NODE_ARCH}.tar.gz" \
    | tar -xz -C "$ADMIN/.tools"
  NODE_BIN="$ADMIN/.tools/node-v22.15.0-${NODE_ARCH}/bin/node"
fi

pnpm start &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true' EXIT
for _ in $(seq 1 30); do
  if curl -sf http://127.0.0.1:3000/sign-in >/dev/null; then
    break
  fi
  sleep 1
done

"$NODE_BIN" ./node_modules/@playwright/test/cli.js test --config=playwright.config.mjs

echo "PASS: Playwright E2E completed."
