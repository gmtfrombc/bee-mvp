# BEE Project Plan – FINAL (v4.1)

This is the authoritative source of truth for the BEE (Behavioral Engagement Engine) app build. It defines all modules, epics, and milestones required for MVP completion using a hybrid AI architecture (LightGBM + LLMs), while enabling seamless future expansion to agentic (Path B) or multimodal (Path C) models.

---

## 🧠 Glossary of Core Concepts

- **Momentum Score**: A real-time user engagement signal calculated from behavioral and biometric events.
- **LLM (Large Language Model)**: Used for generating AI Coach responses (e.g., GPT-4, Claude).
- **LightGBM**: A machine learning model used to predict engagement/disengagement from structured data.
- **JITAI**: Just-in-time adaptive intervention, triggered based on model outputs.
- **Coach Memory**: Stores user preferences and history for long-term personalization.
- **Model Gateway**: A unified interface to route prediction requests to different models.

---

## 🔢 Legend

```
✅ Complete
🔹 In Progress
⚪ Planned
❌ Deferred
✨ New in v4.1
```

---

## 🔖 Note on Document Scope

This plan functions as a **table of contents**. Each Epic refers to one or more documents that describe the feature in detail. Task-level specifications (milestones, tasks, deliverables, dependencies) are generated per Epic using the linked documents.

---

## 📋 Project Structure Overview

### Naming Conventions
```
PROJECT: BEE (Behavioral Engagement Engine)
├── MODULES: High-level categories
│   ├── EPICS: Major efforts per feature
│   │   ├── MILESTONES: Deliverable checkpoints
│   │   │   ├── TASKS: Implementation items
```

---

## 🔄 Revised MVP Build Sequence

1) Registration and Auth (1.6)  ⚪
2) Core UI: Momentum Meter (1.1), Today Feed (1.2)  ⚪
3) Event Infra: Engagement Logging (2.1), Wearables (2.2), Coaching Logs (2.3)  ⚪
4) Action Steps (1.5), PES (1.7), Biometrics (1.9)  ⚪
5) Momentum + Motivation Score (1.8)  ⚪
6) Adaptive AI Coach (1.3), Conversation Engine (1.10)  ⚪
7) LightGBM + Analytics Engine (3.2.1)  ⚪
8) Admin Dashboard (5.2) ⚪
9) User Segmentation (5.1)  ⚪
10) Coach Dashboard Alpha (4.1) ⚪
11) In-App Messaging (1.4) ⚪
12) Onboarding (1.11)

---

## 🧱 MODULE 1: Core Mobile Experience

### Epic 1.1: Momentum Meter ⚪
Depends on: 1.5, 1.7, 1.9  
Documents: `momentum_score_calculation.md`, `momentum_score.md`

---

### Epic 1.2: Today Feed and This Week's Journey ⚪  
Depends on: 1.8  
Documents: `today_tile_prompt.md`, `today_feed_journey.md`

---

### Epic 1.3: Adaptive AI Coach ⚪  
Depends on: 1.5, 1.8  
Documents: `tasks_adaptive_coach_summary.md`, `tasks-conversation-engine.md`

---

### Epic 1.4: In-App Messaging ⚪  
Depends on: 1.3  
Documents: `in_app_messaging.md`

---

### Epic 1.5: Action Steps ⚪  
Depends on: 1.6  
Documents: `action_steps.md`

---

### Epic 1.6: Registration and Auth ⚪  
Documents: `@auth_registration.md`, `@onboarding_survey.md`, `@medical_history_survey.md`

---

### Epic 1.7: Perceived Energy Score (PES) ⚪  
Depends on: 1.6  
Documents: `perceived_energy_score.md`

---

### Epic 1.8: Momentum + Motivation Score ⚪  
Depends on: 1.5, 1.7  
Documents: `momentum_score.md`, `motivation_score_algorithm.md`, `motivation_score_implementation.md`

---

### Epic 1.9: Biometrics Entry + PES ⚪  
Depends on: 1.6  
Documents: `biometrics_pes.md`, `biometrics_integration.md`

---

### Epic 1.10: AI Coach Conversation Engine ⚪  
Depends on: 1.3  
Documents: `tasks-conversation-engine.md`

