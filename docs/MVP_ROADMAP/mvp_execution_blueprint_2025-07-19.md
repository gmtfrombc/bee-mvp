# BEE MVP – Execution Blueprint (v2 · 2025-07-19)

> **Source of truth** for the remaining path to MVP. This replaces previous
> high-level sequences. Keep this file updated if scope or ordering changes.

---

## Legend

| Symbol | Meaning                        |
| ------ | ------------------------------ |
| 🏗      | Feature / Epic development     |
| 🧹     | House-keeping / tech-debt      |
| 🔬     | Automated tests & CI work      |
| 👤     | Manual, on-device walk-through |
| 📱     | External beta testing round    |

---

## Phase Overview

| Phase | Scope Highlights                                      | Duration | Milestone           | Manual Test      |
| ----- | ----------------------------------------------------- | -------- | ------------------- | ---------------- |
| **0** | Stability & Hygiene (tests, TODOs, size gate)         | 1 wk     | CI green @ 45 % cov | 👤 Founder WT #0 |
| **1** | Momentum + Motivation Score Engine (Epic 1.8)         | 1 wk     | Gauge updates       | 👤 WT #1         |
| **2** | Today Feed 2.0 (Epic 1.2 enh)                         | 1 wk     | Adaptive tiles live | 👤 WT #2         |
| **3** | Adaptive AI Coach v2 + Conversation (Epics 1.3, 1.10) | 2 wk     | Chat flows          | 👤 WT #3         |
| **4** | In-App Messaging + First External Beta (Epic 1.4)     | 1 wk     | Secure chat         | 📱 Beta #1       |
| **5** | Analytics Engine & Dashboards (Epics 3.2.1, 4.1, 5.2) | 2 wk     | KPI dashboards      | 👤 WT #4         |
| **6** | Final Polish & Release Candidate                      | 1 wk     | MVP RC              | 📱 Beta #2       |

_Total estimated timeline: **8 weeks (solo-dev)**._

---

## Detailed Task Breakdown

### Phase 0 – Stability & Hygiene (Week 0)

1. 🧹 **Un-skip** 12 Flutter tests; ensure CI green.
2. 🧹 Triage all TODOs → implement or ticket; archive low-value notes.
3. 🧹 **Component Size Governance – Pass 1**: refactor files > 300 LOC.
4. 🧹 Remove committed `app/coverage/lcov.info`; update `.gitignore`.
5. 🔬 Raise test-coverage gate → **45 %**.
6. 👤 **Founder Walk-Through #0**: Onboarding → Action Step → Health Signals
   sanity check.

### Phase 1 – Momentum + Motivation Score Engine (Week 1)

7. 🏗 **Epic 1.8**: Final Momentum % + Motivation tier calculation.
8. 🔬 Back-test algorithm against fixtures; coverage ≥ 48 %.
9. 🧹 Spike Deno std upgrade in edge-function repo (flag-protected).
10. 👤 **Walk-Through #1**: Verify gauge & label update after mock events.

### Phase 2 – Today Feed 2.0 (Week 2)

11. 🏗 **Epic 1.2** enhancements: energy-aware scheduler & tiles.
12. 🧹 Component Size Governance – Pass 2 (Feed files).
13. 🔬 Feature-flag A/B test infra for tile variants.
14. 👤 **Walk-Through #2**: Inspect new Feed cards on device.

### Phase 3 – Adaptive AI Coach v2 + Conversation Engine (Weeks 3-4)

15. 🏗 **Epics 1.3 & 1.10**: JITAI triggers, coach-memory hooks, full chat.
16. 🧹 Eliminate skipped chat widget tests; CI remains green.
17. 👤 **Walk-Through #3**: Chat → observe Momentum modifiers.

### Phase 4 – In-App Messaging & External Beta #1 (Week 5)

18. 🏗 **Epic 1.4**: Secure Supabase Realtime messaging.
19. 🧹 Local Supabase mini-stack V2 (Realtime, Storage) + CI toggle.
20. 🔬 WCAG/keyboard audit of chat UI.
21. 📱 **External Beta #1**: 10 tester cohort via TestFlight; survey feedback.

### Phase 5 – Analytics & Dashboards (Weeks 6-7)

22. 🏗 **Epics 3.2.1, 4.1, 5.2**: Deploy LightGBM; build Coach & Admin
    dashboards.
23. 🔬 Golden tests for charts; overall coverage ≥ 55 %.
24. 👤 **Walk-Through #4**: Dashboards load & update correctly.

### Phase 6 – Final Polish & Release Candidate (Week 8)

25. 🧹 Component Size Governance – Pass 3 + automatic CI gate.
26. 🧹 Close high-priority TODOs; zero P0 bugs.
27. 🔬 Tests green, coverage ≥ 60 %, 0 skips, WCAG AA.
28. 📱 **External Beta #2**: Full regression script; sign-off for MVP.

---

## Testing Protocols

- **Automated**: Unit, widget, integration run on every PR (`make ci-fast`).
- **Founder Walk-Throughs**: End of each phase < 15 min device checklist.
- **External Betas**: Structured feedback form (UX, stability, value).

---

## Change Management

1. All scope changes must update this file and receive 👍 in PR review.
2. Any phase slippage > 2 days triggers a re-projection section at file top.

---

_Last updated: 2025-07-19 by AI pair-programmer_
