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

# 🚦 Default behaviour for local CI runs
# --------------------------------------
FLUTTER_VERSION="3.32.1"
# Supabase CLI version expected by remote GitHub CI. Keep this in sync with
# .github/workflows/migrations-deploy.yml and other workflows.
PINNED_SUPABASE_CLI_VERSION="2.30.4"

# -------------------------------------------------------------
# Install the pinned Supabase CLI version locally when it is
# either missing or does not match the pinned version. The binary
# is placed in a throw-away tmpdir that is prepended to PATH so
# it never pollutes the user’s global install. No sudo required.
# -------------------------------------------------------------
install_supabase_cli() {
  local os arch url tmpdir

  # Determine target OS
  case "$(uname -s)" in
    Linux*)   os="linux" ;;
    Darwin*)  os="darwin" ;;
    *) echo "❌  Unsupported OS for automatic Supabase CLI install" >&2; return 1 ;;
  esac

  # Determine architecture
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) echo "❌  Unsupported architecture for automatic Supabase CLI install" >&2; return 1 ;;
  esac

  url="https://github.com/supabase/cli/releases/download/v${PINNED_SUPABASE_CLI_VERSION}/supabase_${os}_${arch}.tar.gz"
  echo "⬇️  Downloading Supabase CLI v${PINNED_SUPABASE_CLI_VERSION} (${os}/${arch})…"
  tmpdir="$(mktemp -d)"
  curl -sSL "$url" | tar -xz -C "$tmpdir" || { echo "❌  Failed to download Supabase CLI" >&2; return 1; }

  export PATH="$tmpdir:$PATH"
  echo "✅  Supabase CLI installed to $tmpdir"
}

# Skip the heavy Supabase migrations/terraform job unless the caller
# explicitly disables skipping (e.g. SKIP_MIGRATIONS=false) or forces it
# (FORCE_MIGRATIONS=true). This mirrors GitHubʼs behaviour where the
# deploy job only runs when infra-related paths change.

export SKIP_MIGRATIONS=${SKIP_MIGRATIONS:-true}
# By default we skip artifact uploads for speed.  For workflows where the
# artefact is the primary output (e.g. LightGBM export) we *must* run the
# upload step locally to mimic GitHub.  Detect those jobs and disable the
# skip flag automatically unless the user forces it.

if [[ "${JOB_FILTER:-}" == "export-scorer" || "${JOB_FILTER:-}" == "train-dry-run" ]]; then
  export SKIP_UPLOAD_ARTIFACTS=${SKIP_UPLOAD_ARTIFACTS:-false}
else
  export SKIP_UPLOAD_ARTIFACTS=${SKIP_UPLOAD_ARTIFACTS:-true}
fi

if [[ "${FORCE_MIGRATIONS:-}" == "true" ]]; then
  SKIP_MIGRATIONS=false
fi

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
GITHUB_TOKEN=
EOF
fi

