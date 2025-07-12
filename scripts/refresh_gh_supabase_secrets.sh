#!/usr/bin/env bash
# refresh_gh_supabase_secrets.sh — sync local Supabase credentials to GitHub Actions secrets
# -----------------------------------------------------------------------------
# Usage: ./scripts/refresh_gh_supabase_secrets.sh [owner/repo]
#
# Reads the developer’s local `~/.bee_secrets/supabase.env` (or path specified
# in $SUPABASE_ENV_FILE) and updates the corresponding GitHub repository
# secrets via the `gh` CLI.  Only the *length* of each secret is printed so no
# sensitive data is exposed.
# -----------------------------------------------------------------------------
set -euo pipefail

REPO="${1:-gmtfrombc/bee-mvp}"
ENV_FILE="${SUPABASE_ENV_FILE:-$HOME/.bee_secrets/supabase.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Supabase env file not found: $ENV_FILE" >&2
  exit 1
fi

# Keys we sync. Adjust as needed.
KEYS=(
  SUPABASE_ACCESS_TOKEN
  SUPABASE_PROJECT_REF
  SUPABASE_URL
  SUPABASE_DB_PASSWORD
  SUPABASE_SERVICE_ROLE_SECRET
)

echo "🔑  Refreshing GitHub secrets in $REPO from $ENV_FILE …"

for KEY in "${KEYS[@]}"; do
  VAL=$(grep -E "^${KEY}=" "$ENV_FILE" | head -n1 | cut -d= -f2- | tr -d '\r\n' || true)
  LEN=${#VAL}
  printf "• %-28s length=%d\n" "$KEY" "$LEN"
  if [[ -z "$VAL" ]]; then
    echo "  ⚠️   Skipped — no local value"
    continue
  fi
  gh secret set "$KEY" --repo "$REPO" --body "$VAL" >/dev/null
  echo "  ✅  Updated"
  sleep 1 # avoid hitting secondary rate limits
done

echo "✅ All available Supabase secrets refreshed." 