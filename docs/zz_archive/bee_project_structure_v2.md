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

### 🟡 Epic 1.2: Today Feed

_In progress_: Next steps will add the following:

- 3x/week program content (habit science, motivation, behavior change)
- 3x/week lifestyle content (nutrition, sleep, movement, etc.)
- 1x/week fun content (joke, fun fact = variable reward)

### 🟡 Epic 1.3: Adaptive AI Coach

_In progress – Phase 1 complete; advanced JITAI logic Phase 3_

- Conversational AI support
- Emotionally aware tone
- Triggers based on Momentum and biometric signals
- AI coach analyzes each chat for motivational cues--low motivation, neutral, or high motivation
- AI coach updates analytics with 'AI motivation assessment score'. This score in turn, is used in Momentum Score calculation. 

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
- Minor integration fixes to improve data capture

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
