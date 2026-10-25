#!/usr/bin/env bash
# Deploy Edge Functions one slug at a time so staging-only functions never ship
# to production. Use this instead of a bare `supabase functions deploy`, which
# deploys every directory, staging-otp included.
#
#   bash backend/functions/scripts/deploy_functions.sh [--dry-run] <staging|prod> <project-ref>
set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then DRY_RUN=1; shift; fi
TARGET="${1:-}"
REF="${2:-}"
case "$TARGET" in staging|prod) ;; *) echo "usage: $0 [--dry-run] <staging|prod> <project-ref>" >&2; exit 2 ;; esac
[ -n "$REF" ] || { echo "project ref required" >&2; exit 2; }

# Functions that must exist only on staging.
STAGING_ONLY=(staging-otp)

FN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mapfile -t SLUGS < <(cd "$FN_DIR" && find . -name index.ts -not -path './_shared/*' -not -path './scripts/*' \
  | sed 's#^\./##; s#/index\.ts$##' | sort)

for slug in "${SLUGS[@]}"; do
  if [ "$TARGET" != staging ] && printf '%s\n' "${STAGING_ONLY[@]}" | grep -qx "$slug"; then
    echo "skip (staging-only): $slug"
    continue
  fi
  echo "deploy: $slug"
  if [ "$DRY_RUN" = 0 ]; then
    flags=()
    case "$slug" in webhooks/*|send-sms) flags+=(--no-verify-jwt) ;; esac
    supabase functions deploy "$slug" --project-ref "$REF" "${flags[@]}"
  fi
done
