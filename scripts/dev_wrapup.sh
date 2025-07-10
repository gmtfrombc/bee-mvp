#!/usr/bin/env bash
# dev_wrapup.sh – non-interactive helper for Developer Wrap-Up Playbook
# Usage: ./scripts/dev_wrapup.sh M1.12.1
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <milestone-code>" >&2
  exit 1
fi
MILESTONE=$1
BRANCH="feature/${MILESTONE}"

# Ensure on correct branch
CURRENT=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT" != "$BRANCH" ]]; then
  echo "❌ Switch to $BRANCH before running." >&2
  exit 1
fi

# Ensure clean tree
if [[ -n $(git status --porcelain) ]]; then
  echo "❌ Working tree dirty. Commit or stash changes first." >&2
  exit 1
fi

echo "🔍 Final local health-check…"
flutter analyze --fatal-infos
flutter test --no-pub

echo "🔄 Rebase onto latest main…"
git fetch origin
git rebase origin/main

echo "🧪 Re-running tests after rebase…"
flutter analyze --fatal-infos
flutter test --no-pub

echo "🚀 Pushing branch…"
git push --force-with-lease

# Open or update PR
if command -v gh >/dev/null; then
  gh pr view "$BRANCH" || gh pr create --title "$MILESTONE complete" --base main --head "$BRANCH" --body "Automated wrap-up push by dev_wrapup.sh" --web
fi

echo "✅ Wrap-up script finished. Merge in GitHub after CI passes." 