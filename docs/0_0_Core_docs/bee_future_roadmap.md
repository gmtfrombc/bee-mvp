# BEE Future Roadmap – Post-MVP Expansion

> This document outlines the high-level plan **after** the current BEE MVP (as
> defined in `bee_project_structure.md`) is complete. It is intentionally
> forward-looking and should be treated as a living roadmap.

---

## 🌱 Guiding Principles

1. **Build on working foundations** – Ship incremental, user-visible wins fast.
2. **Evidence-driven iteration** – Every new model or feature must come with a
   measurable hypothesis and success metric.
3. **Cost & safety first** – Optimise for low latency, transparent decisions,
   and HIPAA/GDPR compliance.

---

## 🚀 Phase 4 (Quarters 3-4 2025) – Intelligent Personalisation

### Epic 3.4 – Advanced JITAI Engine

| Milestone  | Deliverable                                       | Notes                                          |
| ---------- | ------------------------------------------------- | ---------------------------------------------- |
| **M3.4.1** | LightGBM/XGBoost upgrade for predictive triggers  | Non-linear thresholds automatically handled    |
| **M3.4.2** | Hierarchical / mixed-effects layer (`patient_id`) | Rapid per-user fine-tuning                     |
| **M3.4.3** | Contextual-bandit intervention selector           | Learns best nudge per user over time           |
| **M3.4.4** | Real-time feature store & online learning loop    | <100 ms updates; enables day-0 personalisation |

### Epic 3.5 – Multimodal Sentiment Pipeline

| Milestone  | Deliverable                                  | Notes                                 |
| ---------- | -------------------------------------------- | ------------------------------------- |
| **M3.5.1** | Speech-to-text pipeline for visit recordings | Google Speech / Whisper-large         |
| **M3.5.2** | Embedding extraction & storage               | OpenAI `text-embedding-3-small`       |
| **M3.5.3** | Emotion & motivation classifiers             | Fine-tuned small BERT                 |
| **M3.5.4** | Integration into JITAI feature set           | Adds linguistic early-warning signals |

### Epic 3.6 – Motivation State Forecaster

| Milestone  | Deliverable                                                        | Notes                                           |
| ---------- | ------------------------------------------------------------------ | ----------------------------------------------- |
| **M3.6.1** | Seq2Seq or Temporal Fusion Transformer predicting 7-day engagement | Runs nightly in Vertex AI                       |
| **M3.6.2** | Coach scheduling API                                               | Surfaces "high-risk next week" flags to coaches |

---

## 🩺 Phase 5 (2026) – Clinical-Grade Coaching

1. **Closed-loop efficacy trials** with IRB oversight.
2. **Explainability dashboard** for clinicians (SHAP values on triggers).
3. **FDA SaMD pre-submission** groundwork.
4. **Privacy-preserving federated learning** to fine-tune models without
   centralising PHI.

---

## ⚠️ Parking Lot (Explore / R&D)

- Video emotion detection (face & posture cues).
- Wearable-only, on-device TinyML fallback for offline coaching.
- GPT-4o custom fine-tune for healthcare motivational interviewing.

---

_Last updated: {{TODAY}}_
