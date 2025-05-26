
# Behavioral Engagement Engine (BEE) – MVP Build Sequence & Milestones

> **Source‑of‑Truth** execution roadmap linked to the architecture in `bee_mvp_architecture.md`.

---

## 🧭 Guiding Principles
1. **Value Early** – deliver visible progress each week  
2. **Vertical Slices** – each milestone exercises the full stack  
3. **Automate** – CI/CD & IaC from day 1



---

## 🗓️ Milestone Timeline
| # | Name | Duration | Deliverable |
|---|------|----------|-------------|
| 0 | Project Bootstrap | 3 days | Repo, Terraform skeleton, CI green |
| 1 | Data Backbone | 1 week | Supabase DB + RLS, Flutter auth |
| 2 | Daily Dashboard Alpha | 1 week | Widget renders mock data |
| 3 | Realtime Event Logging | 1 week | EHR ingest → dashboard updates |
| 4 | Nudge Engine v1 | 1 week | Rule‑based push notifications |
| 5 | Goal Tracking | 1 week | User sets/completes goals |
| 6 | Demo & Feedback | 3 days | Stakeholder demo, backlog refresh |

_Total ETA: ~6 weeks (solo pace)._

---

| Milestone (Build‑Sequence) | Corresponding PRD(s) in Phase 1 | Notes |
|---------------------------|----------------------------------|-------|
| **0 · Project Bootstrap** | — | Repo setup, CI, Terraform scaffolding (no feature PRD) |
| **1 · Data Backbone** | `prd-engagement-events-logging.md` | Create `engagement_events` table, Row‑Level Security, auth wiring |
| **2 · Daily Dashboard Alpha** | `prd-daily-engagement-dashboard.md` | Build UI with mock data pulled from DB |
| **3 · Realtime Event Logging** | `prd-engagement-events-logging.md` (same as M1) | Add Cloud Function ingest so dashboard updates live |
| **4 · Nudge Engine v1** | `prd-nudge-trigger-system.md` | Rule‑based scheduler; writes `scheduled_nudges` rows; push notifications |
| **5 · Goal Tracking** | `prd-micro-goal-tracking.md` | Users set/complete goals; streak counter |
| **6 · Demo & Feedback** | *(All above PRDs)* | Stakeholder walkthrough, backlog refresh |

## Detailed Tasks (per milestone)
> Generate fine‑grained task lists with the Task‑List rule.

### Milestone 0 – Project Bootstrap
- Create mono‑repo (`app/`, `infra/`, `functions/`)  
- Terraform: Supabase, networking, secrets  
- GitHub Actions: lint, test, deploy preview

### Milestone 1 – Data Backbone
- Design `engagement_events` schema  
- Implement RLS policies  
- Flutter auth & simple query view

### Milestone 2 – Dashboard Alpha
- Seed mock data  
- Build `EngagementDashboard` widget  
- Unit‑test aggregation logic

### Milestone 3 – Realtime Event Logging
- Cloud Function to pull sample Cerbo data  
- Pub/Sub → write to `engagement_events`  
- Supabase Realtime → Flutter stream refresh

### Milestone 4 – Nudge Engine v1
- Define inactivity rule (>48 h)  
- Scheduler job writes `scheduled_nudges`  
- Send FCM push to device

### Milestone 5 – Goal Tracking
- `goals` table (goal, target date, status)  
- Flutter UI add/complete goals  
- Streak counter on dashboard

### Milestone 6 – Demo & Feedback
- Prepare demo script  
- Collect stakeholder notes  
- Retrospective & next‑phase planning

---

## Directory Convention
```
bee/
  app/                 # Flutter
  infra/               # Terraform
  functions/           # Cloud Functions & Run
  docs/
    bee_mvp_architecture.md
    bee_mvp_build_sequence.md
    modules/
      core-engagement/
        prd-daily-engagement-dashboard.md
```

### Definition of Done (MVP)
- Core dashboard, goal tracking, nudging functional  
- Tests ≥ 80 % on core widgets & services  
- CI/CD pipeline green  
- Migration plan to Cloud SQL documented

---

