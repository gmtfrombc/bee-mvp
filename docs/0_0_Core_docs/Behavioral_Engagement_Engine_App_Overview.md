# Behavioral Engagement Engine (BEE) – App & Dashboard Overview

*Document Version: 2025-07-24*

> Audience: Internal developers, analytics-team engineers, product stakeholders.
> Scope: High-level product & technical summary of the Momentum Coach mobile app **and** the accompanying Back-End Analytics Dashboard (primary focus).

---

## 1️⃣ Executive Summary

The **Behavioral Engagement Engine (BEE)** is a cross-platform wellness product that combines:

• A **Momentum Coach** mobile app (Flutter) that nudges users toward healthy habits and logs engagement signals in real-time.  
• A **Back-End Analytics Dashboard** (web) that allows operational and clinical teams to monitor population-level momentum scores, drill into user timelines, and configure intervention policies.

Most of this document is dedicated to the dashboard because it will be implemented by a separate full-stack team and requires a clear contract with the existing back-end services.

---

## 2️⃣ High-Level System Diagram

```text
                           ┌──────────────────────────┐
                           │  Momentum Coach (Flutter) │
                           └──────────────┬───────────┘
                                          │ GraphQL / REST
                                          ▼
┌──────────────────────────┐  Realtime   ┌──────────────────────────┐
│ Supabase **Edge Functions**│────────────▶│    Postgres 15 + pgvector │
└──────────────────────────┘              └──────────┬──────────────┘
                                 Pub/Sub /           │ Analytical ETL
                                 Channels            ▼
                                            ┌──────────────────────┐
                                            │   BigQuery + VertexAI │
                                            └──────────────────────┘
```

The dashboard sits *next to* the mobile client and consumes the same APIs plus additional admin-only endpoints (service-role JWT required).

---

## 3️⃣ Momentum Coach – Mobile Front End (1-page Recap)

| Area                     | Details |
|--------------------------|---------|
| **Framework**            | Flutter 3.3.2a, Riverpod v2 |
| **Navigation**           | `go_router` |
| **State Mgmt**           | Riverpod providers & `StateNotifier`s |
| **Offline Caching**      | `hydrated_riverpod` + `sqflite` |
| **Core Screens**         | Onboarding → Today Feed → Action Steps → Chat → Settings |
| **Outbound Events**      | `engagement_events` insert via Supabase Auto-REST |
| **Realtime Updates**     | Supabase *Channels* subscription for momentum score changes |
| **CI Footprint**         | Widget + golden tests, 85 % coverage target |

> For in-depth client architecture see `docs/architecture/auto_flutter_architecture.md`.

---

## 4️⃣ Back-End Analytics Dashboard – Detailed Overview

### 4.1 Purpose

1. **Operational Insight** – Track aggregate momentum, daily active users, and feature uptake.  
2. **Clinical Oversight** – Surface outliers (drop-off, negative momentum) for proactive outreach.  
3. **Intervention Management** – Create/edit action-step templates, schedule nudges, and monitor A/B tests.  
4. **Data Governance** – Export CSV or BigQuery views for research teams under HIPAA controls.

### 4.2 User Personas

| Persona      | Needs |
|--------------|-------|
| **Care Team Clinician** | Quick health snapshot & user timelines |
| **Ops Analyst** | Funnel metrics, retention cohorts |
| **Product Manager** | Feature adoption charts, experiment dashboards |
| **Data Scientist** | Ad-hoc queries, model telemetry |

### 4.3 Functional Modules

| Module                         | Key UI Widgets | Primary Tables / Streams |
|--------------------------------|----------------|--------------------------|
| **Overview** (landing)         | KPI tiles, trend spark-lines, p95 latency     | `daily_engagement_scores`, Cloud Monitoring   |
| **User Explorer**              | Search bar, timeline chart, event log         | `engagement_events`, `coach_memory`          |
| **Intervention Manager**       | CRUD list, scheduler calendar, variant stats  | `action_step_templates`, `scheduled_nudges`  |
| **Momentum Analytics**         | Heat-map, cohort retention curves             | BigQuery derived tables                      |
| **System Health**              | Uptime % tile, error log table                | GCP Cloud Logging, Supabase status API       |

