#!/bin/bash

# Component Size Checking Script
# BEE App - Component Size Audit & Refactor
# Usage: ./scripts/check_component_sizes.sh [--warn-only]
#        REFACTOR_MODE=true ./scripts/check_component_sizes.sh

set -e  # Exit on any error

# Parse command line arguments
WARN_ONLY=false
for arg in "$@"; do
    case $arg in
        --warn-only)
            WARN_ONLY=true
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# Check for refactor mode environment variable
if [[ "${REFACTOR_MODE:-false}" == "true" ]]; then
    WARN_ONLY=true
fi

echo "🔍 BEE Component Size Compliance Check"
if [[ "$WARN_ONLY" == "true" ]]; then
    echo "⚠️  REFACTOR MODE: Violations will be reported as warnings"
fi
echo "======================================="

# Initialize counters
VIOLATIONS=0
TOTAL_FILES=0

# === Hard-fail ceilings ===
SERVICE_CEILING=750
WIDGET_CEILING=450
SCREEN_CEILING=600
MODAL_CEILING=375

# Toggle via env var; default false
HARD_FAIL=${HARD_FAIL:-false}

# Initialize hard-fail counter
HARD_FAIL_COUNT=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check file size compliance
check_files() {
    local pattern="$1"
    local limit="$2"
    local type="$3"
    local description="$4"
    
    echo -e "\n${BLUE}Checking ${description}...${NC}"
    
    local violations=0
    local files=0
    
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            lines=$(wc -l < "$file")
            files=$((files + 1))

            # Determine hard-fail ceiling based on component type
            local ceiling=0
            case "$type" in
                service)
                    ceiling=$SERVICE_CEILING
                    ;;
                widget)
                    ceiling=$WIDGET_CEILING
                    ;;
                screen)
                    ceiling=$SCREEN_CEILING
                    ;;
                modal)
                    ceiling=$MODAL_CEILING
                    ;;
            esac

            if grep -q "@size-exempt" "$file"; then
                echo -e "${YELLOW}⚠️  SKIP: $file is marked as @size-exempt${NC}"
                continue
            fi

            if [[ $lines -gt $limit ]]; then
                local violation_percent=$(( (lines * 100 / limit) - 100 ))
                echo -e "${RED}❌ VIOLATION: ${file}${NC}"
                echo -e "   Lines: ${lines} (${violation_percent}% over ${limit}-line limit)"
                violations=$((violations + 1))
            fi

            # Hard-fail ceiling check
            if [[ $lines -gt $ceiling ]]; then
                HARD_FAIL_COUNT=$((HARD_FAIL_COUNT + 1))
                echo "❌ HARD-FAIL candidate: $file – ${lines} LOC ($ceiling allowed)"
            fi
        fi
    done < <(find app/lib -path "$pattern" -name "*.dart" -print0 2>/dev/null)
    
    if [[ $violations -eq 0 ]]; then
        echo -e "${GREEN}✅ All ${files} ${type} files comply with ${limit}-line limit${NC}"
    else
        echo -e "${RED}❌ ${violations}/${files} ${type} files violate ${limit}-line limit${NC}"
    fi
    
    VIOLATIONS=$((VIOLATIONS + violations))
    TOTAL_FILES=$((TOTAL_FILES + files))
}

# Check Services (≤500 lines)
check_files "*service*.dart" 500 "service" "Services (≤500 lines)"

# Check UI Widgets (≤300 lines) - excluding screens and modals
check_files "*/presentation/widgets/*" 300 "widget" "UI Widgets (≤300 lines)"

# Check Screen Components (≤400 lines)
check_files "*/presentation/screens/*" 400 "screen" "Screen Components (≤400 lines)"

# Check Modal Components (≤250 lines)
check_files "*modal*.dart" 250 "modal" "Modal Components (≤250 lines)"

# Additional specific checks for known large files
echo -e "\n${BLUE}Checking specific critical components...${NC}"

# TodayFeedTile check
FEED_TILE="app/lib/features/today_feed/presentation/widgets/today_feed_tile.dart"
if [[ -f "$FEED_TILE" ]]; then
    lines=$(wc -l < "$FEED_TILE")
    if [[ $lines -gt 300 ]]; then
        echo -e "${RED}❌ CRITICAL: TodayFeedTile: ${lines} lines (exceeds 300-line widget limit)${NC}"
        VIOLATIONS=$((VIOLATIONS + 1))
    else
        echo -e "${GREEN}✅ TodayFeedTile: ${lines} lines (within widget limit)${NC}"
    fi
fi

# CoachDashboardScreen check
DASHBOARD="app/lib/features/momentum/presentation/screens/coach_dashboard_screen.dart"
if [[ -f "$DASHBOARD" ]]; then
    lines=$(wc -l < "$DASHBOARD")
    if [[ $lines -gt 400 ]]; then
        echo -e "${RED}❌ CRITICAL: CoachDashboardScreen: ${lines} lines (exceeds 400-line screen limit)${NC}"
        VIOLATIONS=$((VIOLATIONS + 1))
    else
        echo -e "${GREEN}✅ CoachDashboardScreen: ${lines} lines (within screen limit)${NC}"
    fi
fi

# Summary report
echo -e "\n${BLUE}============================================${NC}"
echo -e "${BLUE}Component Size Compliance Summary${NC}"
echo -e "============================================${NC}"

if [[ "$HARD_FAIL" == true && $HARD_FAIL_COUNT -gt 0 ]]; then
    echo -e "${RED}❌ HARD-FAIL: ${HARD_FAIL_COUNT} component(s) exceed hard ceiling limits${NC}"
    exit 1
fi

if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}🎉 SUCCESS: All ${TOTAL_FILES} components comply with size guidelines!${NC}"
    echo -e "${GREEN}✅ Services: ≤500 lines${NC}"
    echo -e "${GREEN}✅ Widgets: ≤300 lines${NC}" 
    echo -e "${GREEN}✅ Screens: ≤400 lines${NC}"
    echo -e "${GREEN}✅ Modals: ≤250 lines${NC}"
    exit 0
else
    if [[ "$WARN_ONLY" == "true" ]]; then
        echo -e "${YELLOW}⚠️  REFACTOR MODE: ${VIOLATIONS} component(s) exceed size guidelines${NC}"
        echo -e "${YELLOW}📋 Guidelines (enforced after refactor):${NC}"
        echo -e "   Services: ≤500 lines"
        echo -e "   Widgets: ≤300 lines"
        echo -e "   Screens: ≤400 lines" 
        echo -e "   Modals: ≤250 lines"
        echo -e "\n${BLUE}🔄 Currently in refactor mode - CI will pass${NC}"
        echo -e "${BLUE}📖 See: docs/refactor/notification_system_refactor/sprint_0_setup.md${NC}"
        exit 0
    else
        echo -e "${RED}❌ FAILURE: ${VIOLATIONS} component(s) violate size guidelines${NC}"
        echo -e "${YELLOW}📋 Guidelines:${NC}"
        echo -e "   Services: ≤500 lines"
        echo -e "   Widgets: ≤300 lines"
        echo -e "   Screens: ≤400 lines" 
        echo -e "   Modals: ≤250 lines"
        echo -e "\n${YELLOW}🔧 Recommended Actions:${NC}"
        echo -e "   1. Extract components following established patterns"
        echo -e "   2. Use service extraction for oversized services"
        echo -e "   3. Decompose complex widgets into smaller components"
        echo -e "   4. Review component_architecture_guidelines.md"
        echo -e "\n${BLUE}📖 See: docs/refactor/component_size_audit_refactor_plan.md${NC}"
        exit 1
    fi
fi 