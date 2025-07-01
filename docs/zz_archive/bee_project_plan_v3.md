# BEE Project Plan – v3 (Merged Structure + MVP)

This is the fully merged project structure including the original project vision
(v2) and the serialized, detailed MVP roadmap defined in June 2025.

---

## 🧭 Full Project Structure

# BEE Project Structure – Unified MVP Roadmap (Updated)

> This is the updated definitive source of truth for the **BEE** (Behavioral
> Engagement Engine) roadmap, incorporating MVP refinements from June 2025
> planning discussions.

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

## 🧱 MODULE 1: Core Mobile Experience

### ✅ Epic 1.1: Momentum Meter

_Complete_ – Real-time user momentum score with decay + visualization.

### ✅ Epic 1.2: Today Feed

_Updated Scope_: Now includes:

- 3x/week program content (habit science, motivation, behavior change)
- 3x/week lifestyle content (nutrition, sleep, movement, etc.)
- 1x/week fun content (joke, fun fact = variable reward)

### 🟡 Epic 1.3: Adaptive AI Coach

_In progress – Phase 1 complete; advanced JITAI logic Phase 3_

- Conversational AI support
- Emotionally aware tone
- Triggers based on Momentum and biometric signals
- AI coach analyzes each chat for motivational cues--low motivation, neutral, or
  high motivation
- AI coach updates analytics with 'AI motivation assessment score'. This score
  in turn, is used in Momentum Score calculation.
- Real-time wearable feedback loop (listener → Coach → UI push)
- Strict RLS policies & tenant checks for coach tables
    (`coach_chat_log`, `nlp_insights`, `coaching_effectiveness`)

### ⚪ Epic 1.4: In-App Messaging

_Planned_

- Secure coach-patient messaging
- Future: AI + human routing

### 🟡 Epic 1.5: Habit Architect

_Enhanced Scope_

- Users define **action steps** (process goals)
- Completion tracked and integrated into Momentum Score
- Escalation logic if 3+ missed completions in 7 days

### ⚪ Epic 1.6: Active-Minutes Insights

_Planned_

- From wearables
- Habit consistency monitoring

### ⚪ Epic 1.7: On-Demand Lesson Library

_Deprioritized_

- Deferred due to strong Today Feed + AI Coach

### ⚪ Epic 1.8: Advanced Social Features

_Planned – Post-MVP_

### 🆕 Epic 1.9: Subjective Energy Score

- 1–5 emoji scale for daily energy check-in
- Defaults to daily, can be customized
- Appears in Momentum screen
- Included in Momentum Score weighting (initially)

### 🆕 Epic 1.10: Progress to Goal Tracker

- Outcome goals captured during onboarding
- Options: Weight (default), Vitality Score (optional)
- Visual trend + motivational messaging

### 🆕 Epic 1.11: Onboarding Intake Survey

_Planned – Cross-feature survey flow_

- Multi-step intake survey UX with progress indicator
- Store raw answers in `onboarding_survey_responses` (Supabase)
- Derive profile tags (`motivation_tier`, `coach_style`, etc.) via scoring
  algorithm
- Surface tags to AI Coach and Today Feed personalization
- Emit `engagement_events:onboarding_completed`
- Dashboard metrics for survey completion

---

## 🔗 MODULE 2: Data Integration & Events

### ✅ Epic 2.1: Engagement Events Logging

- Infrastructure complete
- Needs implementation of real-time event inserts (e.g., goal completion)

### ✅ Epic 2.2: Wearable Integration Layer

- Captures steps, sleep, active energy, HR, weight
- Used for habit consistency modifier in Momentum Score

### ✅ Epic 2.3: Coaching Interaction Log

- Logs all AI + human interactions
- Tags source, timestamps, and sentiment analysis (future expansion)

---

## 🤖 MODULE 3: AI & Personalization

### ⚪ Epic 3.1: Personalized Motivation Profile

_Planned – Post-MVP_

- Learns user patterns and motivational tone