# 1️⃣🚀  Auto-populate secrets from local Supabase env file (optional)
DEFAULT_SECRETS_SRC="${SUPABASE_SECRETS_SRC:-$HOME/.bee_secrets/supabase.env}"
if [[ -f "$DEFAULT_SECRETS_SRC" ]]; then
  echo "🔑  Importing Supabase secrets from $DEFAULT_SECRETS_SRC"

  # -----------------------------------------------------------------
  # SAFER ENV LOADING
  # -----------------------------------------------------------------
  # The raw supabase.env may contain comments, blank lines, or stray tokens
  # (e.g. a JWT on its own line).  Sourcing it verbatim causes Bash errors
  # like “command not found”.  Instead, we filter for valid KEY=value
  # assignments, optionally prefixed with `export`, then evaluate only those.

  # shellcheck disable=SC2016,SC1090,SC2046
  set -a  # export all variables that get declared in this subshell
  # Revert to plain source now that supabase.env no longer includes stray tokens
  # shellcheck disable=SC1090
  source "$DEFAULT_SECRETS_SRC"
  set +a

  # -----------------------------------------------------------------
  # Fallback: some edge cases (e.g., very long base64 strings with odd chars)
  # may still prevent the above `source` from setting GCP_SA_KEY.  If the
  # variable is still empty but present in the raw file, extract it manually.
  if [[ -z "${GCP_SA_KEY:-}" ]]; then
    GCP_SA_KEY=$(grep -E '^[[:space:]]*(export[[:space:]]+)?GCP_SA_KEY[[:space:]]*=' "$DEFAULT_SECRETS_SRC" | head -n1 | cut -d= -f2- | sed -E 's/^[[:space:]]*//') || true
    export GCP_SA_KEY
  fi

  # Ensure variables are defined (empty string if missing)
  : "${SUPABASE_ACCESS_TOKEN:=}"
  : "${SUPABASE_SERVICE_ROLE_SECRET:=}"
  : "${SUPABASE_URL:=}"
  : "${SUPABASE_PROJECT_REF:=}"
  : "${SUPABASE_DB_PASSWORD:=}"

  # Fail-fast when critical Supabase vars are missing so that
  # the password-policy enforcement path runs locally exactly
  # as it does on GitHub CI.
  if [[ -z "$SUPABASE_ACCESS_TOKEN" || -z "$SUPABASE_URL" ]]; then
    echo "❌  SUPABASE_ACCESS_TOKEN and/or SUPABASE_URL missing. Local CI cannot continue – add them to $DEFAULT_SECRETS_SRC (see docs)." >&2
    exit 1
  fi

  # Auto-derive project ref from URL when missing
  if [[ -z "$SUPABASE_PROJECT_REF" && -n "$SUPABASE_URL" ]]; then
    # Extract subdomain before first dot after protocol
    SUPABASE_PROJECT_REF=$(echo "$SUPABASE_URL" | sed -E 's#https?://([^.]+)\..*#\1#')
    export SUPABASE_PROJECT_REF
    echo "ℹ️  Derived SUPABASE_PROJECT_REF=$SUPABASE_PROJECT_REF from SUPABASE_URL"
  fi

  # -----------------------------------------------------------------
  # If critical Supabase vars are missing AND user hasn't explicitly
  # disabled skipping, auto-skip migrations to avoid CLI failures.
  if [[ -z "$SUPABASE_PROJECT_REF" || -z "$SUPABASE_ACCESS_TOKEN" || -z "$SUPABASE_DB_PASSWORD" ]]; then
    if [[ "${FORCE_MIGRATIONS:-}" != "true" ]]; then
      export SKIP_MIGRATIONS=true
      echo "⚠️  Missing Supabase credentials – migrations job will be skipped. Use FORCE_MIGRATIONS=true to override."
    fi
  fi

  # Rewrite the .secrets file with any values we just sourced.
  # IMPORTANT: file lives locally and is git-ignored; real secrets are never committed.
  cat > "$SECRETS_FILE" <<EOF
SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN
SUPABASE_SERVICE_ROLE_SECRET=$SUPABASE_SERVICE_ROLE_SECRET
SUPABASE_URL=$SUPABASE_URL
SUPABASE_PROJECT_REF=$SUPABASE_PROJECT_REF
SUPABASE_DB_PASSWORD=$SUPABASE_DB_PASSWORD
SKIP_TERRAFORM=${SKIP_TERRAFORM:-true}
GCP_SA_KEY=${GCP_SA_KEY:-}
# Optional extras for other CI workflows
GCS_BUCKET=${GCS_BUCKET:-}
SUPABASE_PROJECT_ID=${SUPABASE_PROJECT_ID:-}
GITHUB_TOKEN=${GITHUB_TOKEN:-}
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

# Debug: echo key vars when verbose flag or FORCE_MIGRATIONS=true
if [[ "${FORCE_MIGRATIONS:-}" == "true" ]]; then
  echo "🔍 Supabase vars after loading:"
  echo "  SUPABASE_PROJECT_REF=$SUPABASE_PROJECT_REF"
  echo "  SUPABASE_ACCESS_TOKEN length=${#SUPABASE_ACCESS_TOKEN}"
  echo "  SUPABASE_DB_PASSWORD set? $([ -n "$SUPABASE_DB_PASSWORD" ] && echo yes || echo no)"
