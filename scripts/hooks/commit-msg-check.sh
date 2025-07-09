#!/usr/bin/env bash
set -euo pipefail

MSG_FILE="$1"

if grep -Ei -- '--no-verify|\bno-verify\b' "$MSG_FILE" >/dev/null; then
  echo "❌  Commit message contains disallowed '--no-verify' flag. Commits must pass verification hooks."
  echo "🚫  Remove '--no-verify' (or similar) from the message and try again."
  exit 1
fi

exit 0 