### ⚪ Epic 3.2: AI Nudge Optimizer

- Triggers messages based on biometric or behavioral changes

- **Milestone 3.2.1:** Monthly LightGBM JITAI model retraining & deployment
  (scheduled GitHub Action)
- **Milestone 3.2.2:** Contextual-bandit reward table & online learning loop
  (epsilon-greedy with nightly policy update)
- **Milestone 3.2.3:** Global KV/Redis cache & large-response handling
  middleware (GC-14)

### ⚪ Epic 3.3: Context-Aware Recommendations

- Not in MVP scope

---

## 🧑‍⚕️ MODULE 4: Coaching & Support

### ⚪ Epic 4.1: Coach Dashboard Alpha

_New for MVP testing only_

- Basic web app using **Vue.js + Supabase**
- Displays:
  - Escalation flags
  - Goal completion stats
  - Subjective energy score logs

### ⚪ Epic 4.2–4.3: Patient Messaging / Escalation

- Future implementation for production support

### ⚪ Epic 4.4: Provider Visit Analysis

- NLP processing of transcripts
- Deferred to post-MVP

---

## 📊 MODULE 5: Analytics & Admin

### ⚪ Epic 5.1: User Segmentation / Cohort Analysis

_Post-MVP_

### ⚪ Epic 5.2: Analytics Dashboard

- Behavior change and engagement trends
- **Milestone 5.2.1:** Metrics table partitioning + continuous aggregates for
  Grafana (GC-18)

### ⚪ Epic 5.3: Feature Flag & Config

- Not part of MVP

---

## 🆕 MODULE 6: Vitality Score Integration

### 🆕 Epic 6.1: Vitality Score (Metabolic Health Index)

- Based on MetS z-score (converted)
- Entered manually during onboarding or lab review
- Shown as **qualitative bands**, not percentiles:
  - Foundational
  - Improving
  - Optimizing
- Trends > snapshot; shown with caution language

---

## 🧪 MVP TESTING + DATA STRATEGY

- Focus on Tier 1 signals:
  - Goal completion
  - Coach interaction
  - Subjective energy
  - Biometrics (consistency + deltas)

- Event producers will trigger writes to `engagement_events`
- Begin training momentum decay logic and habit consistency model
- LightGBM and JITAI integration: post-MVP

---

## ✅ MVP COMPLETION CRITERIA

- [x] Momentum Meter operational
- [x] Today Feed operational
- [x] Biometric ingestion and logging
- [x] AI Coach live with basic interventions
- [x] Goal setting + action step logging
- [x] Subjective energy check-in
- [x] Manual entry of Vitality Score with bands
- [x] Coach dashboard alpha

---

## 🔮 Post-MVP: Version 1.1+ Priorities

- Coach messaging system
- Personalized Motivation Profile (AI)
- Enhanced Progress Tracker (multiple outcome types)
- NLP on transcripts to classify motivational tone
- Intervention Effectiveness Loops
- JITAI engine + ML scoring (LightGBM)

---

## 🧩 MVP Roadmap Modules and Enhancements

# BEE MVP – Master Roadmap (June 2025)

This document outlines all Epics and Modules required for the BEE Momentum Coach
MVP. Each entry links back to its source spec document and is flagged as
MVP-critical or for future release.

---

## ✅ EPIC 1: Action Step Engine

### Milestone 1.1: Weekly Goal Selection [✅ MVP]

- Users select or enter proactive action steps weekly
- AI Coach facilitates goal planning via hybrid chat + UI
- Guardrails ensure goals are valid, measurable, and motivating
- Source: [action_steps.md]

### Milestone 1.2: Daily Check-ins + Reward Logic [✅ MVP]

- Users record goal completions daily
- Momentum Score updated based on adherence
- Weekly rewards (e.g., confetti) tied to streaks/completions
- Source: [action_steps.md]

### Milestone 1.3: AI Coach Updates [✅ MVP]

- AI coach updates analytics with 'AI motivation assessment score'. This score
  in turn, is used in Momentum Score calculation.