fi

# 1️⃣✅  Auto-skip Supabase migrations when no related files changed
# -----------------------------------------------------------------
# If the caller didn't explicitly set SKIP_MIGRATIONS, check the Git diff. If
# there are no changes under `supabase/` **or** the migrations workflow file,
# we set SKIP_MIGRATIONS=true so the deploy job is omitted.  The user can force
# the job to run by exporting FORCE_MIGRATIONS=true.
# Optional: Skip Supabase migrations job manually by exporting SKIP_MIGRATIONS=true before running this script.

# === ARG PARSING: capture -j/--job early so we can tweak workflow list ===
JOB_FILTER=""
PASSTHRU_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -j|--job)
      JOB_FILTER="$2"
      # we will re-append this flag AFTER all -W args later
      shift 2
      ;;
    *)
      PASSTHRU_ARGS+=("$1")
      shift
      ;;
  esac
done
# restore positional params (sans -j) for later pass-through
if [[ ${#PASSTHRU_ARGS[@]} -gt 0 ]]; then
  eval set -- "${PASSTHRU_ARGS[@]}"
else
  # reset to no positional arguments
  set --
fi

# -------------------------------------------------------------------------
# 2️⃣ Pick a runner image – switch to a Flutter-preinstalled image when the
#    requested job is the Flutter CI "test" job for dramatically faster runs.
# -------------------------------------------------------------------------
# Default minimal image for backend/integration workflows
DEFAULT_RUNNER_IMAGE="ghcr.io/gmtfrombc/ci-base:latest"
# Flutter-optimised image (contains SDK $FLUTTER_VERSION and Android toolchain)
FLUTTER_RUNNER_IMAGE="ghcr.io/instrumentisto/flutter:${FLUTTER_VERSION}-androidsdk35-r0"

if [[ "$JOB_FILTER" == "test" ]]; then
  # Use the heavier but pre-baked Flutter image when only Flutter tests run
  GITHUB_RUNNER_IMAGE="${FLUTTER_RUNNER_IMAGE}"
else
  GITHUB_RUNNER_IMAGE="${DEFAULT_RUNNER_IMAGE}"
fi

# 3️⃣  Execute `act`
# Select workflow files – default is main CI plus migrations. Set SKIP_MIGRATIONS=true to skip.
WORKFLOW_FILES=(
  ".github/workflows/ci.yml"                 # Backend & Integration Tests
  ".github/workflows/coach_epic_ci.yml"      # Coach Epic CI
  ".github/workflows/flutter-ci.yml"         # Flutter CI
  ".github/workflows/jitai_model_ci.yml"     # JITAI Model CI
  ".github/workflows/lightgbm_export_ci.yml" # LightGBM TS Export CI
)

# When a specific job is requested, keep only the workflow likely to contain it
if [[ -n "$JOB_FILTER" ]]; then
  case "$JOB_FILTER" in
    test)
      WORKFLOW_FILES=(".github/workflows/flutter-ci.yml")
      ;;
    build)
      WORKFLOW_FILES=(".github/workflows/ci.yml")
      ;;
    deploy)
      WORKFLOW_FILES=(".github/workflows/migrations-deploy.yml")
      ;;
    train-dry-run)
      # JITAI Model CI – train-dry-run job
      WORKFLOW_FILES=(".github/workflows/jitai_model_ci.yml")
      ;;
    *)
      # fallback: keep existing list (acts like original behaviour)
      ;;
  esac
fi

# By default, skip migrations for faster local runs unless FORCE_MIGRATIONS is true
if [[ "${FORCE_MIGRATIONS:-}" == "true" ]]; then
  SKIP_MIGRATIONS=false
fi

# Export so child processes inherit
export SKIP_MIGRATIONS=${SKIP_MIGRATIONS:-true}

# Include migrations workflow only when not skipping
if [[ "${SKIP_MIGRATIONS}" != "true" ]]; then
  WORKFLOW_FILES+=(".github/workflows/migrations-deploy.yml")
