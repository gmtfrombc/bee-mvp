# Component Size Governance System

**Project:** BEE App - Component Architecture Guidelines  
**Version:** 1.0  
**Implemented:** Sprint 5 - Automated Size Governance  
**Status:** Active

## Overview

The Component Size Governance System enforces architectural guidelines through automated tools and processes to maintain code quality, prevent technical debt, and ensure consistent component architecture across the BEE application.

## Size Guidelines

### Established Limits

| Component Type | Line Limit | Rationale |
|----------------|------------|-----------|
| **Services** | ≤500 lines | Maintain single responsibility, testability |
| **UI Widgets** | ≤300 lines | Promote reusability, reduce complexity |
| **Screen Components** | ≤400 lines | Allow for complex layouts while maintaining structure |
| **Modal Components** | ≤250 lines | Ensure focused, lightweight modals |
| **Models** | Flexible | Complex data structures acceptable |

### Compliance Tracking

- **Target Compliance Rate:** 100%
- **Critical Threshold:** >50% over limit requires immediate action
- **Warning Threshold:** >20% over limit requires planning

## Automated Governance Tools

### 1. Pre-commit Hooks

**Location:** `.git/hooks/pre-commit`  
**Purpose:** Prevent oversized components from being committed

```bash
# Manual installation (if needed)
chmod +x .git/hooks/pre-commit
```

**Features:**
- Checks all staged Dart files
- Categorizes files by type (service, widget, screen, modal)
- Blocks commits with violations
- Provides clear violation reports
- Offers bypass option (not recommended)

**Usage:**
```bash
# Normal commit (automatic check)
git commit -m "Feature: Add new component"

# Bypass check (emergency only)
git commit --no-verify -m "Emergency fix"
```

### 2. Manual Size Checking

**Script:** `scripts/check_component_sizes.sh`  
**Purpose:** Quick compliance verification

```bash
# Run component size check
./scripts/check_component_sizes.sh
```

**Features:**
- Comprehensive file scanning
- Color-coded terminal output
- Violation percentage calculation
- Compliance summary report
- Exit code for automation (0=pass, 1=fail)

### 3. Weekly Audit Reports

**Script:** `scripts/component_size_audit.sh`  
**Purpose:** Detailed compliance reporting

```bash
# Generate weekly report
./scripts/component_size_audit.sh

# Custom output file
./scripts/component_size_audit.sh --output-file custom_report.md
```

**Report Features:**
- Executive summary with compliance rates
- Category-wise violation breakdown
- Detailed file listings
- Recommended actions
- Trending analysis (future enhancement)

### 4. CI/CD Integration

**Workflow:** `.github/workflows/ci.yml`  
**Purpose:** Automated enforcement in build pipeline

**Features:**
- **Build Blocking:** Fails builds with size violations
- **PR Comments:** Automatic component size reports on pull requests
- **Artifact Generation:** Detailed reports uploaded for review
- **Early Detection:** Catches violations before merge

**Integration Points:**
1. **Early Check:** Size validation runs before other tests
2. **Build Failure:** Prevents deployment of non-compliant code
3. **PR Reporting:** Provides detailed analysis in pull request comments
4. **Artifact Storage:** Stores reports for historical analysis

## Developer Workflow

### Creating New Components

```bash
# 1. Check current compliance
./scripts/check_component_sizes.sh

# 2. Create component following guidelines
# (see component size limits above)

# 3. Commit with automatic validation
git add .
git commit -m "Add new component"  # Pre-commit hook runs automatically

# 4. Push and create PR
git push origin feature-branch
# CI/CD will run size checks and generate reports
```

### Handling Size Violations

#### Immediate Actions (Critical Violations: >50% over limit)

1. **Extract Components:**
   ```dart
   // Before: Large widget (400+ lines)
   class ComplexWidget extends StatelessWidget {
     // 400+ lines of code
   }
   
   // After: Extracted components
   class ComplexWidget extends StatelessWidget {
     // ~200 lines - main structure
   }
   
   class ComplexWidgetHeader extends StatelessWidget {
     // ~100 lines - header logic
   }
   
   class ComplexWidgetBody extends StatelessWidget {
     // ~100 lines - body logic
   }
   ```

2. **Service Decomposition:**
   ```dart
   // Before: Monolithic service (600+ lines)
   class LargeService {
     // 600+ lines of mixed responsibilities
   }
   
   // After: Focused services
   class CoreService {           // ~300 lines - core logic
   class HelperService {         // ~200 lines - helper functions
   class ValidationService {     // ~150 lines - validation logic
   ```

