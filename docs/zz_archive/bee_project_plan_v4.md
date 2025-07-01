# BEE Project Plan – v4 (Hybrid AI with Future-Proofing)

This is the updated project structure incorporating the MVP goals for a hybrid AI system (LightGBM + LLMs), while also enabling future evolution to agentic (Path B) and multimodal AI (Path C). This version integrates architectural safeguards and infrastructure needed to support long-term scalability.

---

## 📍 Project Structure Overview

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

### Epic 1.1: Momentum Meter ✅
- Real-time score visualization with decay logic.

### Epic 1.2: Today Feed ✅
- 3x/week program + lifestyle content
- 1x/week fun/reward signal

### Epic 1.3: Adaptive AI Coach ⚪
- Conversational AI (LLM-driven)
- Emotionally aware tone
- Feature-specific chat hooks
- Motivation tagging
- ⚡ Now uses `model_gateway` and `coach_memory`

### Epic 1.4: In-App Messaging ⚪
- Secure coach-patient communication
- AI + human routing (future)

### Epic 1.5: Habit Architect 🔹
- Weekly action steps
- Escalation logic after missed goals

### Epic 1.6: Active-Minutes Insights ⚪

### Epic 1.7: On-Demand Lesson Library ⚪ (Deferred)

### Epic 1.8: Social Features ⚪ (Post-MVP)

### Epic 1.9: Subjective Energy Score ⚪
- 1–5 emoji check-in
- Integrated into momentum score

### Epic 1.10: Progress to Goal Tracker ⚪

### Epic 1.11: Onboarding Intake Survey ⚪
- Multi-step onboarding flow
- Emits `engagement_events:onboarding_completed`

---

## 🔗 MODULE 2: Data Integration & Events

### Epic 2.1: Engagement Events Logging ✅
### Epic 2.2: Wearable Integration ✅
### Epic 2.3: Coaching Interaction Log ✅

---

## 🤖 MODULE 3: AI & Personalization

### Epic 3.1: Motivation Profile ⚪ (Post-MVP)

### Epic 3.2: AI Nudge Optimizer ⚪
- Milestone 3.2.1: LightGBM model retraining
- Milestone 3.2.2: Contextual Bandit logic
- Milestone 3.2.3: Global cache handling
- ✨ Milestone 3.2.4: Add experimentation engine via `model_gateway`

### Epic 3.3: Context-Aware Recommendations ⚪
- Future support for embedded vector similarity using `embedding_shadow_layer`

---

## 🧑‍⚕️ MODULE 4: Coaching & Support

### Epic 4.1: Coach Dashboard Alpha ⚪
### Epic 4.2–4.3: Messaging & Escalation ⚪
### Epic 4.4: Provider Visit Analysis ⚪ (Post-MVP)

---

## 📊 MODULE 5: Analytics & Admin

### Epic 5.1: Cohort Analysis ⚪
### Epic 5.2: Analytics Dashboard ⚪
- Milestone 5.2.1: Metrics table partitioning for Grafana

### Epic 5.3: Feature Flag + Config ⚪

---

## 🧬 MODULE 6: Vitality Score Integration

### Epic 6.1: Vitality Score UI ⚪
- Based on MetS z-score
- Qualitative banding + trend graphing

---

## 🧪 MODULE 7: AI Infrastructure & Model Layer ✨ **[NEW]**

### Epic 7.1: Model Gateway Interface ✅
- Unified API for model scoring (LLM, LightGBM, etc.)
- Enables hot-swapping and experimentation

### Epic 7.2: Coach Memory Store ⚪
- Store user-specific traits (tone, timing, preferences)
- Optional Redis or Supabase `coach_memory` table

### Epic 7.3: Model Scoring Registry ⚪
- `user_model_scores` table logs all scores
- Enables future ensemble models and per-model evaluation

### Epic 7.4: Embedding Shadow Layer ❌ (Post-MVP)
- Vector representation of tabular + text inputs
- Future support for multimodal or retrieval-based systems

---

## ✅ MVP Completion Criteria (Updated)

- [x] Real-time Momentum Meter
- [x] Daily Today Feed
- [x] Biometric ingestion + logging
- [x] AI Coach v1 with feature chat + motivation tagging
- [x] Goal setting + action step tracking
- [x] Subjective energy input
- [x] Vitality Score intake
- [x] Coach dashboard alpha
- [x] Model gateway abstraction in use

---

## 🔮 Post-MVP Evolution Paths

### ⚡ Option B: Agentic AI Coach
- Enhance `coach_memory`
- Add orchestration layer (Planner + Tools)
- Use stored insights to determine timing + escalation

### 🧠 Option C: Foundation Model Integration
- Embedding layer stores text+tabular representations
- Replace model gateway with single multimodal API call
- LLM agent accesses user state, history, intent, and behavior

---

**Last updated:** July 2025 – incorporates hybrid MVP scope + AI extensibility
