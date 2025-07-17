# BEE Project Plan – FINAL (v4)

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
✨ New in v4
```
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

1) Registration and Auth (1.6)  ✅ Completed 
2) Core UI: Momentum Meter (1.1) ✅ Completed 
3) Event Infra: Engagement Logging (2.1), Wearables (2.2), Coaching Logs (2.3)  ✅ Completed 
4) Onboarding Intake Surveys (1.11) ✅ Completed 
5) Action Steps (1.5) ✅ Completed 
6) Biometrics (1.9) and Perceived Energy Score (1.7)
7) Momentum + Motivation Score (1.8)
8) Today Feed (1.2)
9) Adaptive AI Coach + Conversation Engine (1.3 & 1.10)
10) In-App Messaging (1.4)
11) LightGBM + Analytics Engine (3.2.1)
12) User Segmentation (5.1)
13) Coach Dashboard Alpha (4.1)
14) Admin Dashboard (5.2)

## 🧱 MODULE 1: Core Mobile Experience

### Epic 1.1: Momentum Meter ✅ Completed 
*documents: @momentum_score_calculation.md; momentum_score.md*
- Real-time score visualization with decay logic enabled
- Refine momentum score calculation to reflect multiple metrics as described in above document

- 

### Epic 1.2: Today Feed and This Week's Journey ⚪
*Documents: @today_tile_prompt.md and @today_feed_journey.md*
- Change to 3x/week program + lifestyle content and 1x/week fun/reward signal as described in document
- fix bug whereby daily scheduled cron job/Edge function not firing (manual trigger working)
- change from momentum score representation to action step subjective energy calculation (see below)

- 

### Epic 1.3: Adaptive AI Coach ⚪
*Documents: @tasks_adaptive_coach_summary.md contains current status (June 29, 2025), Epic 1.12 AI Coach Conversation Engine - @tasks-conversation-engine.md*
- build the remaining tasks delineated in @tasks_adaptive_coach_summary.md

- 

### Epic 1.4: In-App Messaging ⚪
*Documents: @in_app_messaging.md*
- Secure coach (human and AI) patient communication
- Enable the AI Coach to send proactive push notifications to users (e.g., “Great work finishing your workout!”)
- Users can tap to open the app, view the coach message, and optionally reply within the chat interface.

-

### Epic 1.5: Action Steps ⚪
*Documents: @action_steps.md*
-Help patients develop identity-based, consistent behaviors through weekly mini-goals that:
- Are proactive (approach-oriented)
- Are consistent (5–7 days per week) based on their own, user-set goals
- Support internal motivation and confidence
- Allow tracking and reflection
- Opportunity for AI (and human) Coach to support behavior change
- Completion/non-completion of action steps is a significant contributor to Momentum Score

- 

### Epic 1.6: Registration and Auth ✅ Completed 
*Documents: @auth_registration.md;*
- This module will handle secure user account creation, login, and authentication state 
- Create UX features for login and password recovery
- Supabase will be used as the backend for authentication and user data management.

- 

### Epic 1.7: Perceived Energy Score ⚪
*Documents: @perceived_energy_score.md*
- The Perceived Energy Score (PES) allows users to log how energized they feel on a scale from 1 to 5. 
- This value is user-entered, reflects subjective wellness, and contributes to visual trend displays and backend behavioral analytics. 
- It will also dynamically inform the AI Coach’s messaging.

- 

### Epic 1.8: Momentum-Motivation Score ⚪
*Documents: momentum_score.md; momentum_score_algoritm.md; motivation_score_algorithm.md; motivation_score_implementation.md;*
- Motivation Score is used to assess and support the transition from **external** to **internal** motivation in lifestyle change. 
  - It supports long-term behavioral resilience and integrates with coach conversations, biometric patterns, journaling, and in-app prompts.
- Momentum Score is a determinant of *Engagement* and is used to predict and identify early disengagement, allowing intervention early using tools such as AI our human outreach and curating content and messages accordingly. 
- Momentum Score is shown to the user on the Momentum Gauge widget, and used on the backend by the AI analytics system to generate interventions
- The system will learn how interventions influence behavior--positive, negative, or neutral, to improve the fidelity of interventions as users move through the program
- At the end of this Epic, users will have a momentum score calculated as designed that is visible on the Momentum Gauge

- 

### Epic 1.9: Biometrics (labs, vitals) Entry and Perceived Energy Score ⚪
*documents: @biometrics_pes.md; biometrics_integration.md*
- User will enter biometrics manually and will include lab values and vital signs
- User will enter a Perceived Energy Score at a cadence of their choosing (1-7 days)
- At the end of this Epic, the user will have a UI to enter the data, which will be saved to supabase
- The biometrics data will be available for the patient to view in the UX and will be used in calculation of Momentum Score
- Perceived Energy Score will be visible on This Week's Journey widget and also used in calculating Momentum Score

- 

### Epic 1.10: AI Coach Conversation Engine ⚪
*documents: tasks-conversation-engine.md*
- The Conversation Engine transforms the AI Coach from a single feature into a
shared _interaction layer_ that:\
• Enables feature-specific prompts & nudges\
• Mediates engagement between modules (Momentum, Today Feed, Wearables…)\
• Logs all coach/user dialogue as a first-class data stream\
• Enforces security, latency (<1 s p95) and cost guard-rails across teams

- 

### Epic 1.11: Onboarding Intake Surveys ⚪
*documents: @onboarding_survey.md; onboarding_survey_scoring.md; medical_history_survey.md*
- This Epic is designed to implement the onboarding experience for new users.
- After registration, all new users will proceed through an onboarding process that consists of surveys and a medical history



### Epic 1.12: On-Demand Lesson Library ⚪ (Post-MVP)
- The On-Demand Lesson Library provides users with easy access to structured educational content (FAQs, lesson PDFs, NotebookLM podcasts) hosted on WordPress. 
- It serves as a learning component in the BEE platform, offering searchable, filterable, and offline-accessible educational resources that support users' health journey while integrating with the momentum meter to reward learning engagement.
- 

### Epic 1.13: Social Features ⚪ (Post-MVP)
- Deferred
---

## 🔗 MODULE 2: Data Integration & Events

### Epic 2.1: Engagement Events Logging ✅ Completed 
### Epic 2.2: Wearable Integration ✅ Completed 
### Epic 2.3: Coaching Interaction Log ✅ Completed 

---

## 🤖 MODULE 3: AI & Personalization

### Epic 3.1: Motivation Profile ⚪

### Epic 3.2: AI Nudge Optimizer ⚪
- 3.2.1: LightGBM retraining + Vertex deployment
- 3.2.2: Contextual Bandit policy logic
- 3.2.3: Caching and large-payload handling
- ✨ 3.2.4: Experimentation support via Model Gateway

### Epic 3.3: Context-Aware Recommendations ⚪
- embed-based suggestions from Module 7.4

---

## 🧑‍⚕️ MODULE 4: Coaching & Support

### Epic 4.1: Coach Dashboard Alpha ⚪
### Epic 4.2–4.3: Messaging + Escalation ⚪
### Epic 4.4: Provider Visit Analysis ⚪ ❌ (Post-MVP)

---

## 📊 MODULE 5: Analytics & Admin

### Epic 5.1: User Segmentation ⚪
### Epic 5.2: Admin Dashboard Alpha ⚪
      - 5.2.1: Metrics aggregation for Grafana

### Epic 5.3: Feature Flags ⚪

---

---

## 🧪 MODULE 6: AI Infrastructure & Model Layer ✨

### Epic 6.1: Model Gateway ✅
- Unified API abstraction for all scoring models

### Epic 6.2: Coach Memory ⚪
- Per-user tone and preference storage

### Epic 6.3: Score Registry ⚪
- Central tracking of predictions per user and model

### Epic 6.4: Embedding Layer ❌ (Post-MVP)

---

## 🧮 MVP Completion Criteria

- [x] Real-time Momentum Meter
- [x] Daily Today Feed
- [x] Biometric ingestion + logging
- [x] AI Coach v1 with chat + scoring tags
- [x] Goal setting + check-ins
- [x] Subjective energy score
- [x] Vitality Score bands
- [x] Coach dashboard
- [x] Model Gateway abstraction

---

## 🚀 Suggested Development Flow

1. Core UI (Modules 1.1–1.2)
2. Event infra (Module 2)
3. AI Coach MVP (1.3, 7.1, 7.2)
4. LightGBM + Vertex setup (3.2.1)
5. Momentum Score + Dashboard
6. Phase 2 Modules (e.g. Messaging, Motivation Profile)

---

## 🔮 Post-MVP Evolution Paths

### ⚡ Option B: Agentic AI Coach
- Enhance `coach_memory`
- Add orchestrator & function tools
- Predict optimal engagement windows

### 🧠 Option C: Foundation Model
- Store joint embeddings in 7.4
- Replace gateway with multi-modal transformer
- Unified coaching intelligence

---

**Last updated:** July 2025 – Final consolidated plan for AI-powered behavior engagement engine.
