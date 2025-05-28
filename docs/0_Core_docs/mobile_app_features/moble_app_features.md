Mobile App Features

## Momentum Meter (Motivation Gauge)

### Purpose  
Provide a friendly, real‑time indicator of each user’s engagement level, enabling timely AI‑driven nudges and coach interventions while avoiding demotivating “scores.”

### User Experience  
* **Patient view:** simple circular gauge with three states—Rising 🚀, Steady 🙂, Needs Care 🌱—updated once daily.  
* **Clinician view:** 0‑100 line graph plus intervention log on the provider dashboard.  
* Users choose an initial messaging style (“Daily Check‑in”, “Quick Nudge”, or “Silent unless Needed”); the AI adapts over time based on open/response rates.
* Use behavioral concept of 'variable reward' in outreach given the research-based positive effects.

### Data Inputs (MVP)  
| Source | Events | Notes |  
|--------|--------|-------|  
| App actions | habit check‑ins, lesson completions, journal entries | Effort‑weighted +1 each |  
| Wearables | steps, active minutes, sleep hours | Normalized to per‑user baseline |  
| Scheduling | tele‑visit attendance | +3 for attended, −2 for no‑show |  

_Additional sources (CGM glucose stability, med refills) queued for v2._

### Scoring Logic (batch job, nightly)  
```python
# pseudocode
score = sigmoid(Σ weight_i * feature_i_decay) * 100
zone = (
    "Rising" if score >= 70 else
    "Steady" if score >= 45 else
    "NeedsCare"
)
```
* Exponential decay half‑life: 10 days  
* Three‑day rolling average to smooth noise

### Notification & Intervention Rules  
* Drop ≥15 pts in 5 days → send supportive push + action tip  
* Two consecutive “Needs Care” days → auto‑schedule 5‑min coach call (human can cancel)  
* Five “Steady” or “Rising” days → optional celebratory message  

### Technical Architecture  
* **Backend:** nightly Cloud Run job reads `engagement_events` table, writes `daily_engagement_scores`.  
* **Database schema additions:**  

  ```sql
  CREATE TABLE engagement_events (
      id SERIAL PRIMARY KEY,
      user_id UUID,
      event_type TEXT,
      value NUMERIC,
      recorded_at TIMESTAMP
  );

  CREATE TABLE daily_engagement_scores (
      user_id UUID,
      score_date DATE,
      raw_score NUMERIC,
      zone TEXT
  );
  ```

* **API:** `GET /v1/engagement/score` returns latest zone + tip.  
* **Flutter widget:** custom painter for gauge; provider pattern subscribes to score endpoint; updates via Riverpod.

### Acceptance Criteria  
- [ ] Gauge renders correct zone for mocked scores.  
- [ ] Backend job completes < 2 min for 10 k users.  
- [ ] Push notification fires on score drop in staging tests.  
- [ ] Data visible in clinician dashboard.


### Future Enhancements  
* Personalised thresholds via Bayesian bandits  
* A/B testing alternate copy & color schemes  
* Streaming update pipeline to replace nightly batch

## Adaptive AI Coach

### Purpose  
Deliver personalized Accountability, Motivation, and Troubleshooting (“ACT”) through an LLM‑powered coach that learns each user’s preferred style and adjusts cadence, tone, and content to sustain long‑term engagement.

### User Experience  
* **Initial setup:** user completes intake survey and selects a coach mode slider — Quiet ▸ Balanced ▸ Hands‑on.  
* **Dialog format:** in‑app chat bubbles (text), optional voice playback via TTS.  
* **Cadence:** default daily touch for Balanced; Quiet only on meaningful events; Hands‑on up to 2×/day.  
* **Feedback loop:** every two weeks the coach asks, “Are these check‑ins helpful?” (👍/👎). Response adjusts future cadence.  
* **Escalation rules:**  
  * Detect ≥3 converging low‑momentum signals within 7 days → proactive outreach.  
  * Two unanswered messages → progressively shorter prompts; after 4 → switch to Quiet mode until re‑engagement.  
  * “Needs Care” zone ≥5 days → auto‑schedule human coach call (cancel‑able).  
* **Human handoff:** any discussion of med side‑effects, severe mood, or specific dosing triggers a handoff banner: “I’ve flagged this for your clinician.”

### Data Inputs  
| Source | Use | Notes |  
|--------|-----|-------|  
| Intake survey | personality seed (e.g., prefers humor, dislikes emojis), coach mode default | stored in `user_profile` |  
| Momentum Meter zone history | detect trends, escalation triggers | pull via internal gRPC |  
| Message analytics | open rate, response latency | updates `engagement_signal` table |  

