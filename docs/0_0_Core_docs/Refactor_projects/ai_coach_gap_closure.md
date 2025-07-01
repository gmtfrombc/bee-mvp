# AI Coach – Gap Closure Plan

> Consolidated tasks required _before or in parallel with_ Epic 1.12
> (Conversation Engine).

## 🔴 High-Priority Blockers (must complete first)

| Task ID  | Description                                                                                     | Owner                  | Status     |
| -------- | ----------------------------------------------------------------------------------------------- | ---------------------- | ---------- |
| **GC-1** | Pass Today-Feed article context (`article_id`, `summary`) from Flutter → Edge Fn prompt builder | Mobile & Backend       | ✅ Done    |
| **GC-2** | Implement Conversation-Quality feedback loop (UI rating + EffectivenessTracker auto analysis)   | Mobile UI & AI Backend | ✅ Done    |
| **GC-3** | Close accessibility gaps in chat UI (semantic labels, text-scale support, screen-reader hints)  | Mobile UI              | ✅ Done    |
| **GC-4** | Harden API-key / role enforcement tests for `X-System-Event` calls & audit-log coverage         | Platform Security      | ✅ Done    |

## 🟡 Nice-to-Have (can run in parallel)

| Task ID   | Description                                                                          | Owner                 | Status   |
| --------- | ------------------------------------------------------------------------------------ | --------------------- | -------- |
| **GC-5**  | Add progress-celebration & milestone tracker (Momentum achievements)                 | Gamification Squad    | ✅ Done  |
| **GC-6**  | Expand coaching analytics dashboard (token spend, latency percentiles, helpful-rate) | DevOps                | ✅ Done  |
| **GC-7**  | Replace LightGBM stub with trained model + CI export script                          | Data Science          | ✅ Done  |
| **GC-8**  | Deploy Vertex AI endpoint + switch predictive-trigger model URL                      | ML Infra              | ✅ Done  |
| **GC-9**  | Add patient-ID hierarchical layer to JITAI model features                            | ML Infra              | ✅ Done  |
| **GC-10** | Implement contextual-bandit reward table & learning loop                             | Data Science          | 🟡 Moved |
| **GC-11** | Wire embedding service into transcript logging pipeline                              | AI Backend            | ✅ Done  |
| **GC-12** | End-to-end wearable stream → coach → UI live feedback (M1.10.2)                      | Wearables & Mobile UI | 🟡 Moved |

## 📝 Notes

- High-priority blockers must be resolved before Epic 1.12 milestones can exit
  _In Progress_.
- Nice-to-Haves improve coach quality & analytics but do not block API surface
  definition.
- Update this file via PR checklist; each task closes when merged tests pass.

### ➕ Additional Quality & Security Tasks

| Task ID   | Description                                                                                            | Owner             | Status   |
| --------- | ------------------------------------------------------------------------------------------------------ | ----------------- | -------- |
| **GC-13** | Add strict RLS policies + tenant checks for `coach_chat_log`, `nlp_insights`, `coaching_effectiveness` | Platform Security | 🟡 Moved |
| **GC-14** | Introduce global KV/Redis cache, cap cached response size & handle large GPT outputs                   | AI Backend        | 🟡 Moved |
| **GC-15** | Ensure fetch abort cleanup; add null-safe branch to momentum listener for new users                    | Backend           | ✅ Done  |
| **GC-16** | Upgrade sentiment pipeline to language-agnostic (embedding + language detect) or tone-tag fallback     | AI Backend        | 🟡 Moved |
| **GC-17** | Implement `X-Request-Id` middleware; propagate to logs & responses                                     | DevOps            | ✅ Done  |
| **GC-18** | Partition/roll-up metrics tables; add continuous aggregate view for Grafana panels                     | DevOps            | 🟡 Moved |
| **GC-19** | Add negative-case unit tests for red-flag detector; raise coverage >90 %                               | QA                | ✅ Done  |
| **GC-20** | Add accessibility golden tests for chat UI (semantic labels, screen-reader hints)                      | Mobile UI         | ✅ Done  |
