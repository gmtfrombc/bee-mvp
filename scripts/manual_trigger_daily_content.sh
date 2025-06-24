#!/usr/bin/env bash
# Trigger the daily-content-generator Edge Function manually.
# Usage:
#   ./scripts/manual_trigger_daily_content.sh [project-ref] [json-body]
# If project-ref is omitted, the script uses $PROJECT_ID from ~/.bee_secrets/supabase.env.
# If json-body is omitted, an empty JSON object is sent.

# use 
#./scripts/manual_trigger_daily_content.sh "daily-content-generator" '{"content_date": "2025-06-22"}'

set -euo pipefail

# ---------------------------------------------------------------------------
# Load Supabase secrets (PROJECT_ID, SERVICE_ROLE_SECRET, etc.)
# ---------------------------------------------------------------------------
SECRETS_FILE="${HOME}/.bee_secrets/supabase.env"
if [[ -f "${SECRETS_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${SECRETS_FILE}"
else
  echo "❌ Secrets file ${SECRETS_FILE} not found." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Determine project ref & payload
# ---------------------------------------------------------------------------
PROJECT_REF="${1:-${PROJECT_ID:-}}"
BODY="${2:-{}}"
if [[ -z "${PROJECT_REF}" ]]; then
  echo "Usage: $0 <project-ref|omitted if PROJECT_ID set> [json-body]" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Prepare auth header (use service-role JWT automatically)
# ---------------------------------------------------------------------------
if [[ -z "${SERVICE_ROLE_SECRET:-}" ]]; then
  echo "❌ SERVICE_ROLE_SECRET missing in secrets file." >&2
  exit 1
fi
SERVICE_ROLE_JWT="${SERVICE_ROLE_JWT:-${SERVICE_ROLE_SECRET}}"

# ---------------------------------------------------------------------------
# Perform HTTPS POST
# ---------------------------------------------------------------------------
FUNCTION_URL="https://${PROJECT_REF}.supabase.co/functions/v1/daily-content-generator"

curl -i -X POST "${FUNCTION_URL}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_JWT}" \
  -H "Content-Type: application/json" \
  -d "${BODY}" | cat 