### Dialogue & Adaptation Logic  
```python
# pseudocode
class CoachPolicy:
    def decide_next_action(context):
        if context.force_handoff:
            return HandoffCard()
        if context.low_momentum_streak >= 5:
            return ScheduleHumanCall()
        cadence = user_settings.cadence  # Quiet / Balanced / Hands-on
        if context.unanswered >= 4:
            cadence = 'Quiet'
        return LLMResponsePrompt(cadence, persona=user_settings.persona)
```
* **Minimum dwell time:** coach waits ≥7 days before switching persona/cadence to avoid erratic shifts.  
* Online contextual bandit updates reward = 1 if user reads/responds within 4 h, else 0.

### Technical Architecture  
* **Orchestrator service (Python/FastAPI):** receives `conversation_event` webhook, builds prompt, calls OpenAI function‑calling model.  
* **State storage:**  
  * `coach_state` table — current persona, cadence, last_checkin_time.  
  * `conversation_history` table — message JSON, timestamps, engagement flag.  
* **Edge delivery:** Firebase Cloud Messaging → Flutter chat widget; voice playback via Flutter TTS plugin.  
* **Safety layer:** moderation endpoint scans outgoing text; red‑flags route to human review queue.

### Acceptance Criteria  
- [ ] Coach obeys selected mode in staging tests.  
- [ ] 👍/👎 feedback adjusts cadence within one session.  
- [ ] Unanswered‑messages rule switches to Quiet mode.  
- [ ] Handoff banner appears on trigger phrases in test set.  

### Future Enhancements  
* Persona library expansion (humorous, drill‑sergeant, serene).  
* RLHF fine‑tuning with program‑specific transcripts.  
* Multimodal summaries (short video or GIF encouragement).

## Habit Architect (Mini‑Loop Builder + Micro‑Challenges)

### Purpose  
Enable users to create low‑friction, process‑focused habits (nutrition, activity, sleep, stress) and strengthen them through self‑logging, variable reward, and adaptive micro‑challenges—building long‑term routines with minimal cognitive load.

### User Experience  
1. **Select pillar → action** (one tap each).  
   *Examples:*  
   • Nutrition → “Pack tomorrow’s lunch”  
   • Activity → “10‑min post‑dinner walk”  
2. **One‑tap commit** adds a tile to Today feed; no cue entry required.  
3. **Self‑log button** appears daily—user taps when done; no push reminder unless safety net triggers.  
4. **Variable reward** fires instantly (confetti, XP drip, rare big badge). Probability of higher reward scales with quick logging.  
5. **Weekly micro‑challenge** (optional) auto‑suggests a small upgrade aligned with the loop (e.g., “Add one veggie to lunch”). User can accept or skip.  
6. **Safety net toggle**: “Remind me if I forget 3×” (default off). If enabled and user misses three days, app shows a discreet reminder badge.

### Data Model  
```sql
CREATE TABLE habits (
    id UUID PRIMARY KEY,
    user_id UUID,
    pillar TEXT,          -- nutrition / activity / sleep / stress
    action TEXT,
    start_date DATE,
    active BOOLEAN DEFAULT TRUE,
    remind_after_misses INTEGER DEFAULT 0  -- 0 = no safety net
);

CREATE TABLE habit_logs (
    id SERIAL PRIMARY KEY,
    habit_id UUID,
    log_date DATE,
    logged_at TIMESTAMP,
    reward_tier SMALLINT  -- 0:none, 1:standard, 2:bonus
);
```

### Logic & Reward Algorithm (nightly task)  
```python
def assign_reward(log_delay_minutes):
    if log_delay_minutes <= 10:
        return 2  # bonus
    elif log_delay_minutes <= 120:
        return 1
    return 0
```
*Three consecutive `log_date` gaps → if `remind_after_misses` > 0, schedule reminder.*

### Technical Architecture  
* **Flutter UI:** HabitBuilder screen → Today feed tile with “Done” button; Riverpod watches `habit_logs`.  
* **Backend:** Cloud Function `POST /v1/habits/log` writes log, returns reward tier.  
* **Scheduler:** daily cron checks for missed logs, queues Firebase Cloud Messaging if safety net conditions met.  
* **Micro‑challenge engine:** weekly cron `suggest_micro_challenge()` creates challenge record and pushes card.

