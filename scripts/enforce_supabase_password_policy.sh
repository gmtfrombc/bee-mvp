#!/usr/bin/env bash
# enforce_supabase_password_policy.sh — Ensures the Supabase Auth password policy is at least
#   • minimum length 8
#   • requires symbols
# If the current policy is weaker, the script PATCHes the Management API to update it.
# The script is idempotent and exits 0 on success.
#
# Required env vars:
#   SUPABASE_ACCESS_TOKEN – Personal access token with project admin scope
#   SUPABASE_URL          – Project URL, e.g. https://abcd.supabase.co
set -euo pipefail

REQUIRED_MIN_LENGTH=8
REQUIRED_SYMBOLS="symbols"  # Supabase requires string literal

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" || -z "${SUPABASE_URL:-}" ]]; then
  echo "⚠️  SUPABASE_ACCESS_TOKEN or SUPABASE_URL not set — cannot enforce password policy. Exiting 1." >&2
  exit 1
fi

# Derive project ref from the base URL (<ref>.supabase.co)
PROJECT_REF=$(echo "$SUPABASE_URL" | sed -E 's~https?://([^.]+)\.supabase\.co/?~\1~')
if [[ -z "$PROJECT_REF" ]]; then
  echo "❌ Unable to determine project ref from SUPABASE_URL=$SUPABASE_URL" >&2
  exit 1
fi

# NOTE: Management API path is /config/auth (not /auth/config)
API="https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth"

CONFIG=$(curl -s -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" "$API")

CUR_MIN_LENGTH=$(echo "$CONFIG" | jq -r '.password_min_length // 0')
CUR_REQUIRED_CHARS=$(echo "$CONFIG" | jq -r '.password_required_characters // ""')

NEED_PATCH=false
if (( CUR_MIN_LENGTH < REQUIRED_MIN_LENGTH )); then
  NEED_PATCH=true
fi
if [[ "$CUR_REQUIRED_CHARS" != "$REQUIRED_SYMBOLS" ]]; then
  NEED_PATCH=true
fi

echo "🔍 Current policy: min_length=$CUR_MIN_LENGTH required_characters=$CUR_REQUIRED_CHARS"

if [[ "$NEED_PATCH" == "true" ]]; then
  echo "⚙️  Updating password policy to min_length=$REQUIRED_MIN_LENGTH, required_characters=$REQUIRED_SYMBOLS…"
  # --argjson expects a raw JSON value (number here), so we must NOT quote the variable
  PATCH_PAYLOAD=$(jq -n --argjson len ${REQUIRED_MIN_LENGTH} --arg req "$REQUIRED_SYMBOLS" '{password_min_length:$len,password_required_characters:$req}')
  if ! curl -fsS -X PATCH "$API" \
      -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "$PATCH_PAYLOAD" >/dev/null; then
    echo "❌ Failed to PATCH password policy via Management API" >&2
    exit 1
  fi

  # Poll the API (max 5 × 2s) until the policy reflects the new values
  for i in {1..5}; do
    sleep 2
    CONFIG=$(curl -s -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" "$API")
    CUR_MIN_LENGTH=$(echo "$CONFIG" | jq -r '.password_min_length // 0')
    CUR_REQUIRED_CHARS=$(echo "$CONFIG" | jq -r '.password_required_characters // ""')
    if (( CUR_MIN_LENGTH >= REQUIRED_MIN_LENGTH )) && [[ "$CUR_REQUIRED_CHARS" == "$REQUIRED_SYMBOLS" ]]; then
      echo "✅ Policy verified after update."
      break
    fi
    if [[ $i -eq 5 ]]; then
      echo "❌ Password policy still not updated after retries (min_length=$CUR_MIN_LENGTH, required_characters=$CUR_REQUIRED_CHARS)" >&2
      exit 1
    fi
  done
  # If we get here, policy has been updated.
else
  echo "✅ Policy already meets requirements."
fi

exit 0 