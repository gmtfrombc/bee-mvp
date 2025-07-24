# Mini-Sprint Spec – "Current Action Step" Feature

> Version 0.1 · **Draft**  – _Last updated: <!-- yyyy-mm-dd auto-filled by commit hook -->_

## 1 Overview
This mini-sprint adds **visibility & management** for a user’s current Weekly Action Step after onboarding.  
Today the app only supports _creating_ an Action Step; users cannot see, edit, or delete it afterwards.  
The sprint enables Scenarios 2 & 3 in the QA walkthrough (edit / delete).

## 2 Goal
Enable users to **view, update, or delete** their current Action Step directly from the Momentum screen.

## 3 Scope & Deliverables
* New page **My Action Step** (`/action-step/current`)
  * Shows category icon, description, target frequency, and week-to-date progress (e.g. 3 / 7).
  * “Edit” button opens the existing `ActionStepForm` pre-filled.
  * “Delete” button removes the step (with confirmation) and resets the `hasSetActionStep` flag.
* Momentum screen
  * If no step set → current behaviour (navigate to Setup page).
  * If step exists → navigate to **My Action Step** page.
  * Display live progress value instead of “--”.
* Persistence logic
  * Query latest row in `action_steps` + day-by-day completion counts.
  * Update row (`UPDATE`) on edit; `DELETE` on delete.
* Analytics hooks for **view**, **edit**, and **delete** events.
* Unit & widget tests (≥ 90 % coverage for new code).
* Updated docs & QA walkthrough.

## 4 Task Breakdown
| ID | Task | Owner | Status |
|----|------|-------|--------|
| T1 | Create `ActionStepRepository` for DB queries | dev | completed |
| T2 | Build **My Action Step** page UI             | dev | completed |
| T3 | Wire navigation logic in Momentum screen     | dev | pending |
| T4 | Implement edit flow (reuse `ActionStepForm`) | dev | pending |
| T5 | Implement delete flow + confirmation dialog  | dev | pending |
| T6 | Calculate & render progress in Momentum card | dev | pending |
| T7 | Add analytics events (view/edit/delete)      | dev | pending |
| T8 | Write unit tests for repository & analytics  | dev | pending |
| T9 | Widget tests for navigation & UI states      | dev | pending |
| T10| Update docs & QA script                      | dev | pending |

## 5 Acceptance Criteria
1. Tapping **Action Step** card on Momentum screen:
   * Navigates to Setup page when _no step exists_.
   * Navigates to **My Action Step** page when _step exists_.
2. **My Action Step** page displays:
   * Current step’s category icon & description.
   * Target frequency (X days / week).
   * Week-to-date progress (completed / target).
3. Edit flow saves changes and updates UI immediately.
4. Delete flow removes the step, resets flag, and redirects to Setup page.
5. Momentum card progress updates reactively (state ≤ 1 s behind DB).
6. All new & existing tests pass (`flutter test`).
7. Code meets project lint rules (`flutter analyze --fatal-warnings`).

## 6 Out-of-Scope
* Multiple concurrent Action Steps.
* Historical history or charts.
* Backend cron jobs for automatic archival.

## 7 Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Supabase latency causing stale progress | Medium | Cache in provider & optimistically update on complete/skip |
| Edit turning frequency lower than completed days | Low | Validate and warn user |

## 8 Timeline
Target completion: **3–4 dev days** (including code review & QA).

---
_End of document_ 