#### Planning Actions (Moderate Violations: 20-50% over limit)

1. **Schedule Refactoring:** Add to technical debt backlog
2. **Monitor Growth:** Track file size in subsequent changes
3. **Extract Incrementally:** Plan component extractions
4. **Document Dependencies:** Map refactoring requirements

### Bypass Procedures (Emergency Only)

```bash
# Emergency bypass (avoid when possible)
git commit --no-verify -m "Emergency fix: Critical bug"

# Follow up immediately
echo "TODO: Refactor oversized component" >> technical_debt.md
```

## Monitoring and Reporting

### Real-time Monitoring

- **Pre-commit Hooks:** Immediate feedback during development
- **IDE Integration:** Size awareness through linting configuration
- **CI/CD Pipeline:** Automated enforcement in build process

### Periodic Reporting

- **Weekly Audits:** Comprehensive compliance reports
- **Sprint Reviews:** Component size metrics in retrospectives
- **Quarterly Analysis:** Architecture evolution trends

### Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Overall Compliance Rate | 100% | TBD | 📊 |
| Service Compliance | 100% | TBD | 📊 |
| Widget Compliance | 100% | TBD | 📊 |
| Screen Compliance | 100% | TBD | 📊 |
| Modal Compliance | 100% | TBD | 📊 |

## Configuration

### Analysis Options

**File:** `app/analysis_options.yaml`

```yaml
# Component size governance documentation
# Automated checking via scripts and CI/CD
# See: docs/architecture/component_governance.md
```

### GitHub Actions

**File:** `.github/workflows/ci.yml`

Key integration points:
- Component Size Compliance Check (early in pipeline)
- PR Comment Generation (for pull requests)
- Artifact Upload (detailed reports)

## Troubleshooting

### Common Issues

#### Pre-commit Hook Not Running

```bash
# Check hook exists and is executable
ls -la .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

#### False Positives

```bash
# Review file classification logic in hook
# Adjust patterns if needed for edge cases
```

#### CI/CD Failures

```bash
# Check script permissions
chmod +x scripts/check_component_sizes.sh
chmod +x scripts/component_size_audit.sh

# Test locally
./scripts/check_component_sizes.sh
```

### Override Procedures

**Temporary Overrides:**
- Use `git commit --no-verify` for emergency fixes
- Immediately plan refactoring after override
- Document in technical debt tracking

**Permanent Exemptions:**
- Update script logic for legitimate exceptions
- Document rationale in architecture decisions
- Consider if guidelines need adjustment

## Evolution and Maintenance

### Future Enhancements

1. **Trending Analysis:** Historical compliance tracking
2. **Complexity Metrics:** Beyond line count (cyclomatic complexity)
3. **Automated Refactoring:** AI-assisted component extraction
4. **Performance Correlation:** Size vs. performance metrics

### Maintenance Tasks

- **Monthly:** Review compliance reports for trends
- **Quarterly:** Assess guideline effectiveness
- **Bi-annually:** Update tools and automation
- **Annually:** Comprehensive architecture review

## Success Metrics

### Quantitative Goals

- **100% Compliance Rate:** All components within guidelines
- **Zero Critical Violations:** No components >50% over limit
- **Reduced Time-to-Understanding:** Faster onboarding/debugging
- **Improved Test Coverage:** Smaller components = easier testing

### Qualitative Benefits

- **Developer Experience:** Easier component modification
- **Code Maintainability:** Clear separation of concerns
- **Technical Debt Reduction:** Proactive architecture management
- **Team Productivity:** Consistent architectural patterns

---

## Quick Reference

### Commands

```bash
# Quick size check
./scripts/check_component_sizes.sh

# Generate detailed report
./scripts/component_size_audit.sh

# Test pre-commit hook
git add . && git commit -m "Test"

# Bypass hook (emergency)
git commit --no-verify -m "Emergency fix"
```

### Guidelines Summary

- **Services:** ≤500 lines
- **Widgets:** ≤300 lines
- **Screens:** ≤400 lines
- **Modals:** ≤250 lines

### Resources

- **Refactoring Guide:** `docs/refactor/component_size_audit_refactor_plan.md`
- **Architecture Guidelines:** This document
- **Implementation Examples:** Sprint 1-4 refactoring examples 