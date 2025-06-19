# Tasks – Stability & Observability Hardening Sprint (Pre-Epic 1.4)

**Epic:** 1.3 · Hardening & Observability Sprint\
**Module:** Core Mobile Experience\
**Status:** 🔴 Planned\
**Dependencies:** None (all work is self-contained, uses existing pipelines)

---

## 📋 Sprint Overview

**Goal:** Eliminate key reliability issues and surface data quality in a
lightweight admin view so that the app can be distributed via TestFlight with
confidence before large-scale user onboarding.

**Why Now?**

1. Unreliable vitals tiles and stale Daily Feed undermine user trust.
2. Rewards screen shows placeholder widgets that may confuse early testers.
3. No single place for an admin/coach to verify that data is flowing.

**Success Criteria:**

- Vitals tiles always display _either_ a fresh value (_<10 min old_) **or** a
  clear "data stale" badge.
- Daily Feed article rotates every 24 h via backend job with ≤5 % failure rate
  (Grafana alert on error).
- Rewards screen shows _only_ live badges; placeholders are hidden behind
  RemoteConfig.
- Admin mini-dashboard lists users with last app open, last vitals sync,
  momentum, and earned badges.
- Nightly CI fails if vitals-sync test error rate > 5 %.
- All new code covered by happy-path + critical edge-case tests following ≥ 85 %
  policy.

---

## 🏁 Milestone Breakdown

### **H1: Scope Lock & Defect Triage** ✅ _Completed_

| Task     | Description                                                                                               | Owner   |
| -------- | --------------------------------------------------------------------------------------------------------- | ------- |
| **H1.1** | Audit wearable-tile flakiness; list reproducible cases (offline, permission revoked, HealthConnect down). | QA      | ✅ Completed
| **H1.2** | Log Daily Feed rotation failures & Supabase cron status; export last-7-day stats.                         | Backend | ✅ Completed
| **H1.3** | Inventory Rewards widgets; mark live vs placeholder; define feature-flag keys.                            | Product | ✅ Completed
| **H1.4** | Define missing metrics & dashboards (feed cron, vitals error rate, rewards service calls).                | DevOps  | ✅ Completed
| **H1.5** | Audit AI-Coach quick suggestions & chat UX; capture defects & recommended fixes (see ai_coach_triage).    | Product | ✅ Completed

### **H2: Reliability Fixes** 🔨 In-Progress

#### H2-A • Vitals Reliability 📈 _Planned_

| Task       | Description                                                           | Est. hrs | Owner  |
| ---------- | --------------------------------------------------------------------- | -------- | ------ |
| **H2.A.1** | Add `dataFreshness` state + grey/green/red badge to each vitals tile. | 4        | Mobile |
| **H2.A.2** | Implement retry w/ exponential back-off in `WearableDataRepository`.  | 6        | Mobile |
| **H2.A.3** | Cache last good value & display alongside stale badge.                | 3        | Mobile |
| **H2.A.4** | Unit tests: offline, permission revoked, stale >10 min, recovery.     | 4        | QA     |

#### H2-B • Daily Feed Stability 📈 _Planned_

| Task       | Description                                                          | Est. hrs | Owner   |
| ---------- | -------------------------------------------------------------------- | -------- | ------- |
| **H2.B.1** | Move article rotation to Supabase Edge Function scheduled job.       | 4        | Backend |
| **H2.B.2** | Add `today_feed_rotation_success` metric + Grafana panel.            | 3        | DevOps  |
| **H2.B.3** | PagerDuty alert if job fails >1 run in 24 h.                         | 2        | DevOps  |
| **H2.B.4** | Integration test: seed new article, verify device receives in <30 s. | 3        | QA      |

#### H2-C • Rewards Screen Cleanup 📈 _Planned_

| Task       | Description                                                              | Est. hrs | Owner  |
| ---------- | ------------------------------------------------------------------------ | -------- | ------ |
| **H2.C.1** | Gate all placeholder widgets behind `rewards_v2_beta` RemoteConfig flag. | 3        | Mobile |
| **H2.C.2** | Implement first real badge: "First Wearable Sync" (Edge func + UI).      | 5        | Mobile |
| **H2.C.3** | Hide Rewards tab completely if `show_rewards` flag is false.             | 2        | Mobile |

#### H2-D • AI Coach Enhancements 📈 _Planned_

| Task       | Description                                                                              | Est. hrs | Owner            |
| ---------- | ---------------------------------------------------------------------------------------- | -------- | ---------------- |
| **H2.D.1** | Rename quick suggestion chips to "Today" & "Tomorrow"; update icons.                     | 1        | Mobile           |
| **H2.D.2** | Build dynamic `today_prompt()` with 7-day momentum avg, steps, sleep.                    | 4        | Backend          |
| **H2.D.3** | Implement `tomorrow_prompt()` returning 3 actionable suggestions for next 24 h.          | 4        | Backend          |
| **H2.D.4** | Add feedback dialog (1-10 rating + optional comment); persist to `coach_feedback` table. | 5        | Mobile + Backend |
| **H2.D.5** | Create side drawer listing past chats; enable delete & "+" new chat icon.                | 6        | Mobile           |
| **H2.D.6** | Rewrite default system greeting copy.                                                    | 1        | Product          |
| **H2.D.7** | Gate new coach features behind `ai_coach_v2_beta` flag and log analytics events.         | 2        | Mobile           |

### **H3: Observability & Admin Mini-Dashboard** 📈 _Planned_

| Task     | Description                                                                                            | Est. hrs | Owner   |
| -------- | ------------------------------------------------------------------------------------------------------ | -------- | ------- |
| **H3.1** | Create SQL view `vw_engagement_overview` (user_id, last_app_open, last_vitals_sync, momentum, badges). | 4        | Backend |
| **H3.2** | Build simple React page (or Supabase Studio extension) listing the view with filters.                  | 6        | Backend |
| **H3.3** | Grafana panels: Momentum distribution (7 d), vitals-ingest errors/min.                                 | 3        | DevOps  |
| **H3.4** | Add RLS policy limiting dashboard rows to coach's patients (future-proof).                             | 2        | Backend |

### **H4: Regression Pass & CI Gate** 📈 _Planned_

| Task     | Description                                                                               | Est. hrs | Owner  |
| -------- | ----------------------------------------------------------------------------------------- | -------- | ------ |
| **H4.1** | Flutter golden tests for vitals tiles (5 data states).                                    | 4        | QA     |
| **H4.2** | End-to-end test: seed Daily Feed entry, verify in app.                                    | 4        | QA     |
| **H4.3** | Nightly canary: 30-min walk test script; fail CI if vitals error rate >5 %.               | 3        | DevOps |
| **H4.4** | Update `analysis_options.yaml` to treat unused-param as error (prevent future flakiness). | 1        | Mobile |

---

## ✅ Definition of Done

- All H2 tasks merged & deployed to TestFlight.
- Admin dashboard reachable via `/admin` route or Supabase Studio.
- Grafana alerts green for 7 consecutive days.
- Nightly CI pipeline passes hard-gate checks.
- Rewards tab shows only live badges; first wearable sync badge unlocks on test
  device.
- QA sign-off: vitals tiles never blank; stale badge appears correctly; Daily
  Feed rotates.

---

**Last Updated:** June, 18 2025
