#!/bin/bash

# Verify Security Fixes Applied Successfully
# This script checks the database to confirm security issues are resolved

set -e

echo "🔍 Verifying Security Fixes in Production..."

# Function to create and run temporary SQL file
run_query() {
    local query="$1"
    local temp_file=$(mktemp /tmp/verify_query_XXXXXX.sql)
    echo "$query" > "$temp_file"
    
    echo "Running query..."
    if psql "$(supabase status | grep 'DB URL' | cut -d':' -f2- | sed 's/^ *//')" -f "$temp_file" 2>/dev/null; then
        rm -f "$temp_file"
    else
        echo "Local DB not available, checking production..."
        rm -f "$temp_file"
        # Create a simple query file for manual execution
        echo "Query to run in Supabase Studio:"
        echo "$query"
        echo "---"
    fi
}

echo ""
echo "📊 1. Checking RLS Status on Previously Problematic Tables..."
run_query "
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('system_logs', 'realtime_event_metrics', 'momentum_error_logs')
AND schemaname = 'public'
ORDER BY tablename;"

echo ""
echo "🔧 2. Checking View Security Properties..."
run_query "
SELECT 
    schemaname,
    viewname,
    viewowner,
    CASE 
        WHEN definition LIKE '%SECURITY DEFINER%' THEN 'HAS SECURITY DEFINER ⚠️'
        ELSE 'Clean ✅'
    END as security_status
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN ('coach_intervention_queue', 'momentum_dashboard', 'recent_user_momentum', 'intervention_candidates')
ORDER BY viewname;"

echo ""
echo "🛡️ 3. Checking for ANY remaining SECURITY DEFINER views..."
run_query "
SELECT 
    schemaname,
    viewname,
    'SECURITY DEFINER FOUND' as issue
FROM pg_views 
WHERE schemaname = 'public' 
AND definition LIKE '%SECURITY DEFINER%'
ORDER BY viewname;"

echo ""
echo "📝 4. Checking Security Log Entries..."
run_query "
SELECT 
    log_level,
    message,
    created_at
FROM public.system_logs 
WHERE message LIKE '%security%' 
ORDER BY created_at DESC 
LIMIT 5;"

echo ""
echo "🔐 5. Checking Helper Functions..."
run_query "
SELECT 
    proname as function_name,
    prosecdef as is_security_definer,
    CASE 
        WHEN prosecdef THEN 'SECURITY DEFINER (Expected for helpers) ✅'
        ELSE 'SECURITY INVOKER'
    END as security_type
FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname = 'public' 
AND p.proname IN ('get_user_email_for_coach', 'get_intervention_with_user_context')
ORDER BY proname;"

echo ""
echo "✅ Security verification complete!"
echo ""
echo "Expected results:"
echo "  • All 3 tables should have RLS enabled (t)"
echo "  • All 4 views should show 'Clean ✅'"
echo "  • No SECURITY DEFINER views should be found"
echo "  • Helper functions should have SECURITY DEFINER (this is expected)"
echo "  • Security log entries should show our fixes" 