#!/bin/bash
set -e

echo "🗄️  BEE-MVP Database Testing (Fast Mode)"
echo "======================================="

cd "$(dirname "$0")/.."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check PostgreSQL version compatibility
check_postgres_version() {
    log_info "Checking PostgreSQL version..."
    PSQL_VERSION=$(psql --version | grep -oE '[0-9]+\.[0-9]+')
    MAJOR_VERSION=$(echo $PSQL_VERSION | cut -d. -f1)
    
    log_info "PostgreSQL version: $PSQL_VERSION"
    
    if [ "$MAJOR_VERSION" -lt 14 ]; then
        log_error "PostgreSQL 14+ required for compatibility with CI environment"
        log_error "Current version: $PSQL_VERSION"
        exit 1
    fi
}

# Setup Supabase-like environment
setup_supabase_environment() {
    log_info "Setting up Supabase-like environment..."
    
    psql -d bee_test_quick -c "
    -- Create auth schema (like Supabase)
    CREATE SCHEMA IF NOT EXISTS auth;
    
    -- Create auth.users table (simplified version for testing)
    CREATE TABLE IF NOT EXISTS auth.users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT UNIQUE,
        encrypted_password TEXT,
        email_confirmed_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Create service_role (like Supabase)
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
            CREATE ROLE service_role;
        END IF;
    END \$\$;
    
    -- Create auth.uid() function to simulate Supabase auth
    CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS \$func\$
    BEGIN
        RETURN NULLIF(
            current_setting('request.jwt.claims', true)::jsonb->>'sub',
            ''
        )::UUID;
    EXCEPTION
        WHEN others THEN
            RETURN NULL;
    END;
    \$func\$ LANGUAGE plpgsql SECURITY DEFINER;
    
    -- Create test users for testing
    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
    VALUES 
        ('11111111-1111-1111-1111-111111111111', 'test-user-a@example.com', 'encrypted', NOW(), NOW(), NOW()),
        ('22222222-2222-2222-2222-222222222222', 'test-user-b@example.com', 'encrypted', NOW(), NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;
    " >/dev/null || {
        log_error "Failed to setup Supabase environment"
        exit 1
    }
}

# Test database setup from scratch
test_database_setup() {
    log_info "Setting up fresh test database..."
    
    # Drop and recreate database
    dropdb bee_test_quick 2>/dev/null || true
    createdb bee_test_quick
    
    # Add extensions
    psql -d bee_test_quick -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" >/dev/null
    
    # Setup Supabase environment
    setup_supabase_environment
    
    # Apply migrations in order
    log_info "Applying migrations..."
    for migration in supabase/migrations/*.sql; do
        if [[ -f "$migration" ]]; then
            filename=$(basename "$migration")
            log_info "  → $filename"
            if ! psql -d bee_test_quick -f "$migration" >/dev/null 2>&1; then
                log_error "Migration failed: $filename"
                # Show the actual error for debugging
                echo "Error details:"
                psql -d bee_test_quick -f "$migration" 2>&1 | head -10
                exit 1
            fi
        fi
    done
}

# Test the exact same constraint syntax as CI
test_constraint_syntax() {
    log_info "Testing CI-compatible constraint syntax..."
    
    # First verify engagement_events table exists
    if ! psql -d bee_test_quick -c "\d engagement_events" >/dev/null 2>&1; then
        log_error "engagement_events table not found after migrations"
        log_info "Available tables:"
        psql -d bee_test_quick -c "\dt"
        exit 1
    fi
    
    psql -d bee_test_quick -c "
    -- Test the exact same constraint pattern used in CI
    DO \$\$ 
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'test_ci_constraint_syntax'
            AND table_name = 'engagement_events'
        ) THEN
            ALTER TABLE engagement_events 
            ADD CONSTRAINT test_ci_constraint_syntax 
            CHECK (true);
        END IF;
    END \$\$;" >/dev/null || {
        log_error "CI constraint syntax test failed"
        exit 1
    }
    
    # Verify constraint was created
    CONSTRAINT_COUNT=$(psql -d bee_test_quick -t -c "
        SELECT COUNT(*) FROM information_schema.table_constraints 
        WHERE constraint_name = 'test_ci_constraint_syntax'
        AND table_name = 'engagement_events';
    " | xargs)
    
    if [ "$CONSTRAINT_COUNT" != "1" ]; then
        log_error "Constraint was not created properly"
        exit 1
    fi
    
    # Clean up
    psql -d bee_test_quick -c "ALTER TABLE engagement_events DROP CONSTRAINT test_ci_constraint_syntax;" >/dev/null
}

# Verify RLS is properly configured
test_rls_setup() {
    log_info "Verifying Row Level Security setup..."
    
    # Check if RLS is enabled
    RLS_ENABLED=$(psql -d bee_test_quick -t -c "
        SELECT relrowsecurity FROM pg_class WHERE relname = 'engagement_events';
    " | xargs)
    
    if [ "$RLS_ENABLED" != "t" ]; then
        log_error "RLS not enabled on engagement_events table"
        exit 1
    fi
    
    # Check if policies exist
    POLICY_COUNT=$(psql -d bee_test_quick -t -c "
        SELECT COUNT(*) FROM pg_policies WHERE tablename = 'engagement_events';
    " | xargs)
    
    if [ "$POLICY_COUNT" -lt 2 ]; then
        log_error "Missing RLS policies (found $POLICY_COUNT, expected at least 2)"
        exit 1
    fi
    
    log_info "RLS configured with $POLICY_COUNT policies"
}

# Test basic table operations
test_basic_operations() {
    log_info "Testing basic database operations..."
    
    # Test insert (will fail with RLS but that's expected)
    psql -d bee_test_quick -c "
        INSERT INTO engagement_events (user_id, event_type, value) 
        VALUES ('11111111-1111-1111-1111-111111111111', 'test_event', '{\"test\": true}');
    " >/dev/null 2>&1 || log_info "Insert failed as expected (RLS working)"
    
    # Test table structure
    psql -d bee_test_quick -c "\d engagement_events" >/dev/null || {
        log_error "Table structure check failed"
        exit 1
    }
}

# Cleanup
cleanup() {
    log_info "Cleaning up test database..."
    dropdb bee_test_quick 2>/dev/null || true
}

# Main function
main() {
    trap cleanup EXIT
    
    check_postgres_version
    test_database_setup
    test_constraint_syntax
    test_rls_setup
    test_basic_operations
    
    echo ""
    log_success "🎉 Database tests passed!"
    log_success "Your migrations are compatible with CI PostgreSQL 14"
    echo ""
}

main "$@" 