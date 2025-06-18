#!/usr/bin/env bash
set -euo pipefail

# 🦕  BEE-MVP – Deno quality gate
# Lints, type-checks and tests all Supabase Edge Functions.
# Usage:  bash scripts/deno_check.sh

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$PROJECT_ROOT"

echo "🔍 Running Deno lint (strict) …"
deno lint supabase/functions

echo "🔎 Running TypeScript type-check …"
deno check --all supabase/functions

echo "🧪 Running unit & integration tests …"
DENO_TESTING=true deno test -A --node-modules-dir supabase/functions

echo "✅ All Deno checks passed" 