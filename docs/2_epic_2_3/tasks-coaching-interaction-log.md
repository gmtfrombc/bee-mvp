# Tasks – Coaching Interaction Log (Epic 2.3)

**Epic:** 2.3 · Coaching Interaction Log\
**Module:** Data Integration & Events\
**Status:** 🟡 **IN PROGRESS (M2.3.2 completed)**\
**Dependencies:** Epic 2.2 ✅, Epic 1.3 Phase-3 (consumer)

---

## 📋 **Epic Overview**

**Goal:** Capture every AI- and human-coach interaction in a structured,
query-friendly log to enable coaching effectiveness analytics, model
fine-tuning, and regulatory auditing.

**Strategic Importance:**

- **BLOCKING** for Epic 1.3 Phase 3 – Rapid Feedback & JITAI effectiveness loop.
- **REQUIRED** for HIPAA auditing & PHI access tracking.
- **INPUT** for cross-patient pattern learning (Epic 3.1).

---

## 🚀 **Strategic Implementation Plan**

### Milestone Breakdown

### **M2.3.1 Interaction Schema Design** (Est. 8 h)

| Task         | Description                                                                                    | Est. hrs | Owner   | Status |
| ------------ | ---------------------------------------------------------------------------------------------- | -------- | ------- | ------ |
| **T2.3.1.1** | Draft ER-diagram & naming conventions (`coach_interactions`, `interaction_events`)             | 2        | Backend | ✅     |
| **T2.3.1.2** | Define JSON columns for message payload & metadata (sender, model, latency, tokens, sentiment) | 2        | Backend | ✅     |
| **T2.3.1.3** | Write Postgres migration with RLS + HIPAA audit fields                                         | 2        | Backend | ✅     |
| **T2.3.1.4** | Create Supabase view `coach_interactions_public` with PII redaction                            | 1        | Backend | ✅     |
| **T2.3.1.5** | Update ERD in `docs/architecture/db_schema.puml`                                               | 1        | Backend | ✅     |

**Acceptance:** Migration applies cleanly in staging; RLS denies cross-user
access.

---

### **M2.3.2 Real-time Logging System** (Est. 12 h)

| Task         | Description                                                                      | Est. hrs | Owner   | Status                        |
| ------------ | -------------------------------------------------------------------------------- | -------- | ------- | ----------------------------- |
| **T2.3.2.1** | Implement `log_coach_interaction()` helper in `ai-coaching-engine/services`      | 3        | Backend | ✅                            |
| **T2.3.2.2** | Hook helper into conversation & JITAI routes (both user & system messages)       | 3        | Backend | ✅                            |
| **T2.3.2.3** | Capture latency, model, tokens, cost, momentum_state                             | 2        | Backend | ✅ _latency, model, momentum_ |
| **T2.3.2.4** | Fire Realtime subscription on new rows (`realtime:coach_interactions:{user_id}`) | 2        | Backend | ✅                            |
| **T2.3.2.5** | Expose REST endpoint `/v1/coach-interactions/history` (service-role only)        | 2        | Backend | ✅                            |

**Acceptance:** New conversation row appears within 1 s; endpoint returns last
100 messages.

---

### **M2.3.3 Analytics Pipeline** (Est. 10 h)

| Task         | Description                                                      | Est. hrs | Owner    | Status                    |
| ------------ | ---------------------------------------------------------------- | -------- | -------- | ------------------------- |
| **T2.3.3.1** | Edge Function `interaction-aggregate` (daily rollup per user)    | 4        | Backend  | ✅                        |
| **T2.3.3.2** | Metrics: response_time_avg, satisfaction_avg, coach_persona_mix  | 2        | Data Sci | ✅ _satisfaction pending_ |
| **T2.3.3.3** | Store results in `coach_interaction_metrics` table               | 1        | Backend  | ✅                        |
| **T2.3.3.4** | Grafana panel JSON `coach_usage_overview.json` (extend existing) | 2        | DevOps   | ✅ _draft_                |
| **T2.3.3.5** | Document SQL/RPC for ad-hoc queries                              | 1        | Backend  | ✅                        |

**Acceptance:** Daily cron job fills metrics table; Grafana shows past 7-day
trends.

---

### **M2.3.4 Performance & Quality Metrics** (Est. 8 h)

| Task         | Description                                           | Est. hrs | Owner   | Status |
| ------------ | ----------------------------------------------------- | -------- | ------- | ------ |
| **T2.3.4.1** | Add x-request-id + timing headers to AI responses     | 1        | Backend | ✅     |
| **T2.3.4.2** | Log token usage & cost to `coach_interactions`        | 2        | Backend | ✅     |
| **T2.3.4.3** | Edge bench `jitai-load.bench.ts` extended for 100 RPS | 2        | QA      | ✅     |
| **T2.3.4.4** | Alert rules: p95 latency > 900 ms, error_rate > 2 %   | 1        | DevOps  | ✅     |
| **T2.3.4.5** | Doc: `docs/testing/interaction_performance.md`        | 2        | DevOps  | ✅     |

**Acceptance:** Bench passes; alerts visible in staging Grafana.

---

### **M2.3.5 Integration Testing & Docs** (Est. 10 h)

| Task         | Description                                               | Est. hrs | Owner      | Status |
| ------------ | --------------------------------------------------------- | -------- | ---------- | ------ |
| **T2.3.5.1** | Write Deno tests for logging helper (happy & failure)     | 2        | QA         | ✅     |
| **T2.3.5.2** | Flutter widget test: Chat UI renders interaction history  | 2        | QA         | ✅     |
| **T2.3.5.3** | End-to-end test: send chat → row logged → metrics updated | 3        | QA         | ✅     |
| **T2.3.5.4** | Compliance checklist (HIPAA, PHI masking)                 | 2        | Compliance | ✅     |
| **T2.3.5.5** | Update `bee_project_structure.md` statuses                | 1        | PM         | ✅     |

**Acceptance:** CI suite green; compliance checklist signed; documentation
merged.

---

## 📅 **Estimated Timeline**

Total ≈ 48 h (~1 dev-week with QA/DevOps assist).

---

## 📜 **Definition of Done – Epic 2.3**

- All milestones marked ✅; CI & deployment pipelines updated.
- 100 % of coach interactions persisted with RLS & PHI masking.
- Daily aggregates populate metrics table; Grafana dashboard live.
- Alerts cover latency & error thresholds.
- Integration tests green; compliance checklist approved.
