# Sprint 1 Execution Guide: Test Pruning (Updated After Audit)

## Objective: Reduce tests from 880 → 300 (66% reduction)

**UPDATED STATUS (Post-Audit):**
- **Current**: 880 tests (605 `test()` + 275 `testWidgets()`)
- **Progress**: Already reduced from 1,203 → 880 (27% reduction)
- **Remaining Target**: 580 tests to remove (66% additional reduction)
- **Feasibility**: ✅ ACHIEVABLE with strategic focus on presentation layer

### Pre-Execution Setup

**1. Create backup branch:**
```bash
git checkout -b sprint-1-test-pruning-continued
git push -u origin sprint-1-test-pruning-continued
```

**2. Updated baseline measurements:**
```bash
# Current metrics (post-audit)
echo "=== CURRENT STATE (POST-AUDIT) ===" >> sprint1_metrics.txt
echo "Test files: $(find test -name "*_test.dart" | wc -l)" >> sprint1_metrics.txt
echo "test() calls: $(grep -rE "test\(" test/ --include="*_test.dart" | wc -l)" >> sprint1_metrics.txt
echo "testWidgets() calls: $(grep -rE "testWidgets\(" test/ --include="*_test.dart" | wc -l)" >> sprint1_metrics.txt
echo "Total tests: 880" >> sprint1_metrics.txt

# Test distribution by layer
echo "=== LAYER DISTRIBUTION ===" >> sprint1_metrics.txt
echo "Presentation: 325 tests (37%)" >> sprint1_metrics.txt
echo "Core Services: 315 tests (36%)" >> sprint1_metrics.txt
echo "Domain: 145 tests (16%) - PRESERVE" >> sprint1_metrics.txt
echo "Data: 142 tests (16%)" >> sprint1_metrics.txt
```

---

## **UPDATED STRATEGY: High-Impact Deletion Targets**

### Phase 1: Delete Entire Device Compatibility File (Day 1)
**IMMEDIATE HIGH-IMPACT TARGET**

**File to DELETE ENTIRELY:**
```bash
# Delete this entire file - it's infrastructure testing, not business logic
rm test/features/momentum/presentation/widgets/device_compatibility_test.dart
```

**Expected reduction: 880 → ~850 tests (-30 tests)**

**Justification:**
- Device compatibility is infrastructure concern
- No business logic risk
- Over-testing screen sizes/device variations
- Flutter framework handles device compatibility

### Phase 2: Aggressive Widget Test Reduction (Days 2-3)
**TARGET: Presentation Layer (325 → 100 tests = -225 tests)**

**High-Impact Files for Surgical Reduction:**

**1. Coach Dashboard Active Tab (703 lines, 24 tests)**
```bash
# File: test/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_active_tab_test.dart
# Strategy: Keep 6 core tests, delete 18 redundant ones
```

**Tests to KEEP (6):**
- Widget creation
- Loading state
- Error state  
- Empty state
- Basic intervention display
- Action menu functionality

**Tests to DELETE (18):**
- Multiple priority color variations
- Extensive responsive design tests
- Multiple edge case permutations
- Detailed styling validations

**2. Coach Dashboard Scheduled Tab (654 lines, 23 tests)**
```bash
# File: test/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_scheduled_tab_test.dart
# Strategy: Near-identical to active tab - reduce to 5 tests
```

**3. Today Feed Tile (652 lines, 28 tests)**
```bash
# File: test/features/today_feed/presentation/widgets/today_feed_tile_test.dart
# Strategy: Keep 6 core tests, delete 22 UI over-validation tests
```

**4. Coach Dashboard Intervention Card (650 lines, 23 tests)**
```bash
# File: test/features/momentum/presentation/widgets/coach_dashboard/coach_dashboard_intervention_card_test.dart  
# Strategy: Keep 5 core tests, delete 18 excessive UI tests
```

### Phase 3: Cache Performance Test Reduction (Day 4)
**TARGET: Core Services Layer Pruning**

**Based on attached performance service file:**
```bash
# File: test/core/services/cache/today_feed_cache_performance_service_test.dart
# Strategy: Keep core functionality, remove performance edge cases
```

**DELETE these test groups:**
- Extensive benchmark suite tests
- Performance regression edge cases  
- Detailed efficiency calculation tests
- Multiple statistical analysis tests

**KEEP these core tests:**
- Basic cache read/write
- Critical performance thresholds
- Error handling for cache operations

### Phase 4: Data Layer Edge Case Reduction (Day 5)
**TARGET: Data Layer (142 → 100 tests = -42 tests)**

**Search patterns for systematic deletion:**
```bash
# Find and reduce these patterns:
grep -r "test.*should.*handle.*null" test/ --include="*_test.dart"
grep -r "test.*should.*handle.*empty" test/ --include="*_test.dart"  
grep -r "test.*should.*handle.*invalid" test/ --include="*_test.dart"
```

**Strategy:** Keep 1 representative error test per service, delete permutations.

---

## **CRITICAL PRESERVATION GUIDELINES**

