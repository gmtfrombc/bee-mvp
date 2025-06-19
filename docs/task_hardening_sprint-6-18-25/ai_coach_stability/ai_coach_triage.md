# AI Coach – H-AI Stability & Feature Triage

**Sprint:** Stability & Observability Hardening (Pre-Epic 1.4)

**Scope lock date:** {{DATE}}

---

## 1. Components in Scope

1. **Quick Suggestions chips** – two fixed prompts: "Today" and "Tomorrow".
2. **Conversation thread UI** – chat bubbles, initial system greeting.
3. **Side Drawer** – list of past conversations with ability to start new or
   delete.
4. **User Feedback Capture** – numeric self-rating (1-10) + optional free-text
   after "Today" reply.
5. **Prompt Logic** – backend prompt assembly using 7-day momentum average,
   latest steps & sleep + future extra metrics (TBD).
6. **Future Voice Chat** – out of scope this sprint, logged for roadmap.

---

## 2. Observed Defects & Gaps

| ID    | Component                 | Symptom / Gap                                                 | Notes                                     |
| ----- | ------------------------- | ------------------------------------------------------------- | ----------------------------------------- |
| AC-01 | Quick Suggestions         | Still labelled "Daily habits" & "Motivation" placeholders.    | Needs rename + new icons.                 |
| AC-02 | Prompt content (Today)    | Does not use momentum/steps/sleep data; static greeting only. | Requires dynamic prompt.                  |
| AC-03 | Prompt content (Tomorrow) | Not implemented.                                              | Needs template with 3 actionable options. |
| AC-04 | User feedback             | No mechanism to capture self-rating or free-text.             | Add modal or inline widget post-response. |
| AC-05 | Conversation history      | No side drawer; cannot revisit or delete chats.               | Mimic ChatGPT mobile.                     |
| AC-06 | New chat                  | No visible "New Chat" button.                                 | Add icon at top of drawer.                |
| AC-07 | System greeting           | Generic copy; needs rewrite.                                  | To-Do.                                    |

---

## 3. Current Implementation Facts / Unknowns

| Area                 | Known                                                                 | Unknown / To-Do                                                |
| -------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------- |
| **Chat backend**     | Supabase Edge Function `ai-coaching-engine` proxied to OpenAI/Claude. | Prompt assembly details; context token limit.                  |
| **Data inputs**      | Momentum score exists in DB.                                          | Exact columns for steps/sleep; need join for last 24 h values. |
| **Feedback storage** | None yet.                                                             | Create `coach_feedback` table (user_id, ts, rating INT, text). |
| **Drawer UI**        | Not built.                                                            | Design & routing pattern; list item schema (date + title).     |
| **Voice chat**       | Planned.                                                              | TTS/STT stack choice.                                          |

---

## 4. Recommended Fixes & Owners (feeds H2-AI tasks)

| #    | Area                | Fix                                                                                             | Est. hrs | Owner            |
| ---- | ------------------- | ----------------------------------------------------------------------------------------------- | -------- | ---------------- |
| F-20 | Suggestion chips    | Rename to "Today" & "Tomorrow"; update icons.                                                   | 1        | Mobile           |
| F-21 | Prompt logic        | Build `today_prompt()` assembling 7-day momentum avg, steps, sleep; TBD extra metrics.          | 4        | Backend          |
| F-22 | Prompt logic        | Build `tomorrow_prompt()` emitting 3 actionable bullet points based on same data.               | 4        | Backend          |
| F-23 | Feedback capture    | After coach reply, show dialog with 1-10 slider + optional text box; store in `coach_feedback`. | 5        | Mobile + Backend |
| F-24 | Conversation drawer | Sliding drawer with list (date, title), delete swipe, "+" new chat icon top-right.              | 6        | Mobile           |
| F-25 | System greeting     | Rewrite copy (To-Do) and update default first message.                                          | 1        | Product          |
| F-26 | Feature flag        | Gate new drawer & prompts behind `ai_coach_v2_beta`.                                            | 1        | Mobile           |
| F-27 | Analytics           | Log `ai_chat_started`, `ai_feedback_submitted` events.                                          | 1        | Mobile           |

---

## 5. Open Questions

1. What additional metrics (e.g., provider visits, goals) should feed prompts
   for MVP?
2. Momentum thresholds for "defensive" vs "offensive" tone – define later?
3. Maximum token length for responses?
4. Preferred icons for "Today" and "Tomorrow" chips?

---

## 6. Acceptance Criteria

- Quick suggestion chips show "Today" and "Tomorrow" only.
- Selecting "Today" returns dynamic summary including momentum/steps/sleep.
- App prompts user with 1-10 rating + optional comment; data saved.
- Selecting "Tomorrow" returns 3 actionable suggestions for next 24 h.
- Side drawer lists prior chats (date + title); user can delete; "+" starts
  empty conversation.
- Old greeting replaced with updated copy.
- New features behind `ai_coach_v2_beta` flag default off.
- Analytics events captured.

---

_Prepared by:_ Mobile, Backend & Product
