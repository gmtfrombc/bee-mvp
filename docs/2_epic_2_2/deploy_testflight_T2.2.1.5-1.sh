#!/bin/bash

# T2.2.1.5-1: TestFlight Deployment Script for Principal Tester Enrollment
# BEE MVP - Wearable Integration Layer
# 
# This script automates the TestFlight deployment process for T2.2.1.5-1
# principal tester enrollment with Garmin Connect integration validation.

set -e  # Exit on any error

# Configuration
APP_NAME="MomentumCoach"
BUNDLE_ID="com.momentumhealth.beemvp"
VERSION="1.1.0"
BUILD_NUMBER="2"
TEAM_ID="U9TVC3GYP2"
PROD_SUPABASE_URL="https://your-production-supabase-url.com"
PROD_ANON_KEY="your-production-anon-key"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites for T2.2.1.5-1 deployment..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode is not installed or not in PATH"
        exit 1
    fi
    
    # Check current directory
    if [[ ! -f "pubspec.yaml" ]]; then
        log_error "This script must be run from the app directory"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Verify wearable integration setup
verify_wearable_setup() {
    log_info "Verifying wearable integration setup..."
    
    # Check iOS entitlements
    if [[ ! -f "ios/Runner/Runner.entitlements" ]]; then
        log_error "iOS Runner.entitlements not found"
        exit 1
    fi
    
    # Check Health permission strings
    if ! grep -q "NSHealthShareUsageDescription" ios/Runner/Info.plist; then
        log_error "Health permissions not configured in Info.plist"
        exit 1
    fi
    
    # Check wearable data repository exists
    if [[ ! -f "lib/core/services/wearable_data_repository.dart" ]]; then
        log_error "WearableDataRepository not found"
        exit 1
    fi
    
    log_success "Wearable integration setup verified"
}

# Clean and prepare build
prepare_build() {
    log_info "Preparing build environment..."
    
    # Clean previous builds
    flutter clean
    
    # Get dependencies
    flutter pub get
    
    # Install CocoaPods dependencies
    cd ios && pod install && cd ..
    
    log_success "Build environment prepared"
}

# Build iOS for TestFlight
build_ios() {
    log_info "Building iOS app for TestFlight..."
    
    # Build iOS release
    flutter build ios --release --no-codesign \
        --dart-define="ENVIRONMENT=production" \
        --dart-define="SUPABASE_URL=$PROD_SUPABASE_URL" \
        --dart-define="SUPABASE_ANON_KEY=$PROD_ANON_KEY" \
        --dart-define="APP_VERSION=$VERSION"
    
    if [[ $? -eq 0 ]]; then
        log_success "iOS build completed successfully"
    else
        log_error "iOS build failed"
        exit 1
    fi
}

# Open Xcode for archiving
open_xcode() {
    log_info "Opening Xcode for manual archiving..."
    
    log_warning "MANUAL STEPS REQUIRED:"
    echo "1. Xcode will open with the Runner.xcworkspace"
    echo "2. Select 'Runner' target and 'Any iOS Device'"
    echo "3. Go to Product → Archive"
    echo "4. Once archive completes, distribute to TestFlight"
    echo "5. Upload to App Store Connect"
    
    # Open Xcode workspace
    open ios/Runner.xcworkspace
    
    log_info "Waiting for manual Xcode archiving..."
    read -p "Press Enter after completing Xcode archiving and upload..."
}

# Create validation report template
create_validation_report() {
    log_info "Creating validation report template..."
    
    REPORT_FILE="docs/2_epic_2_2/validation_screenshots/T2.2.1.5-1_validation_report.md"
    
    cat > "$REPORT_FILE" << EOF
# T2.2.1.5-1 Principal Tester Enrollment Validation Report

**Date**: $(date +"%Y-%m-%d")
**Tester**: [Your Name]
**Device**: [iPhone Model, iOS Version]
**Garmin Device**: [Garmin Model, Firmware Version]
**App Version**: $APP_NAME v$VERSION (build $BUILD_NUMBER)

## Enrollment Success Metrics
- [ ] TestFlight installation: SUCCESS/FAILURE
- [ ] Garmin Connect setup: SUCCESS/FAILURE  
- [ ] Apple Health integration: SUCCESS/FAILURE
- [ ] BEE MVP health permissions: SUCCESS/FAILURE
- [ ] Real-time data sync: SUCCESS/FAILURE

## Data Quality Baseline
- **Steps Today**: [Number] steps
- **Heart Rate Last Reading**: [BPM] at [Time]
- **Sleep Last Night**: [Hours] hours
- **Last Garmin Sync**: [Time]
- **Last Health App Update**: [Time]

## Issues Identified
- [List any issues encountered]
- [Include screenshots of errors if applicable]

## Screenshots Captured
- [ ] health_summary_baseline_$(date +"%Y%m%d").png
- [ ] health_activity_baseline_$(date +"%Y%m%d").png  
- [ ] health_heart_baseline_$(date +"%Y%m%d").png
- [ ] health_sleep_baseline_$(date +"%Y%m%d").png
- [ ] health_sources_baseline_$(date +"%Y%m%d").png
- [ ] app_health_dashboard_$(date +"%Y%m%d").png

## Validation Results
- **TestFlight Deployment**: ✅ COMPLETE
- **Health Integration**: ⏳ PENDING TESTING
- **Data Pipeline**: ⏳ PENDING VALIDATION
- **Screenshots**: ⏳ PENDING CAPTURE

## Next Steps
1. Install app from TestFlight
2. Configure Garmin Connect → Apple Health integration
3. Grant health permissions in BEE MVP app
4. Capture baseline screenshots
5. Complete validation testing

**Task Status**: 🔄 IN PROGRESS
**Completion**: ⏳ PENDING MANUAL TESTING
EOF

    log_success "Validation report template created: $REPORT_FILE"
}

# Main deployment function
main() {
    log_info "Starting T2.2.1.5-1 TestFlight deployment process..."
    echo "═══════════════════════════════════════════════════════════════"
    echo "BEE MVP - Wearable Integration Layer"
    echo "Task: T2.2.1.5-1 Principal Tester Enrollment"
    echo "═══════════════════════════════════════════════════════════════"
    
    # Execute deployment steps
    check_prerequisites
    verify_wearable_setup
    prepare_build
    build_ios
    create_validation_report
    
    log_success "Automated deployment steps completed!"
    echo ""
    log_warning "NEXT STEPS FOR MANUAL COMPLETION:"
    echo "1. Complete Xcode archiving and TestFlight upload"
    echo "2. Follow the execution checklist: docs/2_epic_2_2/validation_screenshots/T2.2.1.5-1_execution_checklist.md"
    echo "3. Use the validation report template: docs/2_epic_2_2/validation_screenshots/T2.2.1.5-1_validation_report.md"
    echo "4. Update task status to ✅ Complete when validation is finished"
    
    # Optionally open Xcode
    read -p "Open Xcode now for archiving? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open_xcode
    fi
    
    log_success "T2.2.1.5-1 deployment preparation complete!"
}

# Execute main function
main "$@" 