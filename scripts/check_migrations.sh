#!/usr/bin/env bash
# scripts/check_migrations.sh
# -------------------------------------------------------------
# Validate Supabase migrations *only* when DB-relevant files
# are part of the current commit. This keeps the fast path
# snappy for UI-only changes while surfacing SQL issues early.
# -------------------------------------------------------------
set -euo pipefail

# Paths that should trigger a DB reset when modified.
PATTERN='^(supabase/migrations/|supabase/functions/|tests/db/|docs/.*\.sql$)'

# Gather staged paths (pre-commit) or pushed paths (pre-push)
CHANGED_FILES=$(git diff --cached --name-only)

if echo "$CHANGED_FILES" | grep -Eq "$PATTERN"; then
  echo "🛂  DB-related changes detected – validating migrations …"

  # Start (or reuse) a lightweight Postgres and export DB_HOST / DB_PORT
  eval $(bash scripts/start_test_db.sh)

  # Attempt to apply all migrations with Supabase CLI
  if ! supabase db reset --local --no-seed --debug >/tmp/migration_check.log 2>&1; then
    cat /tmp/migration_check.log
    echo "❌  Migration reset failed. Fix SQL errors before committing."
    exit 1
  fi
  echo "✅  Migrations apply cleanly."
fi

exit 0 