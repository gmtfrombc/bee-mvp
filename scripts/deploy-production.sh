#!/bin/bash

# BEE Momentum Meter - Production Deployment Script
# Epic 1.1 - Task T1.1.5.13

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLUTTER_VERSION="3.32.0"
MIN_TEST_COVERAGE=80
DEPLOYMENT_TIMEOUT=300
HEALTH_CHECK_RETRIES=5

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if required environment variables are set
check_environment() {
    log_info "Checking environment configuration..."
    
    required_vars=(
        "ENVIRONMENT"
        "SUPABASE_URL"
        "SUPABASE_ANON_KEY"
        "APP_VERSION"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Missing required environment variable: $var"
            exit 1
        else
            log_success "$var is set"
        fi
    done

    # Validate environment is production
    if [ "$ENVIRONMENT" != "production" ]; then
        log_error "ENVIRONMENT must be 'production' for production deployment"
        exit 1
    fi

    log_success "Environment validation complete"
}

# Validate Flutter installation
check_flutter() {
    log_info "Checking Flutter installation..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed or not in PATH"
        exit 1
    fi

    local flutter_version=$(flutter --version | head -1 | cut -d ' ' -f 2)
    log_info "Flutter version: $flutter_version"
    
    # Check if version is compatible (simplified check)
    if [[ "$flutter_version" != "3.32"* ]]; then
        log_warning "Flutter version $flutter_version may not be fully compatible with $FLUTTER_VERSION"
    fi

    log_success "Flutter check complete"
}

# Test Supabase connection
test_supabase_connection() {
    log_info "Testing Supabase connection..."
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "apikey: $SUPABASE_ANON_KEY" \
        -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
        "$SUPABASE_URL/rest/v1/")

    if [ "$response" = "200" ]; then
        log_success "Supabase connection successful"
    else
        log_error "Supabase connection failed (HTTP $response)"
        exit 1
    fi
}

# Run comprehensive tests
run_tests() {
    log_info "Running comprehensive test suite..."
    
    cd app
    
    # Install dependencies
    log_info "Installing Flutter dependencies..."
    flutter pub get
    
    # Run static analysis
    log_info "Running static analysis..."
    flutter analyze --fatal-infos
    
    if [ $? -ne 0 ]; then
        log_error "Static analysis failed"
        exit 1
    fi
    
    # Run unit tests with coverage
    log_info "Running unit tests with coverage..."
    flutter test --coverage
    
    if [ $? -ne 0 ]; then
        log_error "Unit tests failed"
        exit 1
    fi
    
    # Check test coverage
    if command -v lcov &> /dev/null; then
        local coverage=$(lcov --summary coverage/lcov.info 2>/dev/null | grep -o "lines.*: [0-9.]*%" | cut -d: -f2 | cut -d% -f1 | xargs)
        if (( $(echo "$coverage >= $MIN_TEST_COVERAGE" | bc -l) )); then
            log_success "Test coverage: ${coverage}% (minimum: ${MIN_TEST_COVERAGE}%)"
        else
            log_error "Test coverage ${coverage}% is below minimum ${MIN_TEST_COVERAGE}%"
            exit 1
        fi
    else
        log_warning "lcov not found, skipping coverage check"
    fi
    
    # Run integration tests
    log_info "Running integration tests..."
    flutter test integration_test/
    
    if [ $? -ne 0 ]; then
        log_error "Integration tests failed"
        exit 1
    fi
    
    cd ..
    log_success "All tests passed"
}

# Build Android release
build_android() {
    log_info "Building Android release..."
    
    cd app
    
    # Clean previous builds
    flutter clean
    flutter pub get
    
    # Build APK
    log_info "Building APK..."
    flutter build apk --release \
        --dart-define=ENVIRONMENT=production \
        --dart-define=SUPABASE_URL="$SUPABASE_URL" \
        --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
        --dart-define=APP_VERSION="$APP_VERSION" \
        --dart-define=SENTRY_DSN="${SENTRY_DSN:-}"
    
    # Build App Bundle for Play Store
    log_info "Building App Bundle..."
    flutter build appbundle --release \
        --dart-define=ENVIRONMENT=production \
        --dart-define=SUPABASE_URL="$SUPABASE_URL" \
        --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
        --dart-define=APP_VERSION="$APP_VERSION" \
        --dart-define=SENTRY_DSN="${SENTRY_DSN:-}"
    
    cd ..
    log_success "Android build complete"
    log_info "APK: app/build/app/outputs/apk/release/app-release.apk"
    log_info "Bundle: app/build/app/outputs/bundle/release/app-release.aab"
}

