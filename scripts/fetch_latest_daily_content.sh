#!/usr/bin/env bash
# Fetch the most-recent active daily_feed_content row and print as JSON.
# Usage: ./scripts/fetch_latest_daily_content.sh [project-ref]
# If project-ref is omitted, $PROJECT_ID from ~/.bee_secrets/supabase.env is used.
# Example:
#   ./scripts/fetch_latest_daily_content.sh          # uses $PROJECT_ID
#   ./scripts/fetch_latest_daily_content.sh okptsizouuanwnpqjfui

set -euo pipefail

SECRETS_FILE="${HOME}/.bee_secrets/supabase.env"
if [[ -f "${SECRETS_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${SECRETS_FILE}"
else
  echo "❌ Secrets file ${SECRETS_FILE} not found." >&2
  exit 1
fi

PROJECT_REF="${1:-${PROJECT_ID:-}}"
if [[ -z "${PROJECT_REF}" ]]; then
  echo "Usage: $0 <project-ref|omitted if PROJECT_ID set>" >&2
  exit 1
fi

if [[ -z "${SERVICE_ROLE_SECRET:-}" ]]; then
  echo "❌ SERVICE_ROLE_SECRET missing in secrets file." >&2
  exit 1
fi

BASE_URL="https://${PROJECT_REF}.supabase.co/rest/v1"
HEADERS=(
  -H "apikey: ${SERVICE_ROLE_SECRET}"
  -H "Authorization: Bearer ${SERVICE_ROLE_SECRET}"
  -H "Content-Type: application/json"
)

curl -s "${HEADERS[@]}" "${BASE_URL}/daily_feed_content_current?select=*" | jq 