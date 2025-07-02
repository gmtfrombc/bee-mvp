
# BEE MVP – Master Roadmap (June 2025)

This document outlines all Epics and Modules required for the BEE Momentum Coach MVP. Each entry links back to its source spec document and is flagged as MVP-critical or for future release.

---

## ✅ EPIC 1: Action Step Engine

### Module 1.1: Weekly Goal Selection [✅ MVP]
- Users select or enter proactive action steps weekly
- AI Coach facilitates goal planning via hybrid chat + UI
- Guardrails ensure goals are valid, measurable, and motivating
- Source: [action_steps.md]

### Module 1.2: Daily Check-ins + Reward Logic [✅ MVP]
- Users record goal completions daily
- Momentum Score updated based on adherence
- Weekly rewards (e.g., confetti) tied to streaks/completions
- Source: [action_steps.md]

---

## ✅ EPIC 2: AI Coach Engine

### Module 2.1: Feature-Specific Interactions [✅ MVP]
- Action steps, biometrics, onboarding, and goal reflection prompts
- Source: [bee_ai_coach_conversation_engine.md]

### Module 2.2: General Conversation Thread [✅ MVP]
- Persistent chat UI for user-initiated conversations
- Supports motivational journaling, help-seeking
- Source: [bee_ai_coach_conversation_engine.md]

### Module 2.3: Conversational Analyzer (Motivation Signals) [🕓 Phase 2]
- Tags emotional tone and internal/external motivation in conversation
- Affects motivation scoring and coach responsiveness
- Source: [ai_coach_interactions.md]

### Module 2.4: Backend Routing + Safety Layer [✅ MVP]
- Ensures AI cannot hallucinate database writes
- Provides `updateMomentumScore()` and event insertion functions
- Source: [bee_ai_coach_conversation_engine.md]

---

## ✅ EPIC 3: Engagement & Scoring

### Module 3.1: Momentum Score Calculation Engine [✅ MVP]
- Weighted events like action step completion, coach engagement, etc.
- Score available to AI Coach and dashboard
- Source: [momentum_score.md]

### Module 3.2: Motivation Score System [🕓 Phase 2]
- Uses survey results + chat signal tagging
- Future: feeds JITAI and engagement prediction
- Source: [motivation_score.md]

---

## ✅ EPIC 4: Biometrics

### Module 4.1: Manual Entry + Vitality Score UI [✅ MVP]
- UI for users to enter BP, weight, glucose, etc.
- Metabolic health percentile (Vitality Score) calculated locally
- Source: [biometric_integration.md]

### Module 4.2: Biometric Trigger Events (AI Coach) [✅ MVP]
- Biometric drops (e.g., sleep, activity) trigger check-in prompts
- AI adjusts momentum score only on confirmation
- Source: [biometric_integration.md]

---

## ✅ EPIC 5: Today Feed

### Module 5.1: Edge Function + Seed Prompting [✅ MVP]
- Daily article generation:
  - 3x/week: program insights
  - 3x/week: lifestyle education
  - 1x/week: fun/reward signal
- Source: [Today_Tile_prompt.md]

---

## ✅ EPIC 6: Onboarding & Assessment

### Module 6.1: Baseline Survey + Coaching Style [✅ MVP]
- Captures DOB, preferences, personality, coaching style, outcome goal
- Source: [onboarding_survey.md]

### Module 6.2: Motivation Screener [🕓 Phase 2]
- Series of questions to assess internal/external motivation
- Source: [motivation_score.md]

### Module 6.3: Medical Intake Survey [✅ MVP]
- Collects weight, height, BP, diabetes risk, eating disorder history
- Source: [medical_history_survey.md]

---

## 📊 Appendix: Feature Mapping by Goal

| Feature | Epic | Module(s) | MVP | Source |
|--------|------|-----------|-----|--------|
| Action Steps | 1 | 1.1, 1.2 | ✅ | action_steps.md |
| AI Chat | 2 | 2.1–2.4 | ✅ | bee_ai_coach_conversation_engine.md |
| Motivation Inference | 2, 3 | 2.3, 3.2 | 🕓 | motivation_score.md |
| Biometrics | 4 | 4.1, 4.2 | ✅ | biometric_integration.md |
| Daily Feed | 5 | 5.1 | ✅ | Today_Tile_prompt.md |
| Onboarding | 6 | 6.1–6.3 | ✅ | onboarding_survey.md, medical_history_survey.md |

---

**Last updated:** June 2025
