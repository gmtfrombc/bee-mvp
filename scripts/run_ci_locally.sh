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
EOF
fi

# 2️⃣  Pick a runner image. 22.04 is the newest medium-size `act` image currently published.
# If GitHub moves `ubuntu-latest` to 24.04 we can switch to the heavier full image (`full-24.04`).
GITHUB_RUNNER_IMAGE="ghcr.io/catthehacker/ubuntu:act-22.04"

# 3️⃣  Execute `act`
act push \
  -W "$WORKFLOW_FILE" \
  -P ubuntu-latest=${GITHUB_RUNNER_IMAGE} \
  --container-architecture linux/amd64 \
  --env ACT=false \
  --secret-file "$SECRETS_FILE" \
  "$@" 