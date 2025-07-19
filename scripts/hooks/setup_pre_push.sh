#!/usr/bin/env bash
# Installs or refreshes the pre-push git hook pointing to scripts/smart_test.sh
set -euo pipefail
ROOT_DIR=$(git rev-parse --show-toplevel)
HOOK_PATH="$ROOT_DIR/.git/hooks/pre-push"
TARGET_REL="../../scripts/smart_test.sh"

mkdir -p "$(dirname "$HOOK_PATH")"
rm -f "$HOOK_PATH"
ln -s "$TARGET_REL" "$HOOK_PATH"
chmod +x "$ROOT_DIR/scripts/smart_test.sh"

echo "✅ pre-push hook installed -> $TARGET_REL" 