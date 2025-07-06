#!/usr/bin/env bash
# check_supabase_password_policy.sh — Fails CI if the project's Auth password policy is weaker than specified.
# Requirements:
# • SUPABASE_ACCESS_TOKEN – Personal Access Token with project admin scope (set in CI secrets)
# • SUPABASE_URL          – Project base URL, e.g. https://abcd.supabase.co (set in CI secrets)
#
# The script fetches Auth settings via Supabase Management API and verifies:
#   1. password_min_length  >= 8
#   2. password_require_special_char == true
#
# If either condition fails, the script exits with status 1 so the CI job will fail.
set -euo pipefail

REQUIRED_MIN_LENGTH=8
REQUIRED_CHAR="symbols"

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" || -z "${SUPABASE_URL:-}" ]]; then
  echo "⚠️  SUPABASE_ACCESS_TOKEN or SUPABASE_URL not set — skipping password-policy check."
  exit 0
fi

# Extract project REF from the base URL (<ref>.supabase.co)
PROJECT_REF=$(echo "$SUPABASE_URL" | sed -E 's~https?://([^.]+)\.supabase\.co/?~\1~')
if [[ -z "$PROJECT_REF" ]]; then
  echo "❌ Unable to determine project ref from SUPABASE_URL=$SUPABASE_URL"
  exit 1
fi

API="https://api.supabase.com/v1/projects/${PROJECT_REF}/auth/config"

# Fetch auth config (jq is required)
if ! command -v jq &> /dev/null; then
  echo "📦 Installing jq (missing on runner)…"
  sudo apt-get update -y -qq >/dev/null
  sudo apt-get install -y -qq jq >/dev/null
fi

CONFIG=$(curl -s -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" "$API")

MIN_LENGTH=$(echo "$CONFIG" | jq -r '.password_min_length // 0')
# Ensure numeric; fallback to 0 when not a number
if ! [[ "$MIN_LENGTH" =~ ^[0-9]+$ ]]; then
  MIN_LENGTH=0
fi

# Fetch required characters setting (string like "symbols", "numbers", etc.)
REQUIRED_SETTING=$(echo "$CONFIG" | jq -r '.password_required_characters // ""')

echo "🔍 Supabase password_min_length=$MIN_LENGTH password_required_characters=$REQUIRED_SETTING"

if (( MIN_LENGTH < REQUIRED_MIN_LENGTH )) || [[ "$REQUIRED_SETTING" != "$REQUIRED_CHAR" ]]; then
  echo "❌ Password policy does not meet the required criteria (min length $REQUIRED_MIN_LENGTH & symbol required)."
  exit 1
fi

echo "✅ Password policy meets requirements." 