_All modules inherit a shared design system (Figma tokens) and responsive grid that collapses gracefully to tablet size (1024×768)._  

### 4.4 Technology Stack

| Layer            | Chosen Tech | Notes |
|------------------|-------------|-------|
| **Web Framework**| React 18 + Vite | SSR not required (auth-gated) |
| **State Mgmt**   | Zustand | Lightweight for dashboard scale |
| **Charts**       | `@mui/x-charts` (or Syncfusion JS) | License OK under SaaS tier |
| **Auth**         | Supabase JS Client (service-role in server context) | Row-Level Security bypassed for admin JWT |
| **API**          | Supabase Auto-REST + Edge Functions (`/v1/admin/*`) | Versioned; follow error envelope spec |
| **Realtime**     | Supabase Realtime JS (Channels) | Live KPI tiles |
| **Deployment**   | Cloud Run (container build) | Blue/green w/ 50 % traffic split |
| **CI/CD**        | GitHub Actions → Cloud Build | Lint, test, e2e (Playwright) |

### 4.5 Data Contracts

1. **`daily_engagement_scores`** – aggregated per-user momentum; dashboard consumes *materialized view* with index on `(score_date DESC)`.
2. **`engagement_events`** – raw event stream; dashboard requests window-bounded partitions (e.g., `?from=2025-06-01&to=2025-06-30`).
3. **`action_step_templates`** – definitional table; mutations gated behind `admin` role.
4. **Edge Function `GET /v1/admin/system-health`** – returns uptime, error counts, token spend (AI).

_All breaking changes require a **SemVer major bump** and OpenAPI contract update._

### 4.6 Security & Compliance

• **HIPAA Alignment** – ePHI only in compliant GCP projects; dashboard accessible via SSO (Google Workspace, Okta roadmap).  
• **Row-Level Security** – disabled for service-role JWT but audit logs capture mutations.  
• **Encryption** – TLS 1.2+, CMEK for Postgres and GCS exports.  
• **Audit Trails** – Cloud Audit Logs retained 7 years, surfaced in dashboard System Health tab.  

### 4.7 Performance & SLA Targets

| Metric                    | Target |
|---------------------------|--------|
| Dashboard initial load    | < 2 s TTI on 50th %tile |
| KPI tile refresh interval | 5 s (websocket push) |
| p95 API latency           | < 800 ms |
| Error rate                | < 1 % |

### 4.8 Extension Roadmap (Post-MVP)

1. **Explainability Panel** – SHAP contributions for AI-driven nudges.  
2. **Cohort Comparison View** – side-by-side funnel analysis.  
3. **Custom Alert Builder** – UI to set threshold alerts → PagerDuty.  
4. **Role-Based Access Control** – granular permissions (clinician vs analyst).  
5. **Embedded Reports** – Looker Studio iFrames for ad-hoc dashboards.

---

## 5️⃣ Deployment Pipeline Snapshot

```mermaid
graph TD
    code["Push / PR"] --> lint[Lint & Unit Tests]
    lint --> build[Dashboard Docker Build]
    build --> e2e[Playwright E2E]
    e2e --> cr[Cloud Run Deploy (staging)]
    cr --> approval[Manual QA Sign-off]
    approval --> prod[Cloud Run Deploy (prod)]
```

---

## 6️⃣ Key References

• Technical deep-dive: `docs/architecture/bee_mvp_tech_overview.md`  
• Supabase Edge Function examples: `supabase/functions/`  
• Data model ‑ Postgres migrations: `supabase/migrations/`  
• Monitoring dashboards JSON: `monitoring/grafana/`  
• Security docs & BAA path: `SECURITY_DOCS/`

---

_End of document_ 