# Rewards Screen – H1.3 Inventory & Triage

**Sprint:** Stability & Observability Hardening (Pre-Epic 1.4)

**Scope lock date:** {{DATE}}

---

## 1. Screens & Widgets in Scope

| Screen     | Widget / Section                                                            | Current Status                                                     |
| ---------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Badges     | Your Achievements header                                                    | Live                                                               |
| Badges     | Active Challenges (Daily Check-In)                                          | Live (progress increments)                                         |
| Badges     | Momentum Burst card                                                         | Partially live – "Accept Challenge" snackbar only, no points logic |
| Badges     | Knowledge Seeker card                                                       | Placeholder – snackbar only; unclear if we keep                    |
| Badges     | Badge tiles (Week Warrior, Momentum Master, Chat Champion, Getting Started) | Visible; unlock rules TBD                                          |
| Challenges | Whole screen                                                                | "Coming Soon" placeholder                                          |

---

## 2. Observed Defects & Gaps

| ID    | Component                | Symptom                                                                             | Notes                                  |
| ----- | ------------------------ | ----------------------------------------------------------------------------------- | -------------------------------------- |
| RW-01 | Daily Check-In challenge | Works but points hard-coded; progress does not persist after app restart.           | Needs Supabase row + Riverpod cache.   |
| RW-02 | Momentum Burst           | Accept/Decline buttons show snackbar; no underlying challenge definition or reward. | Also layout bug: "Decline" text wraps. |
| RW-03 | Knowledge Seeker         | Placeholder copy & logic; may drop or replace.                                      | Mark as **To-Do**.                     |
| RW-04 | Badge unlocks            | Week Warrior et al appear unlocked regardless of criteria.                          | Criteria undefined.                    |
| RW-05 | Feature flags            | Unknown RemoteConfig keys; cannot hide placeholder widgets.                         | Need inventory + new flags.            |
| RW-06 | Copy / UX                | Generic labels ("Decline", "Challenge") not engaging; no variable-reward mechanics. | UX rewrite needed.                     |
| RW-07 | Challenges tab           | Entire screen shows "Coming Soon"; should be hidden until ready.                    | Flag or remove.                        |

---

## 3. Current Implementation Facts / Unknowns

| Area                 | Known                                           | Unknown / To-Do                                                 |
| -------------------- | ----------------------------------------------- | --------------------------------------------------------------- |
| **Daily Check-In**   | Button tap increments progress bar client-side. | Where points stored, reset cadence, Supabase table?             |
| **Momentum Burst**   | Accept snackbar only.                           | Challenge definition, completion event, reward multiplier idea. |
| **Knowledge Seeker** | Placeholder.                                    | Decide keep / drop; if keep, trigger = read 5 Today articles.   |
| **Badge tiles**      | Tiles visible.                                  | Unlock event mapping & icons; variable reward tiers.            |
| **Feature flags**    | Possibly `show_rewards`.                        | Confirm keys; add `rewards_v2_beta`, `show_challenges_tab`.     |

---

## 4. Recommended Fixes & Owners (feeds H2-C tasks)

| #    | Area             | Fix                                                                                                                                | Est. hrs | Owner            |
| ---- | ---------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| F-10 | Feature flags    | Implement `rewards_v2_beta` to gate placeholder widgets.                                                                           | 2        | Mobile           |
| F-11 | Challenges tab   | Hide or redirect to Badges until implemented.                                                                                      | 1        | Mobile           |
| F-12 | Daily Check-In   | Store progress in Supabase `user_badges` table; persist across sessions.                                                           | 4        | Backend + Mobile |
| F-13 | Momentum Burst   | Define challenge schema (duration, reward multiplier); implement accept/decline flow; fix layout copy ("Skip" instead of Decline). | 6        | Mobile + Product |
| F-14 | Badge criteria   | Define unlock rules for Week Warrior, Momentum Master, etc.                                                                        | 3        | Product          |
| F-15 | Variable rewards | Design variable reward algorithm (e.g., random bonus points) and integrate.                                                        | 5        | Backend          |
| F-16 | Knowledge Seeker | Decide keep/drop. If keep, wire to "read N Today articles" analytic.                                                               | 2        | Product + Mobile |

---

## 5. Open Questions

1. How many badge tiers do we need for MVP vs later?
2. Preferred naming/copy for declining a challenge (e.g., "Maybe Later" vs
   "Skip").
3. Should variable reward multipliers apply only to Momentum Burst or all
   challenges?
4. Any GDPR concerns with deeper analytics needed for challenge triggers?

---

## 6. Acceptance Criteria

- Placeholder widgets hidden behind `rewards_v2_beta` off by default.
- Daily Check-In progress persists after app relaunch & across devices.
- Momentum Burst shows challenge details; accepting gives bonus points; "Skip"
  button properly aligned.
- Knowledge Seeker either removed or fully functional with unlock after 5 Today
  articles.
- Challenges tab not visible in production build.
- Badge unlock events logged with `badge_unlocked` analytics event.

---

_Prepared by:_ Mobile & Product
