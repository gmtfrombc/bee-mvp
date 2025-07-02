# Vitals Reliability – H1.1 Defect Triage

**Sprint:** Stability & Observability Hardening (Pre-Epic 1.4)

**Scope lock date:** June 18, 2025

---

## 1. In-Scope Vitals Tiles

| Tile       | Current Metric Shown         | Ambiguity / Notes                                                                                                                 |
| ---------- | ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Steps      | _Steps today_ (units: count) | Step count appears ~ 2× expected on some devices; verify aggregation (Apple Health considers wheelchair pushes vs steps?).        |
| Sleep      | _❓ unspecified_             | UX does not state whether this is _total sleep duration_, _time in bed_, or stage-weighted sleep score. Sleep data often missing. |
| Heart Rate | _❓ unspecified_             | Value appears reasonable but label does not clarify if it is _resting HR_, _current HR_, or _24 h average_.                       |

> **Action:** Confirm metric definitions with Product & update copy/tooltip.

---

## 2. Observed Defects & Symptoms

| ID    | Symptom                                                                        | Frequency (est.)          | First Seen                                    | Notes                                                                                                         |
| ----- | ------------------------------------------------------------------------------ | ------------------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| VR-01 | "Loading" spinners persist on cold app launch; no fallback value shown.        | ~60 % of fresh launches   | iOS 17.5                                      | ✅ Fixed in v0.9.1 – tiles now load cached value instantly, spinners removed.                                 |
| VR-02 | Users must re-grant permissions seemingly at random.                           | Intermittent              | iOS 17.5                                      | ✅ Fixed in v0.9.2 – cached auth state prevents redundant dialogs; refresh no longer touches permission flow. |
| VR-03 | Steps tile shows ~2× actual step count.                                        | Frequent on iPhone 15 Pro | May be double-counting watch + phone sources. | ✅ Fixed in v0.9.3 – dedup selects Watch vs Phone source + minute-max sum                                     |
| VR-04 | Sleep tile shows "—" for multiple days despite Apple Health having sleep data. | Frequent                  | All test devices                              | Possibly missing HKCategoryTypeIdentifierSleepAnalysis read permission.                                       |
| VR-05 | Missing context labels (e.g., "Resting HR", "Total sleep hours").              | Always                    | –                                             | Leads to user confusion over meaning of values.                                                               |

---

## 3. Suspected Root Causes / Hypotheses

1. **Cache gap** – app does not persist last good reading; UI defaults to
   spinner until new fetch completes.
2. **Permission check race** – permission status checked after widget build
   leading to false negative & redundant modal.
3. **Data source duplication** (steps) – HealthKit query aggregates _device_ and
   _watch_ samples → double count.
4. **Missing HK query for Sleep Analysis** – only requesting _inBed_ samples?
   needs _asleep_ or both.
5. **Insufficient logging** – current logs do not capture HealthKit fetch
   failures or permission state transitions.

---

## 4. Reproducibility Matrix

| Scenario             | Offline | Permissions Revoked | Device Reboot | Result                                     |
| -------------------- | ------- | ------------------- | ------------- | ------------------------------------------ |
| Cold launch, online  | ✗       | ✗                   | ✗             | VR-01, VR-02                               |
| Cold launch, online  | ✗       | ✔                   | ✗             | Permissions modal expected, works OK       |
| Cold launch, offline | ✔       | ✗                   | ✗             | Spinners (expected) but no cached fallback |
| After reinstall      | –       | –                   | ✔             | VR-01, VR-02                               |

> **Next steps:** QA to run structured matrix once fixes are staged.

---

## 5. Logging & Observability Gaps

- No structured log for HealthKit query duration / result count.
- Permission status changes not emitted to analytics.
- No metric for "vitals fetch success rate" to Grafana.

---

## 6. Recommended Fixes (to feed H2-A tasks)

1. **Data Freshness & Fallback** (✅ implemented) • Persist last valid value +
   timestamp via `SharedPreferences`. Tiles render cached value instantly with
   timestamp. Colored staleness badge superseded by Apple-style timestamp UX.

2. **Improved Permission UX** • On launch, run synchronous HealthKit permission
   check before building tiles. • Replace card list placeholder with dynamic
   list of HealthKit types (steps, sleep, HR) & toggle states.

3. **Metric Definition Clarity** (✅ implemented) • Metrics confirmed: Steps
   today, Time Asleep (prev. night), HR 60-min avg (+24 h range). Tiles updated
   with subtitles & units.

4. **Step Count Deduplication** • Filter CSVDevice apple_watch vs iphone sources
   to prevent double aggregation.

5. **Sleep Data Fetch** • Request HKCategoryValueSleepAnalysis `asleep` & `core`
   stages; aggregate total duration.

6. **Enhanced Logging** • _Pending_ – will be added with retry/back-off
   implementation.

### 6.1 Progress Log

| Date       | Build  | Notes                                                                                                                                                  |
| ---------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2025-06-20 | v0.9.1 | • Cached fallback & timestamp UX live<br/>• Apple-style tile redesign (Heart Rate, Steps, Sleep)<br/>• Pull-to-refresh shows snackbar "Vitals updated" |
| 2025-06-21 | v0.9.2 | • Permission caching & refactor (VR-02)<br/>• Manual refresh analytics event<br/>• Retry/back-off polling                                              |
| 2025-06-22 | v0.9.3 | • Step count deduplication (VR-03)<br/>• Fixed step count issue on iPhone 15 Pro                                                                       |

---

## 7. Open Questions

1. Do we need _current_ HR (real-time) or 24 h average for MVP?
2. Should sleep tile target previous _night_ or rolling 24 h?
3. Is pull-to-refresh still needed once cached fallback is implemented?

---

## 8. Acceptance Criteria for Fixes

- Launch time shows cached value in < 300 ms (BLoC/Riverpod load).
- No spinner visible for more than 500 ms; if stale, grey badge present.
- Permissions modal appears only when at least one required HK type is _not_
  authorized.
- Step count within ±5 % of Apple Health app display.
- Sleep tile populated on next day after sleep recorded; accuracy ±5 min.
- Grafana panel `vitals_fetch_success_rate` > 95 % rolling 7 d.

---

_Prepared by:_ Mobile & QA
