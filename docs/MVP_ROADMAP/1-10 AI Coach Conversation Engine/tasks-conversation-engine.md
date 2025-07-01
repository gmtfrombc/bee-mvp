# Epic 1.12 · AI Coach Conversation Engine

**Module:** Cross-Cutting Interaction Layer\
**Status:** ⚪ Not Started\
**Owner:** Engagement Platform Team\
**Dependencies:** Epic 1.3 Core AI, Engagement Events (2.1), Wearables (2.2)

---

## 📋 Epic Overview

The Conversation Engine transforms the AI Coach from a single feature into a
shared _interaction layer_ that:\
• Enables feature-specific prompts & nudges\
• Mediates engagement between modules (Momentum, Today Feed, Wearables…)\
• Logs all coach/user dialogue as a first-class data stream\
• Enforces security, latency (<1 s p95) and cost guard-rails across teams

This epic creates the APIs, infrastructure and observability needed for every
squad to plug into the coach safely and consistently.

---

## 🚀 Strategic Milestones

### **M1.12.1 – Feature-Specific Interaction Hooks** ⚪ Planned

Enable any feature to trigger or consume coach messages via a lightweight
contract.

| Task          | Description                                                                          | Status     |
| ------------- | ------------------------------------------------------------------------------------ | ---------- |
| **T1.12.1.1** | Publish `CoachInteractionService` TS/Flutter SDK with `triggerCoachMessage()` helper | ⚪ Planned |
| **T1.12.1.2** | Add action-step, biometric, energy-score hooks in app → Edge Fn payload              | ⚪ Planned |
| **T1.12.1.3** | Insert corresponding engagement events into `engagement_events`                      | ⚪ Planned |
| **T1.12.1.4** | Unit tests & example snippets for each feature                                       | ⚪ Planned |

**Deliverables**\
• Versioned API spec (OpenAPI + TypeDefs)\
• Demo calls from Action-Steps & Biometrics modules\
**Acceptance Criteria**\
• Any feature can invoke coach in ≤100 ms overhead\
• Events logged with correct `event_type` & JSON schema

---

### **M1.12.2 – General AI Conversation Thread** ⚪ Planned

Persistent, open chat channel independent of feature context.

| Task          | Description                                               | Status     |
| ------------- | --------------------------------------------------------- | ---------- |
| **T1.12.2.1** | Secure "General Chat" UI component with Riverpod provider | ⚪ Planned |
| **T1.12.2.2** | Pagination & lazy-load of chat history (∞ scroll)         | ⚪ Planned |
| **T1.12.2.3** | Log messages to `coach_chat_log` table                    | ⚪ Planned |
| **T1.12.2.4** | Intent-classification stub & tag storage                  | ⚪ Planned |

**Deliverables**\
• Re-usable chat widget\
• Supabase schema `coach_chat_log`\
**Acceptance Criteria**\
• Chat available 24/7\
• Messages persist & reload across sessions\
• Privacy: only user & coach can read their thread

---

### **M1.12.3 – Conversational Event Analyzer** ⚪ Planned

Post-processing pipeline that tags messages with behavioural signals.

| Task          | Description                                                | Status     |
| ------------- | ---------------------------------------------------------- | ---------- |
| **T1.12.3.1** | Define taxonomy (motivation language, frustration, pride…) | ⚪ Planned |
| **T1.12.3.2** | Implement tagging via GPT function-calling or regex rules  | ⚪ Planned |
| **T1.12.3.3** | Write tags to `nlp_insights` with confidence score         | ⚪ Planned |
| **T1.12.3.4** | Link high-confidence tags to engagement-score modifiers    | ⚪ Planned |

**Deliverables**\
• Tagging service (Edge Fn / job)\
• Insight schema & Supabase policy\
**Acceptance Criteria**\
• ≥ 80 % precision on validation set\
• Processing <500 ms per message\
• Momentum score adjusts within next daily batch

---

### **M1.12.4 – Backend Routing & Role Enforcement** ⚪ Planned

Secure, auditable server actions callable by the AI.

| Task          | Description                                                                                | Status     |
| ------------- | ------------------------------------------------------------------------------------------ | ---------- |
| **T1.12.4.1** | Implement RPCs: `updateMomentumScore`, `insertEngagementEvent`, `flagUserForHumanFollowUp` | ⚪ Planned |
| **T1.12.4.2** | API-key & RLS rules limiting calls to validated system roles                               | ⚪ Planned |
| **T1.12.4.3** | Append audit log record for every call (who/when/why)                                      | ⚪ Planned |
| **T1.12.4.4** | Automated tests for abuse scenarios                                                        | ⚪ Planned |

**Deliverables**\
• RPC functions & Supabase policies\
• Audit dashboard (Grafana/SQL)\
**Acceptance Criteria**\
• Calls only succeed with service role or signed function\
• 100 % audit coverage, no PHI leakage

---

### **M1.12.5 – Observability & Guard-Rails** ⚪ Planned

Holistic monitoring, rate-limit & cost controls.

| Task          | Description                                          | Status     |
| ------------- | ---------------------------------------------------- | ---------- |
| **T1.12.5.1** | Expand metrics: token cost, prompt latency histogram | ⚪ Planned |
| **T1.12.5.2** | Grafana dashboard: SLA & cost per user/day           | ⚪ Planned |
| **T1.12.5.3** | End-to-end chaos tests (API outage, high latency)    | ⚪ Planned |
| **T1.12.5.4** | Red-flag detector coverage >95 % unit test           | ⚪ Planned |

**Deliverables**\
• Metrics table + Grafana panels\
• Chaos test suite in CI\
**Acceptance Criteria**\
• p95 latency < 1 s\
• Monthly token spend alerts trigger at 80 % budget\
• Safety unit tests stay ≥ 95 % pass rate

---

## ✅ Definition of Done

Epic is complete when: • All milestones reach ✅ status.\
• Any app module can interact with the coach through documented APIs.\
• Observability dashboards show p95 < 1 s & red-flag coverage > 95 %.\
• Security audit passes: no unauthorised data mutations, full audit trail.
