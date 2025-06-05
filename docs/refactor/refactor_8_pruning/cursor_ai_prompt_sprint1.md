
# 🐝 **Cursor AI Prompt – Sprint 1 Test-Pruning & Quality Guard-Rails**

> **Attach:** `SPRINT_1_EXECUTION_GUIDE.md`  
> **Goal:** Execute Sprint 1 exactly as outlined in the guide *while* enforcing the extra quality safeguards below.

---

## 1 ⟶ Mission

* Reduce test count **1 203 → ≈ 300** without losing business‑critical coverage (Momentum, Security/HIPAA, API integration, Core user flows).  
* Finish in the two‑week cadence detailed in the Sprint 1 guide.  
* Leave *all* production code unchanged; only tests are touched.

---

## 2 ⟶ Additional Guard‑Rails (must stay green in CI)

| Guard‑rail | Target | How to check |
|------------|--------|--------------|
| **Line/branch coverage** | **≥ 80 %** on `lib/` *and* **≥ 90 %** on `core/business_logic/` | `flutter test --coverage` → fail CI if below |
| **Mutation score** | **≥ 65 %** survived mutants on business‑logic packages | Run [`mutagen`](https://pub.dev/packages/mutagen) after each pruning phase |
| **Cyclomatic complexity** | **< 20** per function; **< 25** methods per class | `dart run dart_code_metrics:metrics analyze lib` (config in `analysis_options.yaml`) |
| **File size** (test files) | **< 500 LOC** each after pruning | auto‑checked via `wc -l` |
| **Sprint metrics log** | Append metrics to `sprint1_metrics.txt` after *every* phase (see guide) | already scripted in guide |

*If any guard‑rail fails, revert that phase and restore deleted tests from the backup branch.*

---

## 3 ⟶ Execution Flow

1. **Create branch & baseline** – follow “Pre‑Execution Setup” in the guide; add coverage, mutation and complexity snapshots to `sprint1_metrics.txt`.  
2. **Phase 1A/B** – delete constant & JSON tests per guide.  
3. **Run validation pipeline**  
   ```bash
   ./tool/run_quality_checks.sh   # script you’ll create from Section 4
   ```  
4. **Phase 2A/B** – prune edge‑case & equality/hashCode tests.  
5. **Phase 3** – simplify over‑mocked tests.  
6. **Final validation** – all guard‑rails + full test suite + mutation run.  
7. **Commit** – use the commit template from the guide, adding mutation & coverage numbers.  
8. **Push PR** – label `sprint1-quality-pass`. Review must confirm green guard‑rails before merge.

---

## 4 ⟶ Helper Script (`tool/run_quality_checks.sh`)

```bash
#!/usr/bin/env bash
set -e

echo "=== QUALITY CHECKS ==="

# 1. Coverage
flutter test --coverage --reporter=compact
lcov --list coverage/lcov.info | tee -a sprint1_metrics.txt

# 2. Mutation testing (business-logic only)
dart run mutagen:mutate -r lib/core/business_logic
dart run mutagen:test -p 4 | tee -a sprint1_metrics.txt

# 3. Cyclomatic complexity
dart run dart_code_metrics:metrics analyze lib | tee -a sprint1_metrics.txt

# 4. Fail thresholds
python tool/enforce_thresholds.py   # returns non-zero exit code on failure
```

Create `tool/enforce_thresholds.py` to parse the logs and exit 1 if thresholds are missed.

---

## 5 ⟶ Deletion Rules Recap

* **Delete**: constant/value tests, exhaustive JSON tests, overspecified edge permutations, duplicated equality/hashCode groups, over‑mocked scaffolds.  
* **Keep**: Momentum calculations, state transitions, security/HIPAA, external API integrations, core user journeys.  
* **Trim** rather than delete integration tests—shrink mock setup to **≤ 5** mocks.

---

## 6 ⟶ Rollback

* `git revert` **OR** checkout backup branch `sprint-1-test-pruning-backup` created at start.  
* Guard‑rails ensure we never merge a failing state.

---

### ✅ Deliverable

A merged PR with:

* ≤ **300** total tests  
* **All guard‑rails passing**  
* `sprint1_metrics.txt` showing before/after counts, coverage %, mutation score, complexity summary  

Good luck—let’s keep the hive lean *and* safe! 🐝
