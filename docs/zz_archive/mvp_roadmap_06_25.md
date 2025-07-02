Absolutely—detailing the specific Epics required for MVP is the final critical piece of alignment.

Below is a structured breakdown of the Epics that must be completed for MVP across all modules, along with a short summary of their function and rationale.

⸻

✅ Required Epics for MVP Completion

🧱 MODULE 1: Core Mobile Experience

✅ Epic 1.1 – Momentum Meter
	•	Core engagement metric ✅ 
	•	Displays user state: Rising, Steady, Needs Care ✅ 

🟡 Epic 1.2 – Today Feed
	•	Daily brief delivering motivational, behavioral, and lifestyle content ✅ 
	•	Now includes program + fun + lifestyle content strategy

🟡 Epic 1.3 – Adaptive AI Coach (Phase 1 only)
	•	AI interaction with users ✅ 
	•	Responds to Momentum Score
	•	Includes tone matching, basic coaching prompts

🟡 Epic 1.5 – Habit Architect (MVP Subset)
	•	Allows patient to create “Action Steps” (process goals)
	•	Captures goal_completion events
	•	Escalates if 3+ completions are missed in 7 days

🆕 Epic 1.9 – Subjective Energy Score
	•	1–5 emoji rating captured daily or user-specified cadence
	•	Contributes to Momentum Score

🆕 Epic 1.10 – Progress to Goal Tracker
	•	Captures outcome goal (weight or Vitality Score)
	•	Displays progress in dashboard/chart form

⸻

🔗 MODULE 2: Data Integration & Events

✅ Epic 2.1 – Engagement Events Logging
	•	Foundation for capturing all user actions
	•	DB + API layer complete
	•	MVP needs actual insert() calls wired from features like AI chat, action steps

✅ Epic 2.2 – Wearable Integration Layer
	•	Passive data (steps, sleep, HR, weight) captured via HealthKit, etc.
	•	Used for habit consistency analysis

✅ Epic 2.3 – Coaching Interaction Log
	•	Tracks AI + human chat interactions
	•	Required for engagement model + later motivation analysis

⸻

🤖 MODULE 3: AI & Personalization

🟡 Epic 3.2 – AI Nudge Optimizer (Basic version)
	•	Part of MVP only to the extent it can deliver low-complexity nudges (e.g., “You missed your goal yesterday”)
	•	Full predictive JITAI logic is post-MVP

⸻

🧑‍⚕️ MODULE 4: Coaching & Support

⚪ Epic 4.1 – Coach Dashboard (Alpha only)
	•	Internal-use only
	•	Displays escalations, subjective energy, goal completions
	•	Simple Vue.js interface, no production polish required

⸻

🆕 MODULE 6: Vitality Score Integration

🆕 Epic 6.1 – Vitality Score
	•	Manual entry during onboarding
	•	Converts lab/vitals into banded “Foundational → Optimizing” score
	•	Used for visualization and as an optional outcome goal

⸻

✅ MVP Epic Completion Summary

Module	Epic	Required for MVP?	Notes
1	1.1 Momentum Meter	✅	Complete
1	1.2 Today Feed	⚠️ 	Partial - need to integrate program content in addition to generic lifestyle content
1	1.3 Adaptive AI Coach (Phase 1)	✅	Core AI experience
1	1.5 Habit Architect (subset)	🟡 	Action steps + escalation
1	1.9 Subjective Energy Score	🟡 	Momentum component
1	1.10 Progress to Goal Tracker	🟡 	Weight or Vitality
2	2.1 Engagement Events Logging	🟡 	Wiring must be complete
2	2.2 Wearable Integration Layer	⚠️ 	Biometric scoring
2	2.3 Coaching Interaction Log	⚠️	AI interaction audit trail
3	3.2 AI Nudge Optimizer	⚠️ Partial	Just-in-time nudges only
4	4.1 Coach Dashboard Alpha	🟡	Internal use only
6	6.1 Vitality Score	🟡	Band-based health marker


⸻