#!/usr/bin/env bash

# run_ci_locally.sh ― mirror GitHub Actions CI with `act`
# ------------------------------------------------------
# Usage: ./scripts/run_ci_locally.sh [additional act args]
#
# This script wraps `act` so local runs are as close as possible to the
# real GitHub Actions environment.  It automatically:
#   • Ensures a `.secrets` file exists (stubbed when missing)
#   • Maps `ubuntu-latest` to an image that matches GitHubʼs 24.04 runner
#   • Forces ACT=false so **all** steps guarded with `if: ${{ env.ACT != 'true' }}` run
#   • Preserves any extra CLI flags you pass through ($@)
# ------------------------------------------------------
set -euo pipefail

WORKFLOW_FILE=".github/workflows/ci.yml"
SECRETS_FILE=".secrets"

# 1️⃣  Ensure secrets file exists (with blank values if not provided)
if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "🔐  Creating blank $SECRETS_FILE – populate with real values as needed"
  cat <<'EOF' > "$SECRETS_FILE"
SUPABASE_ACCESS_TOKEN=
SUPABASE_SERVICE_ROLE_SECRET=
SUPABASE_URL=
SUPABASE_PROJECT_REF=
SUPABASE_DB_PASSWORD=
# Optional Google Cloud creds for Terraform (base64 SA JSON)
GCP_SA_KEY=
# Optional extras for other CI workflows
GCS_BUCKET=
SUPABASE_PROJECT_ID=
EOF
fi

# 1️⃣🚀  Auto-populate secrets from local Supabase env file (optional)
DEFAULT_SECRETS_SRC="${SUPABASE_SECRETS_SRC:-$HOME/.bee_secrets/supabase.env}"
if [[ -f "$DEFAULT_SECRETS_SRC" ]]; then
  echo "🔑  Importing Supabase secrets from $DEFAULT_SECRETS_SRC"
  # shellcheck disable=SC1090
  source "$DEFAULT_SECRETS_SRC"

  # Ensure variables are defined (empty string if missing)
  : "${SUPABASE_ACCESS_TOKEN:=}"
  : "${SUPABASE_SERVICE_ROLE_SECRET:=}"
  : "${SUPABASE_URL:=}"
  : "${SUPABASE_PROJECT_REF:=}"
  : "${SUPABASE_DB_PASSWORD:=}"

  # Rewrite the .secrets file with any values we just sourced.
  # IMPORTANT: file lives locally and is git-ignored; real secrets are never committed.
  cat > "$SECRETS_FILE" <<EOF
SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN
SUPABASE_SERVICE_ROLE_SECRET=$SUPABASE_SERVICE_ROLE_SECRET
SUPABASE_URL=$SUPABASE_URL
SUPABASE_PROJECT_REF=$SUPABASE_PROJECT_REF
SUPABASE_DB_PASSWORD=$SUPABASE_DB_PASSWORD
GCP_SA_KEY=${GCP_SA_KEY:-}
# Optional extras for other CI workflows
GCS_BUCKET=${GCS_BUCKET:-}
SUPABASE_PROJECT_ID=${SUPABASE_PROJECT_ID:-}
EOF

  echo "✅  .secrets updated from local env file (placeholders remain for any missing vars)"

  # Flag to skip Terraform when local creds not present
  if [[ -z "${GCP_SA_KEY:-}" ]]; then
    export SKIP_TERRAFORM=true
    echo "⚠️  No GCP_SA_KEY found – Terraform steps will be skipped in local CI."
  else
    export SKIP_TERRAFORM=false
  fi
fi

# 1️⃣✅  Auto-skip Supabase migrations when no related files changed
# -----------------------------------------------------------------
# If the caller didn't explicitly set SKIP_MIGRATIONS, check the Git diff. If
# there are no changes under `supabase/` **or** the migrations workflow file,
# we set SKIP_MIGRATIONS=true so the deploy job is omitted.  The user can force
# the job to run by exporting FORCE_MIGRATIONS=true.
# Optional: Skip Supabase migrations job manually by exporting SKIP_MIGRATIONS=true before running this script.

# 2️⃣  Pick a runner image. 22.04 is the newest medium-size `act` image currently published.
# If GitHub moves `ubuntu-latest` to 24.04 we can switch to the heavier full image (`full-24.04`).
GITHUB_RUNNER_IMAGE="ghcr.io/catthehacker/ubuntu:act-22.04"

# 3️⃣  Execute `act`
# Select workflow files – default is main CI plus migrations. Set SKIP_MIGRATIONS=true to skip.
WORKFLOW_FILES=(
  ".github/workflows/ci.yml"                 # Backend & Integration Tests
  ".github/workflows/coach_epic_ci.yml"      # Coach Epic CI
  ".github/workflows/flutter-ci.yml"         # Flutter CI
  ".github/workflows/jitai_model_ci.yml"     # JITAI Model CI
  ".github/workflows/lightgbm_export_ci.yml" # LightGBM TS Export CI
)

# Add Supabase migrations unless explicitly skipped
if [[ "${SKIP_MIGRATIONS:-}" != "true" ]]; then
  WORKFLOW_FILES+=(".github/workflows/migrations-deploy.yml")
fi

# Build -W args for act
WF_ARGS=()
for wf in "${WORKFLOW_FILES[@]}"; do
  WF_ARGS+=( -W "$wf" )
done

act push \
  "${WF_ARGS[@]}" \
  -P ubuntu-latest=${GITHUB_RUNNER_IMAGE} \
  --container-architecture linux/amd64 \
  --env ACT=false \
  --env SKIP_TERRAFORM=${SKIP_TERRAFORM:-false} \
  --secret-file "$SECRETS_FILE" \
  "$@" 