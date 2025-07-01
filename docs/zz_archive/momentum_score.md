
🔎 Current Momentum Score Design

✅ What’s smart and sound
	•	Event weighting captures intuitive user actions (e.g., coach interactions > lesson start).
	•	Exponential decay + hysteresis adds behavioral nuance—modeling momentum as fragile, nonlinear, and stateful.
	•	Daily normalization and deduplication is wise to prevent spam-like inflation.

❗️But here’s the issue:

Only a minority of event types are actionable predictors. And right now, many are speculative placeholders rather than validated contributors to engagement or outcomes.

⸻

📊 Event Type Utility – Behavioral Relevance Scorecard

Event Type	Behavioral Signal Value	Comments
coach_interaction	🔥🔥🔥 High	Strong predictor; should be mirrored into momentum immediately.
goal_completion	🔥🔥 High	Reflects actual behavioral change; essential.
journal_entry	🔥 Medium-High	Suggests self-reflection and internal motivation.
assessment_completion	🔥 Medium-High	Demonstrates follow-through and self-awareness.
lesson_completion	🔥 Medium	Predictive if completion isn’t passive; needs UX that requires engagement.
goal_setting	🔥 Medium	Less predictive than completion; might inflate score.
peer_interaction	🔥 Medium	Adds accountability and social proof but depends on good community features.
reminder_response	🟡 Low-Medium	Shows attentiveness, but could be noise if responses are unthinking.
app_session	🟡 Low	Useful as a denominator or absence signal; weak on its own.
streak_milestone	🟡 Low	Motivational, but lagging indicator—adds little prediction.
lesson_start	🟡 Low	Very weak signal; could clutter the score.
resource_access	🟡🚫 Very Low	Probably noise unless deep-link or dwell-time is tracked.


⸻

💡 Additional Metrics with High Predictive Power

You’re absolutely right: momentum shouldn’t ignore passive but powerful behavioral signals. These can actually outperform tap-based metrics.

Signal Type	Predictive Value	Integration Challenge
Sleep trends (duration/consistency)	🔥🔥🔥 High	Moderate – from HealthKit / Garmin
Steps / Activity volume	🔥🔥 High	Moderate – already partially wired
Coach or Provider Visit Adherence	🔥🔥🔥 High	Easy to log via appointment system
Goal Progress (numeric or % complete)	🔥🔥 High	Requires structured goal data
Timeliness of action step completion	🔥🔥 High	Requires timestamped tracking
Check-in streaks (manual or biometric)	🔥 Medium	Needs clear user definition
Behavioral biometrics (HRV, RHR)	🔥 Medium	Long-term potential; early-stage now


⸻

🧠 Recommendation: Rethink the Score’s Foundation

Rather than discard the Momentum Score, I suggest we restructure it around two guiding principles:

⸻

✳️ 1. Multi-Channel Signal Fusion

Break the score into pillars and weight each type of data according to signal quality:

Sample Pillars:
	•	Cognitive Engagement → lesson completion, journaling, assessments
	•	Behavioral Execution → goal/action completion, activity metrics
	•	Relational Engagement → coach/provider sessions, peer engagement
	•	Biometric Consistency → steps, sleep, HRV

Then compute a blended score that balances these (e.g., 30/30/20/20).

⸻

✳️ 2. Purposeful Use Before Complex Math

Ask: What should this score do?
If it’s just for user feedback → simplicity + story.
If it’s for predictive analytics → need A/B testing & retroactive analysis.

Maybe we have:
	•	A Momentum Meter (UX-visible, simple, motivational)
	•	A separate Engagement Risk Index (backend, predictive modeling, ML-trained)

⸻

🧭 Your Next Steps (Strategically)
	1.	Prioritize integration of high-signal events:
	•	Start with coach interactions, goal completions, biometric syncing.
	•	Ignore or delay low-value events (like lesson_start or resource access).
	2.	Redesign the Momentum Score schema:
	•	Consider a “pillar” approach.
	•	Limit noise by gating inclusion of each data type based on relevance.
	3.	Plan for future validation:
	•	Create hooks now to record raw data (biometrics, visit completion, etc.).
	•	Later, validate correlation with outcomes (retention, goal attainment, biometric improvement).

⸻

✅ Final Thoughts

The current version of the Momentum Score is a good MVP scaffolding, but not sufficient for long-term behavioral insight or predictive power. It should evolve into a hybrid signal with both human relevance and analytic rigor—simple enough for users to understand, smart enough to guide interventions.