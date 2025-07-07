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

# Define literal sets accepted by Supabase Management API (source: API error response)
LETTERS_SET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
ALPHANUMERIC_SET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
# Note: use backslash to escape literal backslash and backtick inside double quotes
FULL_SYMBOL_SET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{};'\\\":|<>?,./\`~"

# Map human-friendly requirement labels → exact literal sets expected by Management API
#   symbols        -> $FULL_SYMBOL_SET
#   letters        -> $LETTERS_SET
#   alphanumeric   -> $ALPHANUMERIC_SET
#   none           -> none
HUMAN_REQUIRED="symbols"
case "$HUMAN_REQUIRED" in
  symbols)        REQUIRED_ENUM="$FULL_SYMBOL_SET" ;;
  letters)        REQUIRED_ENUM="$LETTERS_SET" ;;
  alphanumeric|letters_numbers)
                  REQUIRED_ENUM="$ALPHANUMERIC_SET" ;;
  numbers)        REQUIRED_ENUM="0123456789" ;;
  none|"")      REQUIRED_ENUM="none" ;;
  *)              REQUIRED_ENUM="$HUMAN_REQUIRED" ;;
esac

echo "🔧 Resolved human label '$HUMAN_REQUIRED' → literal set: $REQUIRED_ENUM"

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
if [[ "$CUR_REQUIRED_CHARS" != "$REQUIRED_ENUM" ]]; then
  NEED_PATCH=true
fi

echo "🔍 Current policy: min_length=$CUR_MIN_LENGTH required_characters=$CUR_REQUIRED_CHARS (desired=$REQUIRED_ENUM)"

if [[ "$NEED_PATCH" == "true" ]]; then
  echo "⚙️  Updating password policy to min_length=$REQUIRED_MIN_LENGTH, required_characters=$REQUIRED_ENUM…"
  # --argjson expects a raw JSON value (number here), so we must NOT quote the variable
  PATCH_PAYLOAD=$(jq -n --argjson len ${REQUIRED_MIN_LENGTH} --arg req "$REQUIRED_ENUM" '{password_min_length:$len,password_required_characters:$req}')

  echo "🔗 PATCH payload:" >&2
  echo "$PATCH_PAYLOAD" | jq . >&2
  echo "🔗 curl -X PATCH $API -d '$PATCH_PAYLOAD'" >&2

  # Perform PATCH and capture both body and status code for debugging
  HTTP_RESPONSE=$(curl -sS -w "\n%{http_code}" -X PATCH "$API" \
    -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$PATCH_PAYLOAD")

  # Split response and status
  HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
  HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n1)

  if [[ $HTTP_STATUS -ge 200 && $HTTP_STATUS -lt 300 ]]; then
    echo "✅ PATCH request succeeded (status $HTTP_STATUS)"
  else
    echo "❌ PATCH request failed with status $HTTP_STATUS" >&2
    echo "Response body:" >&2
    echo "$HTTP_BODY" | jq . >&2 || echo "$HTTP_BODY" >&2
    exit 1
  fi

  # Poll the API (max 5 × 2s) until the policy reflects the new values
  for i in {1..5}; do
    sleep 2
    CONFIG=$(curl -s -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" "$API")
    CUR_MIN_LENGTH=$(echo "$CONFIG" | jq -r '.password_min_length // 0')
    CUR_REQUIRED_CHARS=$(echo "$CONFIG" | jq -r '.password_required_characters // ""')
    if (( CUR_MIN_LENGTH >= REQUIRED_MIN_LENGTH )) && [[ "$CUR_REQUIRED_CHARS" == "$REQUIRED_ENUM" ]]; then
      echo "✅ Policy verified after update."
      break
    fi
    if [[ $i -eq 5 ]]; then
      echo "❌ Password policy still not updated after retries (min_length=$CUR_MIN_LENGTH, required_characters=$CUR_REQUIRED_CHARS, expected=$REQUIRED_ENUM)" >&2
      exit 1
    fi
  done
  # If we get here, policy has been updated.
else
  echo "✅ Policy already meets requirements."
fi

exit 0 