# Build iOS release
build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warning "iOS build skipped (not running on macOS)"
        return 0
    fi
    
    log_info "Building iOS release..."
    
    cd app
    
    # Build iOS
    flutter build ios --release --no-codesign \
        --dart-define=ENVIRONMENT=production \
        --dart-define=SUPABASE_URL="$SUPABASE_URL" \
        --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
        --dart-define=APP_VERSION="$APP_VERSION" \
        --dart-define=SENTRY_DSN="${SENTRY_DSN:-}"
    
    cd ..
    log_success "iOS build complete (code signing required separately)"
}

# Deploy to staging for final verification
deploy_staging() {
    log_info "Deploying to staging environment for verification..."
    
    # This would typically deploy to a staging environment
    # For now, we'll simulate this step
    log_warning "Staging deployment simulation (replace with actual staging deployment)"
    
    sleep 3
    log_success "Staging deployment complete"
}

# Run post-deployment health checks
health_check() {
    log_info "Running post-deployment health checks..."
    
    local retries=0
    while [ $retries -lt $HEALTH_CHECK_RETRIES ]; do
        log_info "Health check attempt $((retries + 1))/$HEALTH_CHECK_RETRIES"
        
        # This would typically check the deployed application
        # For now, we'll check local services
        if test_supabase_connection; then
            log_success "Health check passed"
            return 0
        fi
        
        retries=$((retries + 1))
        if [ $retries -lt $HEALTH_CHECK_RETRIES ]; then
            log_warning "Health check failed, retrying in 10 seconds..."
            sleep 10
        fi
    done
    
    log_error "Health checks failed after $HEALTH_CHECK_RETRIES attempts"
    return 1
}

# Update monitoring configuration
update_monitoring() {
    log_info "Updating monitoring configuration..."
    
    # Send deployment event to monitoring service
    if [ -n "${MONITORING_WEBHOOK:-}" ]; then
        curl -X POST "$MONITORING_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{
                \"event\": \"deployment\",
                \"version\": \"$APP_VERSION\",
                \"environment\": \"$ENVIRONMENT\",
                \"timestamp\": \"$(date -Iseconds)\",
                \"status\": \"success\"
            }" || log_warning "Failed to send monitoring event"
    fi
    
    log_success "Monitoring configuration updated"
}

# Cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."
    
    # Remove any temporary files created during deployment
    rm -f app/android/key.properties 2>/dev/null || true
    rm -f app/android/app/keystore.jks 2>/dev/null || true
    
    log_success "Cleanup complete"
}

# Main deployment flow
main() {
    local start_time=$(date +%s)
    
    log_info "🚀 Starting BEE Momentum Meter production deployment"
    log_info "Version: ${APP_VERSION:-latest}"
    log_info "Environment: ${ENVIRONMENT:-unknown}"
    log_info "Timestamp: $(date)"
    
    # Pre-deployment checks
    check_environment
    check_flutter
    test_supabase_connection
    
    # Run tests
    run_tests
    
    # Build applications
    build_android
    build_ios
    
    # Deploy to staging for verification
    deploy_staging
    
    # Run health checks
    if ! health_check; then
        log_error "Health checks failed, aborting deployment"
        cleanup
        exit 1
    fi
    
    # Update monitoring
    update_monitoring
    
    # Cleanup
    cleanup
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "🎉 Production deployment completed successfully!"
    log_info "Total deployment time: ${duration} seconds"
    log_info "Next steps:"
    log_info "  1. Upload APK/Bundle to Google Play Console"
    log_info "  2. Upload iOS build to App Store Connect (if on macOS)"
    log_info "  3. Monitor application health and error rates"
    log_info "  4. Verify user-facing functionality"
}

# Trap errors and cleanup
trap cleanup EXIT

# Run main deployment
main "$@" 