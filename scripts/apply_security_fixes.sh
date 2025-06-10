#!/bin/bash

# Apply Supabase Security Fixes
# This script applies the security fixes migration and validates the results

set -e

echo "🔒 Applying Supabase Security Fixes..."

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

echo "📋 Security fixes to be applied:"
echo "   ✓ Enable RLS on system_logs, realtime_event_metrics, momentum_error_logs"
echo "   ✓ Fix auth.users exposure in coach_intervention_queue view"
echo "   ✓ Remove SECURITY DEFINER from 20+ views" 
echo "   ✓ Add secure helper functions for coach access"
echo "   ✓ Tighten permissions on auth schema"
echo ""

# Prompt for confirmation
read -p "🤔 Continue with applying security fixes? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted by user"
    exit 1
fi

# Apply the migration
echo "🚀 Applying migration..."
if supabase db push; then
    echo "✅ Security fixes migration applied successfully!"
else
    echo "❌ Failed to apply migration. Check the error above."
    exit 1
fi

# Validate some key fixes
echo ""
echo "🔍 Validating security fixes..."

# Test 1: Check if RLS is enabled on the problematic tables
echo "   📊 Checking RLS status..."
supabase db exec --query "
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('system_logs', 'realtime_event_metrics', 'momentum_error_logs')
AND schemaname = 'public';"

# Test 2: Verify coach_intervention_queue view doesn't expose auth.users
echo "   👀 Checking coach_intervention_queue view definition..."
supabase db exec --query "
SELECT pg_get_viewdef('public.coach_intervention_queue'::regclass, true) as view_definition;" | grep -q "auth.users" && {
    echo "⚠️  WARNING: coach_intervention_queue still references auth.users"
} || {
    echo "   ✅ coach_intervention_queue no longer exposes auth.users"
}

# Test 3: Check if helper functions were created
echo "   🔧 Checking helper functions..."
FUNC_COUNT=$(supabase db exec --query "
SELECT COUNT(*) 
FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname = 'public' 
AND p.proname IN ('get_user_email_for_coach', 'get_intervention_with_user_context');" | tail -n 1 | tr -d ' ')

if [[ "$FUNC_COUNT" == "2" ]]; then
    echo "   ✅ Helper functions created successfully"
else
    echo "   ⚠️  WARNING: Expected 2 helper functions, found $FUNC_COUNT"
fi

echo ""
echo "🎉 Security fixes deployment completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Test the application thoroughly"
echo "   2. Monitor for any permission-related errors"
echo "   3. Update any code that relied on old view structures"
echo "   4. Verify coach intervention functionality works"
echo ""
echo "📚 See docs/security_fixes/supabase_security_audit_fixes.md for details" 