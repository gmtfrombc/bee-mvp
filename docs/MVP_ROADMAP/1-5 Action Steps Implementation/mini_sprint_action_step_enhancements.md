#Mini-Sprint Spec – "Action Step Enhancements"   

> Version 0.1 · **Draft** – _Last updated: <!-- yyyy-mm-dd auto-filled by commit hook -->_

## 1 Overview
This mini-sprint extends the Weekly **Action Step** feature to resolve three high-priority gaps found during QA:

1️⃣ Restore the ability to **add** a new Action Step when one already exists (weekly rollover / manual reset).
2️⃣ Surface daily **completion logging** so users can mark the step “done” or “skipped” and update progress in real-time.
3️⃣ Provide a **history view** so users can review previous weeks’ Action Steps and outcomes.

Combined, these changes close QA issues 1–3 and unlock full _Plan → Do → Reflect_ workflow.

## 2 Goals
• Seamless goal-setting every week without hidden UI paths.  
• Simple, one-tap daily check-in with instant progress feedback.  
• Transparent record of past Action Steps (description, target, result ✅/❌).

## 3 Scope & Deliverables
* **UX changes** to Momentum Screen & My Action Step page.
* **New page** `ActionStepHistoryPage` (`/action-step/history`).
* **Weekly reset logic**: auto-prompt or manual button to set a new step each Monday.
* **Persistence** of daily logs in `action_step_logs` (existing table).
* **Analytics** events for history view & weekly reset.
* **Unit / widget tests** (≥ 90 % coverage for new code).
* **Doc updates** (this file + QA script).

## 4 Task Breakdown
| ID | Task | Status |
|----|------|--------|
| T11 | Enable weekly rollover / “Add New Action Step” button | ✅ Done |
| T12 | Embed `DailyCheckinCard` & wire Supabase persistence | ⚪ Planned |
| T13 | Build `ActionStepHistoryPage` with paginated list view | ⚪ Planned |
| T14 | Repo methods: `createLog()`, `fetchHistory()` | ⚪ Planned |
| T15 | Update analytics hooks (view/history/reset) | ⚪ Planned |
| T16 | Unit & widget test suite | ⚪ Planned |
| T17 | QA doc & l10n strings update | ⚪ Planned |

## 5 Acceptance Criteria
1. On Monday **or** after deleting a step, tapping Action-Step card opens **Setup** page.  
2. Daily check-in card visible under Momentum; buttons update progress within ≤ 1 s.  
3. `action_step_logs` reflects completion/skip with correct `day`, `status`, `user_id`.  
4. My Action Step displays real-time `X / Y this week` based on logs.  
5. History page lists at least the last 8 weeks, showing description, frequency, and ✅/❌ badge.  
6. All new & existing tests pass (`flutter test`).  
7. Static analysis passes (`flutter analyze --fatal-warnings`).

## 6 Out-of-Scope
* Multiple concurrent Action Steps.  
* Editing past steps retroactively.  
* Coach AI auto-suggestion improvements (handled in separate epic).

## 7 Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Supabase latency affects progress updates | Medium | Optimistic UI + refresh on Realtime event |
| Weekly reset confuses users | Low | Add prompt tooltip + onboarding tooltip |

## 8 Timeline
Target completion: **3 dev days** (coding + QA + review).

---
_End of document_

<!-- CI trigger for PR -->