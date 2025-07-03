#!/usr/bin/env bash
set -euo pipefail

# Reset Supabase auth & profiles for clean test state.
# Requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env vars (load from .env.test)

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set" >&2
  exit 1
fi

# Truncate auth users (requires RPC defined in database)
curl -sS -X POST "$SUPABASE_URL/rest/v1/rpc/truncate_auth" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" | jq '.'

# Truncate public.profiles
curl -sS -X POST "$SUPABASE_URL/rest/v1/rpc/truncate_profiles" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" | jq '.'

echo "✅ Supabase test users reset." 