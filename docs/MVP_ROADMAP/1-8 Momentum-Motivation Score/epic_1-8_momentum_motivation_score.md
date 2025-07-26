### Epic: 1.8 · Momentum & Motivation Scores
**Module:** Data & Analytics Platform (Backend + Edge Functions)
**Status:** 🟡 Planned
**Dependencies:**
- Engagement events logging pipeline ✅
- Supabase auth.users table & analytics schema ✅
- Phase 0 CI green & coverage ≥ 45 % ✅
- Edge-function deployment workflow (SemVer tags) ✅
- Phase 1 biometric streams ingestion (sleep, steps) ➡️

---

## Epic Overview
Build a robust dual-metric system that quantifies **Momentum (Engagement)** and **Motivation Internalization** for every user.

**Goal:**
1. Deliver a daily **Momentum Score** (% 0–100) that incorporates new behavioral signals and historical smoothing.
2. Deliver a daily **Motivation Score** (0–100) measuring internal vs external motivation.
3. Persist both scores & pillar breakdowns in Supabase, powering coach logic and UI gauges.

**Success Criteria:**
- Daily momentum row for 100 % of active users (no gaps).
- Motivation tier (Highly, Moderate, Mixed, External) available via API.<br/>
- p95 latency < 2 s for score queries (<500 ms for edge function execution).
- Automated tests raise project coverage to ≥ 48 %.
- Documentation & ERD updated; stakeholders sign-off.

---

## 🏁 Milestone Breakdown

| ID | Milestone | Hours | Status |
|----|-----------|-------|--------|
| **M1** | Schema & Signal Foundations | 10h |✅ Complete |
| **M2** | Momentum Score Calculator v2 | 12h | 🟡 Planned |
| **M3** | Motivation Score Engine | 14h | 🟡 Planned |
| **M4** | Back-Testing & CI Coverage | 8h  | 🟡 Planned |
| **M5** | API & Docs Finalization | 4h  | 🟡 Planned |

### M1 · Schema & Signal Foundations
| Task | Description | Hours | Status |
|------|-------------|-------|--------|
| T1 | Create `momentum_events`, `momentum_pillars` tables as per implementation guide | 3h | ✅ Complete |
| T2 | Add `motivation_journal`, `habit_index` tables | 3h | ✅ Complete|
| T3 | Migrate legacy `daily_engagement_scores` → view `daily_momentum_scores` | 2h | ✅ Complete |
| T4 | Data backfill job for empty-day momentum rows | 2h | ✅ Complete |

**Acceptance Criteria:**
- All tables exist with PK/FK & audited by pgTAP tests.
- View alias returns identical columns as legacy consumers.

**QA / Tests:**
- Migration rollback passes.
- pgTAP assertions for PK, FK, unique constraints.

---

### M2 · Momentum Score Calculator v2
| Task | Description | Hours | Status |
|------|-------------|-------|--------|
| T1 | Refactor edge function `momentum-score-calculator` to v2 tag | 4h | 🟡 |
| T2 | Add new event weights + cap logic (config file) | 2h | 🟡 |
| T3 | Emit explicit daily rows when no events occur | 2h | 🟡 |
| T4 | Unit tests for >5 messages, zero-event day, new signals | 4h | 🟡 |
| T5 | Deploy daily momentum back-fill cron job | 1h | 🟡 |

**Acceptance Criteria:**
- For a fixture user, score matches expected blended output.
- Function idempotent & rerunnable.

**QA / Tests:**
- deno test suite ≥ 90 % coverage for module.
- Load test (k6) shows p95 < 400 ms for 100 RPS.

---

### M3 · Motivation Score Engine
| Task | Description | Hours | Status |
|------|-------------|-------|--------|
| T1 | Implement NLP classifier for motivational tone (LLM call) | 4h | 🟡 |
| T2 | Cron job `motivation-score-calculator` writing to `momentum_pillars` | 4h | 🟡 |
| T3 | Integrate biometric & habit subscores per algorithm | 4h | 🟡 |
| T4 | Add pillar breakdown JSON column | 2h | 🟡 |

**Acceptance Criteria:**
- Score components sum to 0–100 with correct weighting.
- Cron runs daily in staging; entries visible in table.

**QA / Tests:**
- Fixtures for linguistic, biometric, skill engagement paths.
- Mock LLM calls during tests.

---

### M4 · Back-Testing & CI Coverage
| Task | Description | Hours | Status |
|------|-------------|-------|--------|
| T1 | Import fixtures into `tests/fixtures/` | 1h | 🟡 |
| T2 | Integration tests with 30-day historical data | 3h | 🟡 |
| T3 | Update `make ci-fast` matrix; coverage ≥ 48 % | 2h | 🟡 |
| T4 | Perf test for decay-smoothed queries | 2h | 🟡 |

**Acceptance Criteria:**
- CI passes; coverage badge shows ≥ 48 %.
- Decay query returns < 50 ms locally.

---

### M5 · API & Docs Finalization
| Task | Description | Hours | Status |
|------|-------------|-------|--------|
| T1 | Expose `GET /scores/latest?user_id=` endpoint | 2h | 🟡 |
| T2 | Update OpenAPI spec & README | 1h | 🟡 |
| T3 | Dev hand-off walkthrough + ERD diagram | 1h | 🟡 |

**Acceptance Criteria:**
- Endpoint returns momentum & motivation JSON in < 200 ms.
- API doc auto-generated; screenshot in PR description.

---

## ⏱ Status Flags
🟡 Planned  🔵 In Progress  ✅ Complete

---

## Ambiguities / Questions Answered
1. We compute Motivation Score daily
2. LLM model choice & cost ceiling – GPT-4o or similar
3. Required cold-storage retention period for raw behavioral logs (GDPR) is TBD
4. UI spec for Motivation tiers is pending – TBD

---

_Last updated automatically by Cursor AI on 2025-07-25_ 