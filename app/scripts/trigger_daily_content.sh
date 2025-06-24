#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# trigger_daily_content.sh – Manually invoke the daily-content-generator Edge
# Function.
#
# USAGE:
#   ./trigger_daily_content.sh [--date YYYY-MM-DD] [--force] [--project <ref>]
#
# FLAGS:
#   --date      Target content_date. Defaults to today in UTC.
#   --force     Pass force_regenerate=true to overwrite existing entry.
#   --project   Supabase project ref (e.g. okptsizouuanwnpqjfui). If omitted the
#               script attempts to read it from ./../../supabase/.temp/project-ref
#               or the PROJECT_REF environment variable.
#
# ENV:
#   SERVICE_ROLE_JWT  (optional) If set, an Authorization header will be included.
#
# EXAMPLE:
#   ./trigger_daily_content.sh --date 2025-06-21 --force
# ---------------------------------------------------------------------------
set -euo pipefail

# Defaults
TARGET_DATE="$(date -u +%F)"   # today in UTC
FORCE_PAYLOAD="false"
PROJECT_REF="${PROJECT_REF:-}"

# Helper: print usage
usage() {
  grep -E "^#" "$0" | cut -c 4-
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --date)
      TARGET_DATE="$2"; shift 2;;
    --force)
      FORCE_PAYLOAD="true"; shift;;
    --project)
      PROJECT_REF="$2"; shift 2;;
    -h|--help)
      usage;;
    *)
      echo "Unknown option: $1" >&2; usage;;
  esac
done

# Resolve project ref if still empty
if [[ -z "$PROJECT_REF" ]]; then
  if [[ -f "$(dirname "$0")/../../supabase/.temp/project-ref" ]]; then
    PROJECT_REF="$(cat $(dirname "$0")/../../supabase/.temp/project-ref | tr -d '\n')"
  else
    echo "❌ Project ref not provided and could not be auto-detected." >&2
    usage
  fi
fi

# Build JSON body (avoid jq dependency)
JSON_BODY="{\"target_date\":\"${TARGET_DATE}\",\"force_regenerate\":${FORCE_PAYLOAD}}"

# Prepare curl
URL="https://${PROJECT_REF}.supabase.co/functions/v1/daily-content-generator"
HEADERS=( -H "Content-Type: application/json" )
if [[ -n "${SERVICE_ROLE_JWT:-}" ]]; then
  HEADERS+=( -H "Authorization: Bearer ${SERVICE_ROLE_JWT}" )
fi

echo "🛰️  POST $URL"
echo "📦 Body: $JSON_BODY"
# shellcheck disable=SC2068
curl --fail -sS -X POST "$URL" ${HEADERS[@]} -d "$JSON_BODY" | jq -r '.' 