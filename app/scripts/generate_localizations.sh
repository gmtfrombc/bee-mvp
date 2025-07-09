#!/usr/bin/env bash
# Regenerates Flutter localization (class S) files.
# Usage: ./scripts/generate_localizations.sh
set -euo pipefail

# Navigate to project root (directory where pubspec.yaml lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

flutter gen-l10n 