---

## ✅ EPIC 2: AI Coach Engine

### Milestone 2.1: Feature-Specific Interactions [✅ MVP]

- Action steps, biometrics, onboarding, and goal reflection prompts
- Source: [bee_ai_coach_conversation_engine.md]

### Milestone 2.2: General Conversation Thread [✅ MVP]

- Persistent chat UI for user-initiated conversations
- Supports motivational journaling, help-seeking
- Source: [bee_ai_coach_conversation_engine.md]

### Milestone 2.3: Conversational Analyzer (Motivation Signals) [🕓 Phase 2]

- Tags emotional tone and internal/external motivation in conversation
- Language-agnostic sentiment & tone tagging (embedding + lang-detect fallback)
- Affects motivation scoring and coach responsiveness
- Source: [ai_coach_interactions.md]

### Milestone 2.4: Backend Routing + Safety Layer [✅ MVP]

- Ensures AI cannot hallucinate database writes
- Provides `updateMomentumScore()` and event insertion functions
- Source: [bee_ai_coach_conversation_engine.md]
- Strict RLS policies & tenant checks for coach tables
    (`coach_chat_log`, `nlp_insights`, `coaching_effectiveness`)

---

## ✅ EPIC 3: Engagement & Scoring

### Milestone 3.1: Momentum Score Calculation Engine [✅ MVP]

- Weighted events like action step completion, coach engagement, etc.
- Score available to AI Coach and dashboard
- Source: [momentum_score.md]

### Milestone 3.2: Motivation Score System [🕓 Phase 2]

- Uses survey results + chat signal tagging
- Future: feeds JITAI and engagement prediction
- Source: [motivation_score.md]

---

## ✅ EPIC 4: Biometrics

### Milestone 4.1: Manual Entry + Vitality Score UI [✅ MVP]

- UI for users to enter BP, weight, glucose, etc.
- Metabolic health percentile (Vitality Score) calculated locally
- Source: [biometric_integration.md]

### Milestone 4.2: Biometric Trigger Events (AI Coach) [✅ MVP]

- Biometric drops (e.g., sleep, activity) trigger check-in prompts
- AI adjusts momentum score only on confirmation
- Source: [biometric_integration.md]

---

## ✅ EPIC 5: Today Feed

### Milestone 5.1: Edge Function + Seed Prompting [✅ MVP]

- Daily article generation:
  - 3x/week: program insights
  - 3x/week: lifestyle education
  - 1x/week: fun/reward signal
- Source: [Today_Tile_prompt.md]

---

## ✅ EPIC 6: Onboarding & Assessment

### Milestone 6.1: Baseline Survey + Coaching Style [✅ MVP]

- Captures DOB, preferences, personality, coaching style, outcome goal
- Source: [onboarding_survey.md]

### Milestone 6.2: Motivation Screener [🕓 Phase 2]

- Series of questions to assess internal/external motivation
- Source: [motivation_score.md]

### Milestone 6.3: Medical Intake Survey [✅ MVP]

- Collects weight, height, BP, diabetes risk, eating disorder history
- Source: [medical_history_survey.md]

---

## 📊 Appendix: Feature Mapping by Goal

| Feature              | Epic | Milestone(s) | MVP | Source                                          |
| -------------------- | ---- | ------------ | --- | ----------------------------------------------- |
| Action Steps         | 1    | 1.1, 1.2     | ✅  | action_steps.md                                 |
| AI Chat              | 2    | 2.1–2.4      | ✅  | bee_ai_coach_conversation_engine.md             |
| Motivation Inference | 2, 3 | 2.3, 3.2     | 🕓  | motivation_score.md                             |
| Biometrics           | 4    | 4.1, 4.2     | ✅  | biometric_integration.md                        |
| Daily Feed           | 5    | 5.1          | ✅  | Today_Tile_prompt.md                            |
| Onboarding           | 6    | 6.1–6.3      | ✅  | onboarding_survey.md, medical_history_survey.md |

---

**Last updated:** June 2025