fi

# Pre-flight credentials check – ensure we can link to the Supabase project locally.
# -----------------------------------------------------------------------------
if [[ "${SKIP_MIGRATIONS}" != "true" ]]; then
  # Ensure the pinned Supabase CLI version is available in PATH
  ACTUAL_VERSION="$(command -v supabase >/dev/null 2>&1 && supabase --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo 'none')"
  if [[ "$ACTUAL_VERSION" != "$PINNED_SUPABASE_CLI_VERSION" ]]; then
    echo "🔍  Supabase CLI version mismatch (found $ACTUAL_VERSION, expected $PINNED_SUPABASE_CLI_VERSION). Installing correct version…"
    install_supabase_cli || { echo "❌  Unable to install required Supabase CLI" >&2; exit 1; }
  else
    echo "✅  Supabase CLI v$ACTUAL_VERSION already present"
  fi
  
  echo "🔗  Verifying Supabase credentials via 'supabase link'…"
  # Try linking with access token first (preferred method)
  if ! supabase link --project-ref "$SUPABASE_PROJECT_REF" >/dev/null 2>&1; then
    echo "    • Access token method failed, trying with password..."
    # Suppress verbose CLI output; failures will still bubble up.
    supabase link --project-ref "$SUPABASE_PROJECT_REF" \
                 --password "$SUPABASE_DB_PASSWORD" \
                 --debug \
                 >/dev/null 2>&1 || {
      echo "❌  supabase link failed – check SUPABASE_* secrets before running CI." >&2
      exit 1
    }
  fi
  echo "✅  Supabase credentials verified."
fi

# Build -W args for act
WF_ARGS=()
for wf in "${WORKFLOW_FILES[@]}"; do
  WF_ARGS+=( -W "$wf" )
done

ACT_CMD=(act push "${WF_ARGS[@]}" -P ubuntu-latest=${GITHUB_RUNNER_IMAGE} --container-architecture linux/amd64 --env SKIP_UPLOAD_ARTIFACTS=true --env SKIP_TERRAFORM=${SKIP_TERRAFORM:-false} --secret-file "$SECRETS_FILE")

# Re-append the job filter (if any) **after** all -W flags so `act` can
# correctly match the job once workflows have been loaded.
if [[ -n "$JOB_FILTER" ]]; then
  ACT_CMD+=( -j "$JOB_FILTER" )
fi

# Finally, append any remaining pass-through args supplied by the user
ACT_CMD+=("$@")

# Abort early when artefact uploads are enabled but no GitHub token is present
if [[ "${SKIP_UPLOAD_ARTIFACTS}" == "false" ]]; then
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "❌  SKIP_UPLOAD_ARTIFACTS=false but GITHUB_TOKEN is missing. Provide a GitHub Personal Access Token in ~/.bee_secrets/supabase.env (key: GITHUB_TOKEN) so local runs hit the real upload-artifact endpoint." >&2
    exit 1
  fi
fi

"${ACT_CMD[@]}" 

# =============================================================
#  🔒 Post-run Guard: detect uncommitted artefacts (e.g., golden
#  images) created during the test run. If the working tree is no
#  longer clean, fail the script so the developer notices and
#  commits the updated files before pushing. This prevents the
#  remote CI from failing due to missing golden baselines.
# =============================================================

ACT_EXIT_CODE=$?

# Only perform git cleanliness check when the CI tasks themselves
# succeeded. If the workflow failed (non-zero exit), we propagate
# that error code directly.
if [[ $ACT_EXIT_CODE -eq 0 ]]; then
  # Check for any unstaged or untracked changes in source directories
  # (Flutter goldens in app/, Python auto-formatting in tests/).
  if [[ -n "$(git status --porcelain app/ tests/ | head -n1)" ]]; then
    echo "❌  Local CI completed successfully but produced file changes." >&2
    echo "    Commit or discard these changes (likely updated golden baselines) before pushing." >&2
    git --no-pager status --short app/ tests/ >&2
    exit 1
  fi
fi

exit $ACT_EXIT_CODE 