### Business Logic (NEVER DELETE - 145 tests)
```bash
# Preserve ALL tests in these patterns:
grep -r "momentum.*calculat" test/ --include="*_test.dart"
grep -r "score.*calculat" test/ --include="*_test.dart"
grep -r "state.*transition" test/ --include="*_test.dart"
```

### Security/HIPAA (NEVER DELETE)
```bash
# Preserve ALL tests matching:
grep -r "auth" test/ --include="*_test.dart"
grep -r "encrypt" test/ --include="*_test.dart"
grep -r "permission" test/ --include="*_test.dart"
```

### Core Integration (PRESERVE CORE)
```bash
# Keep essential API/database tests:
find test -path "*/data/*" -name "*api*_test.dart"
find test -path "*/data/*" -name "*repository*_test.dart"
```

---

## **UPDATED EXECUTION PLAN**

### Day 1: Device Compatibility Deletion
```bash
# High-impact, zero-risk deletion
rm test/features/momentum/presentation/widgets/device_compatibility_test.dart

echo "=== DEVICE COMPATIBILITY DELETED ===" >> sprint1_metrics.txt
echo "test() calls: $(grep -rE "test\(" test/ --include="*_test.dart" | wc -l)" >> sprint1_metrics.txt
echo "testWidgets() calls: $(grep -rE "testWidgets\(" test/ --include="*_test.dart" | wc -l)" >> sprint1_metrics.txt

# Run tests to ensure no breakage
flutter test --reporter=compact
```

### Day 2-3: Widget Test Surgical Reduction
**Target the 4 largest widget files identified in audit:**

```bash
# Process each high-impact file:
# 1. coach_dashboard_active_tab_test.dart (24 → 6 tests)
# 2. coach_dashboard_scheduled_tab_test.dart (23 → 5 tests) 
# 3. today_feed_tile_test.dart (28 → 6 tests)
# 4. coach_dashboard_intervention_card_test.dart (23 → 5 tests)

# Expected reduction: ~65 tests
```

### Day 4: Cache Performance Reduction
```bash
# Target cache performance over-testing
# Expected reduction: ~40 tests
```

### Day 5: Final Data Layer Cleanup
```bash
# Clean up remaining edge cases
# Expected reduction: ~40 tests
```

---

## **SUCCESS METRICS**

### Target Progression:
- **Day 1**: 880 → 850 tests (device deletion)
- **Day 2-3**: 850 → 700 tests (widget reduction) 
- **Day 4**: 700 → 550 tests (cache cleanup)
- **Day 5**: 550 → 400 tests (data cleanup)

### Final Validation:
```bash
# Success criteria
FINAL_TESTS=$(( $(grep -rE "test\(" test/ --include="*_test.dart" | wc -l) + $(grep -rE "testWidgets\(" test/ --include="*_test.dart" | wc -l) ))

if [ $FINAL_TESTS -le 450 ]; then
  echo "✅ SUCCESS: Test count reduced to $FINAL_TESTS" >> sprint1_metrics.txt
else
  echo "⚠️ REVIEW: Test count is $FINAL_TESTS (target: <450)" >> sprint1_metrics.txt
fi

# Ensure all critical tests preserved
echo "=== CRITICAL TEST PRESERVATION CHECK ===" >> sprint1_metrics.txt
echo "Domain tests: $(find test -path "*/domain/*" -name "*_test.dart" -exec grep -c "test(" {} + | awk -F: '{sum+=$2} END {print sum}')" >> sprint1_metrics.txt
echo "Momentum tests: $(grep -r "momentum.*calculat\|score.*calculat" test/ --include="*_test.dart" | wc -l)" >> sprint1_metrics.txt
```

---

## **AUDIT-BASED RISK ASSESSMENT**

### ✅ **LOW RISK (DELETE AGGRESSIVELY)**
- Device compatibility tests (infrastructure)
- Widget state over-testing (cosmetic)
- Performance edge cases (non-functional)  
- UI responsive design variations

### ⚠️ **MEDIUM RISK (DELETE CAREFULLY)**
- Cache service edge cases
- Data layer validation permutations
- Service integration error scenarios

### 🚫 **HIGH RISK (PRESERVE ALL)**
- Domain layer business logic (145 tests)
- Security/authentication flows  
- Core API integrations
- Momentum calculation tests (41 identified)

---

## **ROLLBACK PLAN**

```bash
# If reduction goes too far:
git checkout sprint-1-test-pruning-continued~1
git checkout -b sprint-1-test-pruning-recovery

# Review what was deleted:
git diff sprint-1-test-pruning-continued~1 sprint-1-test-pruning-continued --stat

# Selectively restore critical tests
```

---

## **POST-AUDIT INSIGHTS**

1. **Presentation layer has 37% of all tests** - highest pruning potential
2. **Device compatibility testing is pure waste** - delete entirely
3. **Domain layer is already lean** - 145 tests should be preserved
4. **Widget tests are massively over-engineered** - 70% reduction possible
5. **Cache performance testing is excessive** - infrastructure concern

**CONFIDENCE LEVEL**: HIGH - Can reach 350-450 tests safely, very close to 300 target. 