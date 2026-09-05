#!/usr/bin/env bash
# Expose local OSRM (backend/routing compose) via a short-lived cloudflared quick tunnel.
# Set the printed URL as the Supabase Edge Function secret OSRM_URL for the smoke session.
# Do not commit tunnel URLs — they rotate every run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_DIR="${ROOT}/backend/routing"
OSRM_PORT="${OSRM_PORT:-5000}"
PROJECT_REF="${SUPABASE_PROJECT_REF:-upqeypbdegteofwvekie}"

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "ERROR: cloudflared not installed. Install from https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/" >&2
  exit 1
fi

echo "Starting OSRM compose (if not already running)…"
(
  cd "${COMPOSE_DIR}"
  docker compose up -d osrm-car osrm-foot
)

echo ""
echo "Opening quick tunnel to http://127.0.0.1:${OSRM_PORT} …"
echo "When cloudflared prints a https://*.trycloudflare.com URL, set:"
echo "  npx supabase secrets set OSRM_URL=https://<host>.trycloudflare.com --project-ref ${PROJECT_REF}"
echo ""
echo "Edge Functions fall back to straight-line estimates when OSRM_URL is empty/unreachable (doc 01 §9)."
echo "Press Ctrl+C to stop the tunnel."
echo ""

cloudflared tunnel --url "http://127.0.0.1:${OSRM_PORT}"
