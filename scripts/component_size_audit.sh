#!/bin/bash

# Weekly Component Size Audit Script
# BEE App - Component Size Audit & Refactor
# 
# Generates comprehensive size reports for weekly monitoring
# Usage: ./scripts/component_size_audit.sh [--output-file report.md]

set -e

# Default output file
OUTPUT_FILE="component_size_audit_report.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-file)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--output-file report.md]"
            echo "Generates weekly component size audit report"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 BEE Component Size Weekly Audit${NC}"
echo -e "${BLUE}Generating report: ${OUTPUT_FILE}${NC}"
echo "======================================"

# Initialize report
cat > "$OUTPUT_FILE" << EOF
# BEE Component Size Audit Report

**Generated:** $TIMESTAMP  
**Audit Type:** Weekly Automated Report  
**Guidelines:** Services ≤500 lines, UI Components ≤300 lines, Screens ≤400 lines, Modals ≤250 lines

## Executive Summary

EOF

# Initialize counters
TOTAL_VIOLATIONS=0
TOTAL_FILES=0
SERVICE_VIOLATIONS=0
WIDGET_VIOLATIONS=0
SCREEN_VIOLATIONS=0
MODAL_VIOLATIONS=0

# Function to audit file category
audit_category() {
    local pattern="$1"
    local limit="$2"
    local type="$3"
    local description="$4"
    local category_violations=0
    local category_files=0
    
    echo -e "\n${BLUE}Auditing ${description}...${NC}"
    
    # Create temporary file for violations
    local temp_violations=$(mktemp)
    local temp_compliant=$(mktemp)
    
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            local lines=$(wc -l < "$file")
            category_files=$((category_files + 1))
            
            if [[ $lines -gt $limit ]]; then
                local violation_percent=$(( (lines * 100 / limit) - 100 ))
                echo "| $(basename "$file") | $lines | $limit | ${violation_percent}% over |" >> "$temp_violations"
                category_violations=$((category_violations + 1))
                echo -e "${RED}❌ ${file}: ${lines} lines (${violation_percent}% over)${NC}"
            else
                echo "| $(basename "$file") | $lines | $limit | ✅ Compliant |" >> "$temp_compliant"
                echo -e "${GREEN}✅ ${file}: ${lines} lines${NC}"
            fi
        fi
    done < <(find app/lib -path "$pattern" -name "*.dart" -print0 2>/dev/null)
    
    # Add to report
    {
        echo ""
        echo "### ${description}"
        echo ""
        echo "**Limit:** ${limit} lines  "
        echo "**Files Audited:** ${category_files}  "
        echo "**Violations:** ${category_violations}  "
        echo "**Compliance Rate:** $(( (category_files - category_violations) * 100 / (category_files > 0 ? category_files : 1) ))%"
        echo ""
        
        if [[ $category_violations -gt 0 ]]; then
            echo "#### Violations"
            echo ""
            echo "| File | Lines | Limit | Status |"
            echo "|------|-------|-------|--------|"
            cat "$temp_violations"
            echo ""
        fi
        
        if [[ -s "$temp_compliant" ]]; then
            echo "#### Compliant Files"
            echo ""
            echo "| File | Lines | Limit | Status |"
            echo "|------|-------|-------|--------|"
            head -10 "$temp_compliant"  # Show first 10 compliant files
            local remaining=$(( $(wc -l < "$temp_compliant") - 10 ))
            if [[ $remaining -gt 0 ]]; then
                echo "| ... | ... | ... | ... $remaining more compliant files |"
            fi
            echo ""
        fi
    } >> "$OUTPUT_FILE"
    
    # Update counters
    case $type in
        service) SERVICE_VIOLATIONS=$category_violations ;;
        widget) WIDGET_VIOLATIONS=$category_violations ;;
        screen) SCREEN_VIOLATIONS=$category_violations ;;
        modal) MODAL_VIOLATIONS=$category_violations ;;
    esac
    
    TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + category_violations))
    TOTAL_FILES=$((TOTAL_FILES + category_files))
    
    # Cleanup
    rm -f "$temp_violations" "$temp_compliant"
}

