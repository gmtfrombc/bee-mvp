#!/usr/bin/env bash
# Lightweight pre-push smart test runner
# Runs only the test suites affected by staged changes.
#  • Flutter unit/widget tests when Dart source or test files are touched
#  • Deno / Edge-function tests when Supabase function code or config is touched
# Skips entirely if no relevant paths are changed.

set -euo pipefail

# Determine tree-ish to diff against (default: last commit on branch)
BASE_REF=${BASE_REF:-HEAD~1}
CHANGED=$(git diff --name-only "$BASE_REF" --cached)

needs_flutter=false
needs_deno=false

while IFS= read -r file; do
  [[ $file == app/lib/* || $file == app/test/* ]] && needs_flutter=true
  [[ $file == supabase/functions/* ]] && needs_deno=true
  [[ $file == supabase/functions/deno.json ]] && needs_deno=true
done <<< "$CHANGED"

if ! $needs_flutter && ! $needs_deno; then
  echo "smart-test: No Flutter or edge-function changes detected – skipping tests."
  exit 0
fi

if $needs_flutter; then
  echo "smart-test: Running Flutter analyzer & unit tests …"
  (cd app && flutter analyze --fatal-warnings && flutter test --exclude-tags golden)
fi

if $needs_deno; then
  echo "smart-test: Running Deno edge-function tests …"
  deno test -A --config supabase/functions/deno.json supabase/functions
fi

echo "smart-test: Completed successfully." 