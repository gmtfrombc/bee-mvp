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

EMAIL="gmtfrombc@gmail.com"

# Ensure required vars are present
: "${SUPABASE_PROJECT_REF:?Missing SUPABASE_PROJECT_REF in supabase.env}"  # project ref (e.g. okptsiz...)
: "${SUPABASE_DB_PASSWORD:?Missing SUPABASE_DB_PASSWORD in supabase.env}"   # DB password

# ─────────────────────────────────────────────────────────────────────────────
# 1) Compose SQL in a heredoc. A DO block lets us capture row counts and emit
#    clear NOTICE messages that the CLI will print to stdout.
# ─────────────────────────────────────────────────────────────────────────────
SQL=$(cat <<'SQLBLOCK'
DO
$$
DECLARE
    v_uid         uuid;
    v_action      integer := 0;
    v_onboarding  integer := 0;
    v_pes         integer := 0;
    v_profiles    integer := 0;
    v_auth        integer := 0;
BEGIN
    -- Find the auth UID for the hard-coded email
    SELECT id INTO v_uid FROM auth.users WHERE email = 'gmtfrombc@gmail.com' LIMIT 1;

    IF v_uid IS NULL THEN
        RAISE NOTICE 'User "%" not found – nothing to delete.', 'gmtfrombc@gmail.com';
        RETURN;
    END IF;

    -- Delete domain rows and record how many were removed
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
    RAISE NOTICE 'Deleted rows – action_steps: %, onboarding_responses: %, pes_entries: %, profiles: %, auth.users: %',
                 v_action, v_onboarding, v_pes, v_profiles, v_auth;
END
$$;
SQLBLOCK
)

# ─────────────────────────────────────────────────────────────────────────────
# 2) Execute SQL using Supabase CLI (single session)
# ─────────────────────────────────────────────────────────────────────────────
TMP_SQL_FILE=$(mktemp /tmp/reset_gmt_user.XXXXXX.sql)
trap 'rm -f "$TMP_SQL_FILE"' EXIT

echo "$SQL" > "$TMP_SQL_FILE"

# Execute the SQL using psql (works regardless of Supabase CLI version)
PGPASSWORD="$SUPABASE_DB_PASSWORD" \
psql "postgresql://postgres:$SUPABASE_DB_PASSWORD@db.$SUPABASE_PROJECT_REF.supabase.co:6543/postgres" \
  -f "$TMP_SQL_FILE" && \
  echo "✅  Reset script completed – check NOTICE messages above for row counts." 