# Audit each category
audit_category "*service*.dart" 500 "service" "Services"
audit_category "*/presentation/widgets/*" 300 "widget" "UI Widgets"
audit_category "*/presentation/screens/*" 400 "screen" "Screen Components"
audit_category "*modal*.dart" 250 "modal" "Modal Components"

# Generate executive summary
COMPLIANCE_RATE=$(( (TOTAL_FILES - TOTAL_VIOLATIONS) * 100 / (TOTAL_FILES > 0 ? TOTAL_FILES : 1) ))

# Update executive summary in report
{
    echo "**Total Files Audited:** $TOTAL_FILES  "
    echo "**Total Violations:** $TOTAL_VIOLATIONS  "
    echo "**Overall Compliance Rate:** ${COMPLIANCE_RATE}%"
    echo ""
    echo "| Category | Violations | Compliance |"
    echo "|----------|------------|------------|"
    echo "| Services | $SERVICE_VIOLATIONS | $(( SERVICE_VIOLATIONS == 0 ? 100 : 0 ))% |"
    echo "| Widgets | $WIDGET_VIOLATIONS | $(( WIDGET_VIOLATIONS == 0 ? 100 : 0 ))% |"
    echo "| Screens | $SCREEN_VIOLATIONS | $(( SCREEN_VIOLATIONS == 0 ? 100 : 0 ))% |"
    echo "| Modals | $MODAL_VIOLATIONS | $(( MODAL_VIOLATIONS == 0 ? 100 : 0 ))% |"
    echo ""
    
    if [[ $TOTAL_VIOLATIONS -eq 0 ]]; then
        echo "🎉 **STATUS: FULLY COMPLIANT** - All components meet size guidelines!"
    else
        echo "⚠️ **STATUS: VIOLATIONS DETECTED** - $TOTAL_VIOLATIONS components require refactoring"
        echo ""
        echo "## Recommended Actions"
        echo ""
        echo "1. **Immediate:** Review and refactor critical violations (>50% over limit)"
        echo "2. **Short-term:** Plan refactoring for moderate violations (20-50% over limit)"  
        echo "3. **Long-term:** Monitor and prevent new violations through automated governance"
        echo ""
        echo "**Reference:** [Component Size Audit Refactor Plan](docs/refactor/component_size_audit_refactor_plan.md)"
    fi
    
    echo ""
    echo "## Trending Analysis"
    echo ""
    echo "*Note: Historical trending requires multiple audit runs. Future reports will include:*"
    echo "- Week-over-week violation trends"
    echo "- Component growth patterns"
    echo "- Refactoring success metrics"
    echo ""
    echo "## Tools & Automation"
    echo ""
    echo "- **Manual Check:** \`./scripts/check_component_sizes.sh\`"
    echo "- **Pre-commit Hook:** Automatic size checking on commits"
    echo "- **CI/CD Integration:** Size validation in GitHub Actions"
    echo "- **Weekly Reports:** Automated via this script"
    
} >> "$OUTPUT_FILE"

# Terminal summary
echo -e "\n${BLUE}============================================${NC}"
echo -e "${BLUE}Weekly Audit Summary${NC}"
echo -e "${BLUE}============================================${NC}"

if [[ $TOTAL_VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}🎉 SUCCESS: All ${TOTAL_FILES} components comply with size guidelines!${NC}"
    echo -e "${GREEN}Overall compliance rate: ${COMPLIANCE_RATE}%${NC}"
else
    echo -e "${RED}❌ VIOLATIONS: ${TOTAL_VIOLATIONS}/${TOTAL_FILES} components violate guidelines${NC}"
    echo -e "${YELLOW}Overall compliance rate: ${COMPLIANCE_RATE}%${NC}"
    echo -e "${BLUE}📊 Report generated: ${OUTPUT_FILE}${NC}"
fi

echo -e "\n${BLUE}📖 Full report: ${OUTPUT_FILE}${NC}"
echo -e "${BLUE}🔧 Quick check: ./scripts/check_component_sizes.sh${NC}" 