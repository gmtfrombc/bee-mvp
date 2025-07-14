#!/bin/bash
set -euo pipefail  # Exit on any error

echo "🚀 BEE-MVP Complete Local Testing Pipeline"
echo "==========================================="

# Ensure we're in the right directory
cd "$(dirname "$0")/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    log_info "Checking required dependencies..."
    
    command -v psql >/dev/null 2>&1 || { log_error "PostgreSQL (psql) is required but not installed."; exit 1; }
    command -v python >/dev/null 2>&1 || { log_error "Python is required but not installed."; exit 1; }
    command -v flutter >/dev/null 2>&1 || { log_error "Flutter is required but not installed."; exit 1; }
    command -v terraform >/dev/null 2>&1 || { log_error "Terraform is required but not installed."; exit 1; }
    
    log_success "All dependencies found"
}

# Phase 1: Database Infrastructure Testing
test_database() {
    log_info "🗄️  PHASE 1: Database Infrastructure Testing"
    # ------------------------------------------------------------------------
    # Optional CI-parity Postgres (Docker) — mirrors GitHub workflow
    # Set USE_DOCKER_CI=false to keep using local Postgres
    # ------------------------------------------------------------------------
    if [[ "${USE_DOCKER_CI:-true}" == "true" ]]; then
        if command -v docker >/dev/null 2>&1; then
            if ! docker ps --format '{{.Names}}' | grep -q '^bee_ci_pg$'; then
                log_info "Starting disposable Postgres 14 container (bee_ci_pg) for CI parity…"
                docker run --rm -d --name bee_ci_pg \
                    -e POSTGRES_PASSWORD=postgres \
                    -p 55432:5432 postgres:14 >/dev/null
                export PGHOST=localhost PGPORT=55432 PGUSER=postgres PGPASSWORD=postgres
                trap "docker rm -f bee_ci_pg >/dev/null 2>&1" EXIT
                # Wait for Postgres to accept connections
                until PGPASSWORD=postgres psql -h "$PGHOST" -p "$PGPORT" -U postgres -d postgres -c 'SELECT 1' >/dev/null 2>&1; do
                    sleep 0.5
                done
            else
                log_info "Reusing existing bee_ci_pg container"
            fi
        else
            log_warning "Docker not found – falling back to local Postgres"
        fi
    fi
    
    # Check PostgreSQL version
    log_info "Checking PostgreSQL version..."
    PSQL_VERSION=$(psql --version | grep -oE '[0-9]+\.[0-9]+')
    log_info "PostgreSQL version: $PSQL_VERSION"
    
    # Start PostgreSQL if not running (macOS)
    if command -v brew >/dev/null 2>&1; then
        if ! pgrep -f postgres >/dev/null; then
            log_info "Starting PostgreSQL..."
            brew services start postgresql || log_warning "PostgreSQL may already be running"
        fi
    fi
    
    # Create test database
    log_info "Setting up test database..."
    dropdb bee_test 2>/dev/null || log_info "Test database didn't exist"
    createdb bee_test
    
    # Add required extensions
    psql -d bee_test -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" >/dev/null
    psql -d bee_test -c "CREATE EXTENSION IF NOT EXISTS \"pg_trgm\";" >/dev/null 2>&1 || log_warning "pg_trgm extension not available"
    
    # Setup Supabase-like environment
    log_info "Setting up Supabase-like environment..."
    psql -d bee_test -c "
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
    
    # Apply migrations in sequence
    log_info "Applying database migrations..."
    for migration in supabase/migrations/*.sql; do
        if [[ -f "$migration" ]]; then
            log_info "Applying: $(basename "$migration")"
            if ! psql -d bee_test -f "$migration" >/dev/null 2>&1; then
                log_error "MIGRATION FAILED: $migration"
                exit 1
            fi
        fi
    done
    
    # Verify critical tables exist
    log_info "Verifying database schema..."
    if ! psql -d bee_test -c "\d+ engagement_events" >/dev/null 2>&1; then
        log_error "engagement_events table not found"
        exit 1
    fi
    
    # Test constraint compatibility (same as CI)
    log_info "Testing constraint syntax compatibility..."
    psql -d bee_test -c "
    DO \$\$ 
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'test_constraint_compatibility'
            AND table_name = 'engagement_events'
        ) THEN
            ALTER TABLE engagement_events 
            ADD CONSTRAINT test_constraint_compatibility 
            CHECK (true);
        END IF;
    END \$\$;" >/dev/null 2>&1 || {
        log_error "Constraint syntax compatibility test failed"
        exit 1
    }
    
    # Clean up test constraint
    psql -d bee_test -c "ALTER TABLE engagement_events DROP CONSTRAINT IF EXISTS test_constraint_compatibility;" >/dev/null 2>&1
    
    log_success "Database infrastructure tests passed"
}

# Phase 2: Python Code Quality & Security Testing
test_python() {
    log_info "🐍 PHASE 2: Python Code Quality & Security"
    
    # Check if Python dependencies are installed
    if [[ ! -f "venv/bin/activate" ]]; then
        log_warning "Virtual environment not found. Please run: python -m venv venv && source venv/bin/activate && pip install -r tests/requirements-minimal.txt"
        exit 1
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Code formatting check
    log_info "Checking code formatting with Black..."
    if ! black tests/ functions/ --check --diff; then
        log_error "BLACK FORMATTING FAILED - run: black tests/ functions/"
        exit 1
    fi
    
    # Linting
    log_info "Checking code quality with Ruff..."
    if ! ruff check tests/ functions/ --output-format=github; then
        log_error "RUFF LINTING FAILED - run: ruff check tests/ functions/ --fix"
        exit 1
    fi
    
    # Security tests (with real database)
    log_info "Running RLS security tests..."
    if ! python -m pytest tests/db/test_rls.py -v; then
        log_error "RLS SECURITY TESTS FAILED"
        exit 1
    fi
    
    # Performance tests (if they exist)
    if [[ -f "tests/db/test_performance.py" ]]; then
        log_info "Running performance tests..."
        if ! python tests/db/test_performance.py; then
            log_warning "PERFORMANCE TESTS HAD SOME FAILURES - check tests/db/performance_report_*.json for details"
        else
            log_success "Performance tests passed"
        fi
    fi
    
    log_success "Python code quality tests passed"
}

# Phase 3: Flutter Application Testing
test_flutter() {
    log_info "📱 PHASE 3: Flutter Application"
    
    cd app
    
    # Dependencies
    log_info "Getting Flutter dependencies..."
    if ! flutter pub get; then
        log_error "FLUTTER PUB GET FAILED"
        exit 1
    fi
    
    # Static analysis
    log_info "Running Flutter static analysis..."
    if ! flutter analyze; then
        log_error "FLUTTER ANALYZE FAILED"
        exit 1
    fi
    
    # Full test suite
    log_info "Running Flutter tests..."
    if ! flutter test; then
        log_error "FLUTTER TESTS FAILED"
        exit 1
    fi
    
    cd ..
    log_success "Flutter application tests passed"
}

# Phase 4: Infrastructure Validation
test_infrastructure() {
    log_info "🏗️  PHASE 4: Infrastructure Validation"
    
    cd infra
    
    # Terraform initialization
    log_info "Initializing Terraform..."
    if ! terraform init -backend=false >/dev/null; then
        log_error "TERRAFORM INIT FAILED"
        exit 1
    fi
    
    # Terraform validation
    log_info "Validating Terraform configuration..."
    if ! terraform validate; then
        log_error "TERRAFORM VALIDATION FAILED"
        exit 1
    fi
    
    # Terraform format check
    log_info "Checking Terraform formatting..."
    if ! terraform fmt -check; then
        log_error "TERRAFORM FORMAT FAILED - run: terraform fmt"
        exit 1
    fi
    
    cd ..
    log_success "Infrastructure validation passed"
}

# Main execution flow
main() {
    echo ""
    log_info "Starting comprehensive testing pipeline..."
    echo ""
    
    check_dependencies
    test_database
    test_python
    test_flutter
    test_infrastructure
    
    echo ""
    echo "🎉 ALL LOCAL TESTS PASSED!"
    echo "✅ Safe to commit and push to GitHub"
    echo ""
    echo "Next steps:"
    echo "  1. git add ."
    echo "  2. git commit -m \"✅ All local tests passing\""
    echo "  3. git push origin main"
    echo ""
}

# Run main function
main "$@" 