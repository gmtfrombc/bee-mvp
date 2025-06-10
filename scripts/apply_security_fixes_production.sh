#!/bin/bash

# Apply Supabase Security Fixes to Production
# This script applies security fixes to the remote production database

set -e

echo "🔒 Applying Supabase Security Fixes to Production..."

# Check if supabase CLI is available
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install it first."
    exit 1
fi

# Ensure we're in the project root
if [[ ! -f "supabase/config.toml" ]]; then
    echo "❌ Not in project root. Please run from bee-mvp directory."
    exit 1
fi

# Check if migration file exists
MIGRATION_FILE="supabase/migrations/20250120000000_security_fixes.sql"
if [[ ! -f "$MIGRATION_FILE" ]]; then
    echo "❌ Security fixes migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "📋 Security fixes to be applied to PRODUCTION:"
echo "   ✓ Enable RLS on system_logs, realtime_event_metrics, momentum_error_logs"
echo "   ✓ Fix auth.users exposure in coach_intervention_queue view"
echo "   ✓ Remove SECURITY DEFINER from 20+ views" 
echo "   ✓ Add secure helper functions for coach access"
echo "   ✓ Tighten permissions on auth schema"
echo ""
echo "⚠️  WARNING: This will modify your PRODUCTION database!"
echo ""

# Double confirmation for production
read -p "🤔 Are you SURE you want to apply these changes to PRODUCTION? (yes/NO): " -r
if [[ ! $REPLY == "yes" ]]; then
    echo "❌ Aborted. Use 'yes' to confirm production deployment."
    exit 1
fi

echo ""
echo "🚀 Pushing migration to production..."

# Use supabase db push to apply the migration
if supabase db push; then
    echo ""
    echo "✅ Security fixes migration applied successfully to production!"
    echo ""
    echo "🔍 Please validate the changes:"
    echo "   1. Check that anonymous users cannot access sensitive data"
    echo "   2. Verify users can only see their own data"
    echo "   3. Test coach intervention functionality"
    echo "   4. Monitor application for any permission errors"
    echo ""
    echo "📚 See docs/security_fixes/supabase_security_audit_fixes.md for details"
else
    echo ""
    echo "❌ Failed to apply migration to production."
    echo "Please check the error above and try again."
    exit 1
fi 