### Acceptance Criteria  
- [ ] Habit can be created and logged in <5 seconds of UX time.  
- [ ] Variable reward tier matches spec in staging tests.  
- [ ] Safety‑net reminder fires only after 3 consecutive misses.  
- [ ] Micro‑challenge suggestions appear on Monday and respect user skip.

### Future Enhancements  
* Cue inference from sensor/time data to refine reminders.  
* Difficulty adaptation: increase action complexity after 14‑day success streak.  
* Social “friend‑streak” option for shared habits.

## Active‑Minutes Insights (Wearable‑Powered Wins)

### Purpose  
Transform raw wearable data (steps, active minutes, CGM trends) into upbeat, bite‑sized “wins” that reinforce movement and boost the Momentum Meter.

### User Experience  
* Daily at 07:00 local, app syncs yesterday’s data.  
* If active minutes ≥ 10 above 14‑day baseline → create “Nice move yesterday!” tile with delta, friendly calorie equivalent, and optional “Set today’s target” CTA.  
* Tap logs acknowledgement → Momentum +2.  
* Three wins/week trigger micro‑challenge suggestion; five no‑win days trigger gentle prompt.  
* No negative messaging—if data is flat, tile simply doesn’t appear.

### Data Inputs & Model  
| Source | Metric | Notes |  
|--------|--------|-------|  
| HealthKit / Google Fit | active_minutes, steps | OAuth pull via background fetch |  
| Fitbit / Garmin APIs | same | token stored in `wearable_tokens` |  
| CGM (v2) | time‑in‑range % | future enhancement |  

```sql
CREATE TABLE daily_activity (
    user_id UUID,
    activity_date DATE,
    active_minutes INTEGER,
    baseline_minutes INTEGER,
    delta_minutes INTEGER
);
```

* Baseline = rolling 14‑day mean; stored nightly.  
* Win threshold default = +10 min (configurable).

### Technical Architecture  
* **Backend job** gathers data via vendor SDKs → writes `daily_activity`.  
* **Insight engine** selects rows with `delta_minutes >= threshold`, publishes FCM message with payload for tile.  
* Flutter Today feed renders tile component.

### Acceptance Criteria  
- [ ] Win tile shows when delta ≥ threshold.  
- [ ] Momentum boost applied on tap.  
- [ ] No tile on below‑baseline days.  

---

## On‑Demand Lesson Library

### Purpose  
Provide easy access to structured educational content (FAQ, lesson PDFs, NotebookLM podcast) hosted on WordPress.

### User Experience  
* “Learn” tab lists lessons as cards with image, title, completion badge.  
* Tapping opens in‑app WebView (WordPress page) or cached PDF.  
* Search and filter by tag (nutrition, activity, mindset).

### Integration & Data Flow  
* WordPress REST API `wp-json/wp/v2/posts?categories=lessons` returns JSON.  
* Flutter fetches list at app launch, caches in SQLite `lessons` table.  
* Mark lesson complete when ≥ 90 % of content scrolled or podcast listened.

### Acceptance Criteria  
- [ ] Lesson list loads offline using cache.  
- [ ] Completion badge toggles on view.  

---

## Today Feed (AI Daily Brief)

### Purpose  
Deliver a single, engaging health topic each day, generated by the GCP backend, to spark curiosity and conversation.

### User Experience  
* Feed tile with title, 2‑sentence summary, “Read more” link.  
* Same content for all users in v1; v2 will personalize via interests/goals.

### Technical Notes  
* Existing Cloud Run endpoint `/today` returns JSON `{title, summary, link}`.  
* App pulls once per 24 h, caches in SharedPreferences.  
* Momentum +1 on first open per day.

### Acceptance Criteria  
- [ ] Tile refreshes at local midnight.  
- [ ] Fallback shows yesterday’s tile if offline.  

---

## Unified Data Dashboard (Care‑Team Web)

### Purpose  
Give clinicians a consolidated view of engagement trends, Momentum zones, labs, vitals, and tele‑visit adherence to guide outreach.

### Features  
* Patient list with risk flags (low Momentum streaks, lab outliers).  
* Drill‑down charts for engagement score, habit adherence, active minutes.  
* Secure messaging shortcut and quick‑note logging.

### Tech Stack  
* **Frontend:** React + Ant Design, hosted on GCP Cloud Run.  
* **Backend:** Supabase Postgres read‑replica of production DB (HIPAA‑compliant).  
* JWT auth via Auth0; role‑based access.  

### Acceptance Criteria  
- [ ] Dashboard loads < 2 s with 1 k patients.  
- [ ] Risk filter correctly surfaces ≥ 5‑day Needs Care streaks.  
- [ ] Audit log records every clinician view.

---