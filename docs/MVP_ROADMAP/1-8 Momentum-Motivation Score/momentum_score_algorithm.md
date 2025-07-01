## Momentum Score audit (current state – June 2025)
───────────────────────────────────────────────
## 1. Where, when, and how the score is produced

• Edge Function `/functions/v1/momentum-score-calculator`
  – 24 KB TypeScript file, writes into table `public.daily_engagement_scores`.
• A listener (`momentum-score-listener`) fires whenever `momentum_state` changes and notifies the AI-Coach / push-notification engine.
• All other services that need “engagement” data read that same table; no second metric called *Engagement Score* exists yet.  
  ➜ In code and database they are synonymous.

## 2. Algorithm details (v 1 · documented in docs/…/momentum-score-calculator.md)

a. Raw daily score  
   – Each engagement event gets a fixed weight (e.g. coach_interaction 20 pts, app_session 3 pts).  
   – Anti-gaming: max 5 events/type/day, hard cap 100 pts.
b. Historical smoothing  
   – Fetches last 30 days of `final_score`.  
   – Exponential decay with half-life 10 days → produces `decayAdjustedScore`.  
   – Blended score = 0.7 × raw + 0.3 × decayAdjustedScore.
c. State classification + hysteresis (2-point buffer)  
   Rising ≥ 70 Steady 45-69 Needs Care < 45.
d. Fields persisted  
   `raw_score`, `normalized_score` (actually the blended score), `final_score` (identical to normalized), `momentum_state`, JSON   `breakdown`, `algorithm_version`.

## 3. Places that assume “Momentum = Engagement”

• Push-notification triggers query `daily_engagement_scores` for “momentum change” logic.  
• AI-Coaching listener reads the same table to send a system event.  
• Docs and UI wire-frames use the friendly term *Momentum* for the patient, but all SQL/TS code lives under *engagement*.

#  4. Gaps & risks

• Naming confusion: developers may search for “engagement score” and overlook the calculator.  
• `normalized_score` duplicates `final_score`; could lead to bugs if one field is changed later.  
• Data coverage: new signals you mentioned (PHQ-9, GAD-7, provider transcripts, action-step completion, missed visits) are **not** yet part of `EVENT_WEIGHTS`; they’ll score 0.  
• Weights & thresholds were hand-tuned; no A/B or ML feedback loop yet.  
• `MAX_EVENTS_PER_TYPE = 5` might under-value very engaged chat users (e.g. >5 coach messages).  
• Score is recomputed on demand; if a day has *zero* events the entry may be missing, which breaks 30-day trend math.

## 5. Recommendations (short-term)

a. Terminology: rename table to `daily_momentum_scores` (or create a view alias) so tech and product wording match.  
b. Field cleanup: keep **one** numeric—`final_score`—plus the state; drop `normalized_score` or make it a view.  
c. Expand `EVENT_WEIGHTS` to include upcoming signals (action-step completion, readiness score, PHQ-9 delta, missed visits).  
d. Emit an explicit daily row even when no events occur; set `raw_score = 0` so decay still happens smoothly.  
e. Unit tests: add fixtures for “>5 messages”, “no events”, and newly added event types.

## 6. Recommendations (mid-term, when Engagement Score diverges)

Option A – keep a **single numeric** that everyone calls Momentum/Engagement; change only the *composition* (weights, ML model) behind the scenes.  
Option B – derive a new *Predictive Disengagement Risk* score (0-1 probability) via LightGBM/NN.  
 • Store it in `predicted_disengagement_risk` alongside the daily momentum row.  
 • AI Coach reads both: momentum for tone, risk score for escalation suggestions.  
 • Maintain backward-compat by defaulting risk = 1-(final_score/100) until the model is trained.

## 7. Long-term architecture

• Feature store: move raw events into a time-series table; nightly job materialises both “momentum” and “risk” scores.  
• Online pipeline: add Kafka or Supabase Realtime to update scores within seconds for just-in-time nudges.  
• Model governance: log feature versions and thresholds so UI/Coach explanations match the actual math.

## Bottom line

— Momentum Score today *is* the Engagement Score.  
— Algorithm is deterministic, reasonable for MVP, but must incorporate new signals and clearer naming before layer ML-based disengagement prediction on top.