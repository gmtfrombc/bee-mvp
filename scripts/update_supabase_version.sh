#!/bin/bash

# Script to update the pinned Supabase CLI version across all files
# Usage: ./scripts/update_supabase_version.sh <new_version>

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <new_version>"
    echo "Example: $0 2.31.0"
    exit 1
fi

NEW_VERSION="$1"

# Validate version format
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "❌ Invalid version format. Expected format: X.Y.Z (e.g., 1.84.0)"
    exit 1
fi

echo "🔄 Updating Supabase CLI version to $NEW_VERSION..."

# Files to update
WORKFLOW_FILE=".github/workflows/migrations-deploy.yml"
LOCAL_CI_FILE="scripts/run_ci_locally.sh"

# Update GitHub workflow
if [ -f "$WORKFLOW_FILE" ]; then
    echo "📝 Updating $WORKFLOW_FILE..."
    sed -i.bak "s/version: [0-9]\+\.[0-9]\+\.[0-9]\+/version: $NEW_VERSION/" "$WORKFLOW_FILE"
    sed -i.bak "s/EXPECTED_VERSION=\"[0-9]\+\.[0-9]\+\.[0-9]\+\"/EXPECTED_VERSION=\"$NEW_VERSION\"/" "$WORKFLOW_FILE"
    rm "$WORKFLOW_FILE.bak"
    echo "✅ Updated $WORKFLOW_FILE"
else
    echo "⚠️  $WORKFLOW_FILE not found"
fi

# Update local CI script
if [ -f "$LOCAL_CI_FILE" ]; then
    echo "📝 Updating $LOCAL_CI_FILE..."
    sed -i.bak "s/EXPECTED_VERSION=\"[0-9]\+\.[0-9]\+\.[0-9]\+\"/EXPECTED_VERSION=\"$NEW_VERSION\"/" "$LOCAL_CI_FILE"
    rm "$LOCAL_CI_FILE.bak"
    echo "✅ Updated $LOCAL_CI_FILE"
else
    echo "⚠️  $LOCAL_CI_FILE not found"
fi

echo ""
echo "✅ Successfully updated Supabase CLI version to $NEW_VERSION"
echo ""
echo "📋 Next steps:"
echo "1. Test the changes locally:"
echo "   ./scripts/run_ci_locally.sh -j deploy --env ACT=false --env SKIP_TERRAFORM=true"
echo "2. Commit and push the changes:"
echo "   git add $WORKFLOW_FILE $LOCAL_CI_FILE"
echo "   git commit -m \"ci: update Supabase CLI to v$NEW_VERSION\""
echo "   git push origin main"
echo "3. Monitor the GitHub Actions workflow for any issues"
echo ""
echo "🔗 Release notes: https://github.com/supabase/cli/releases/tag/v$NEW_VERSION" 