---

### Epic 1.11: On-Demand Lesson Library ❌ (Post-MVP)

---

### Epic 1.12: Social Features ❌ (Post-MVP)

---

## 🔗 MODULE 2: Data Integration & Events

### Epic 2.1: Engagement Events Logging ✅  
### Epic 2.2: Wearable Integration ✅  
### Epic 2.3: Coaching Interaction Log ✅  

---

## 🤖 MODULE 3: AI & Personalization

### Epic 3.1: Motivation Profile ⚪  
### Epic 3.2: AI Nudge Optimizer ⚪  
Subtasks:
- 3.2.1: LightGBM retraining + Vertex deployment  
- 3.2.2: Contextual Bandit logic  
- 3.2.3: Caching + large-payload handling  
- 3.2.4: ✨ Experimentation support via Model Gateway  

### Epic 3.3: Context-Aware Recommendations ⚪

---

## 🧑‍⚕️ MODULE 4: Coaching & Support

### Epic 4.1: Coach Dashboard Alpha ⚪ (Consider for MVP)
### Epic 4.2–4.3: Messaging + Escalation ⚪  
### Epic 4.4: Provider Visit Analysis ❌ (Post-MVP)

---

## 📊 MODULE 5: Analytics & Admin

### Epic 5.1: User Segmentation ⚪  
### Epic 5.2: Admin Dashboard ⚪  
Subtask: 5.2.1: Grafana integration  

### Epic 5.3: Feature Flags ⚪  
✨ Moved to early phase for MVP control and testing safety

---

## 🧪 MODULE 6: AI Infrastructure

### Epic 6.1: Model Gateway ✅  
### Epic 6.2: Coach Memory ⚪  
### Epic 6.3: Score Registry ⚪  
### Epic 6.4: Embedding Layer ❌ (Post-MVP)

---

## 📦 Global MVP Readiness Requirements (Non-Functional)

- ✅ CI/CD with auto deployment, rollback, signed artifacts  
- ✅ Feature flags for all experimental modules  
- ⚪ App store metadata, screenshots, legal/privacy policies  
- ⚪ Performance SLAs: cold-start, RAM, background sync  
- ⚪ Security: HIPAA audit trail, user data export controls  
- ⚪ Error tracking (Sentry or equivalent)  
- ⚪ In-app feedback widget for tester cohort  
- ⚪ Accessibility: WCAG color/contrast, font-scaling  
- ⚪ Internationalization: future-proof RTL and language switching  
- ⚪ Smoke test scripts for major features

---

**Last updated:** July 2025 – Refined for Epic-based sprint generation and MVP launch sequencing.

🧭 Recommended Next Steps

Now that your CI/CD and test infra is live, your priority shifts from setup to maturity and validation. Here’s what I recommend:

⸻

1. Perform a CI/QA Infrastructure Audit

Ask Cursor AI (or another assistant) to:
    •    Scan all test-related files, pipeline configs, and project folder structure
    •    Assess test coverage breadth:
    •    Does each major feature (e.g., Momentum Score, Action Steps, PES) have automated test coverage?
    •    Are there tests for edge cases, failure states, and auth logic?
    •    Identify gaps in:
    •    Integration test coverage (e.g., auth + PES working together)
    •    UI golden path flows (e.g., onboarding → dashboard → action step)
    •    Critical model outputs (JITAI scoring, LGBM, etc.)

2. Formalize Your Test & QA Expectations

Add a new Epic (or checklist) called “QA Validation & Coverage Enforcement” with items like:
    •    ✅ Add test coverage targets by module (e.g., “90% for AI Coach, 75% for onboarding”)
    •    ✅ Use flutter_coverage or similar to track coverage by file
    •    ✅ Define required test types:
    •    Unit tests for all service classes
    •    Integration tests for critical flows
    •    Smoke test suite to run on every deploy
    •    ✅ Add codecov.io or GitHub coverage badge to enforce standards
    
Area                    Action
Test Quality            ✅ Ask Cursor AI to audit by module
Coverage Maturity       ✅ Add a formal checklist per Epic/module
Crash Reporting         ✅ Add Sentry/Crashlytics if missing
QA Culture              ✅ Document expectations in the repo/wiki

