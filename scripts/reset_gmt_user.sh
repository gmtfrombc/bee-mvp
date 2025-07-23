#!/usr/bin/env bash
# Purpose: wipe all data for the hard-coded test account (gmtfrombc@gmail.com)
# Usage   : ./scripts/reset_gmt_user.sh
# Requires: supabase CLI and ~/.bee_secrets/supabase.env with project + DB creds

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# 0) Load Supabase credentials (PROJECT_REF and DB password)
# ─────────────────────────────────────────────────────────────────────────────
set -a
source ~/.bee_secrets/supabase.env
set +a

# Allow overriding the target email via CLI arg; default to Graeme's test account.
# Usage: ./scripts/reset_gmt_user.sh [email]
EMAIL="${1:-gmtfrombc@gmail.com}"

# Ensure required vars are present
: "${SUPABASE_PROJECT_REF:?Missing SUPABASE_PROJECT_REF in supabase.env}"  # project ref (e.g. okptsiz...)
: "${SUPABASE_DB_PASSWORD:?Missing SUPABASE_DB_PASSWORD in supabase.env}"   # DB password

# ─────────────────────────────────────────────────────────────────────────────
# 1) Compose SQL in a heredoc. A DO block lets us capture row counts and emit
#    clear NOTICE messages that the CLI will print to stdout.
# ─────────────────────────────────────────────────────────────────────────────
SQL=$(cat <<SQLBLOCK
DO
\$\$
DECLARE
    v_uid         uuid;
    v_action      integer := 0;
    v_onboarding  integer := 0;
    v_pes         integer := 0;
    v_profiles    integer := 0;
    v_auth        integer := 0;
    v_logs        integer := 0;
BEGIN
    -- Find the auth UID for the provided email
    SELECT id INTO v_uid FROM auth.users WHERE email = '${EMAIL}' LIMIT 1;

    IF v_uid IS NULL THEN
        RAISE NOTICE 'User "%" not found – nothing to delete.', 'gmtfrombc@gmail.com';
        RETURN;
    END IF;

    -- Action Step logs must be deleted before the parent Action Step
    DELETE FROM public.action_step_logs
      WHERE action_step_id IN (SELECT id FROM public.action_steps WHERE user_id = v_uid);
    GET DIAGNOSTICS v_logs = ROW_COUNT;

    DELETE FROM public.action_steps         WHERE user_id = v_uid;
    GET DIAGNOSTICS v_action = ROW_COUNT;

    DELETE FROM public.onboarding_responses WHERE user_id = v_uid;
    GET DIAGNOSTICS v_onboarding = ROW_COUNT;

    DELETE FROM public.pes_entries          WHERE user_id = v_uid;
    GET DIAGNOSTICS v_pes = ROW_COUNT;

    DELETE FROM public.profiles             WHERE id      = v_uid;
    GET DIAGNOSTICS v_profiles = ROW_COUNT;

    -- Delete the Auth user last
    DELETE FROM auth.users                  WHERE id      = v_uid;
    GET DIAGNOSTICS v_auth = ROW_COUNT;

    -- Summary output
    RAISE NOTICE 'Deleted rows – action_steps: %, logs: %, onboarding_responses: %, pes_entries: %, profiles: %, auth.users: %',
                 v_action, v_logs, v_onboarding, v_pes, v_profiles, v_auth;
END
\$\$;
SQLBLOCK
)

# ─────────────────────────────────────────────────────────────────────────────
# 2) Execute SQL using Supabase CLI (single session)
# ─────────────────────────────────────────────────────────────────────────────
TMP_SQL_FILE=$(mktemp /tmp/reset_gmt_user.XXXXXX.sql)
trap 'rm -f "$TMP_SQL_FILE"' EXIT

echo "$SQL" > "$TMP_SQL_FILE"

# Execute the SQL using psql (works regardless of Supabase CLI version)
if PGPASSWORD="$SUPABASE_DB_PASSWORD" \
psql "postgresql://postgres:$SUPABASE_DB_PASSWORD@db.$SUPABASE_PROJECT_REF.supabase.co:6543/postgres" \
  -f "$TMP_SQL_FILE" ; then
  echo "✅  Reset script completed – check NOTICE messages above for row counts."
else
  echo "⚠️  Direct DB connection failed – falling back to Supabase Admin API over HTTPS..."

  API_URL="https://$SUPABASE_PROJECT_REF.supabase.co"
  AUTH_HDR=( -H "apikey: $SERVICE_ROLE_SECRET" -H "Authorization: Bearer $SERVICE_ROLE_SECRET" -H "Content-Type: application/json" )

  # 1) Lookup the user ID via Admin API
  USER_JSON=$(curl -s "${AUTH_HDR[@]}" "$API_URL/auth/v1/admin/users?email=eq.$EMAIL")
  USER_ID=$(echo "$USER_JSON" | grep -oE '"id":"[^\"]+' | head -1 | cut -d':' -f2 | tr -d '"')

  if [ -z "$USER_ID" ]; then
    echo "User $EMAIL not found – nothing to delete."
    exit 0
  fi

  # 2) Delete domain rows via PostgREST endpoints
  curl -s -X DELETE "${AUTH_HDR[@]}" "$API_URL/rest/v1/action_steps?user_id=eq.$USER_ID" >/dev/null
  curl -s -X DELETE "${AUTH_HDR[@]}" "$API_URL/rest/v1/onboarding_responses?user_id=eq.$USER_ID" >/dev/null
  curl -s -X DELETE "${AUTH_HDR[@]}" "$API_URL/rest/v1/pes_entries?user_id=eq.$USER_ID" >/dev/null
  curl -s -X DELETE "${AUTH_HDR[@]}" "$API_URL/rest/v1/profiles?id=eq.$USER_ID" >/dev/null

  # 3) Delete the Auth user record
  curl -s -X DELETE "${AUTH_HDR[@]}" "$API_URL/auth/v1/admin/users/$USER_ID" >/dev/null

  echo "✅  Reset completed via Admin API."
fi 