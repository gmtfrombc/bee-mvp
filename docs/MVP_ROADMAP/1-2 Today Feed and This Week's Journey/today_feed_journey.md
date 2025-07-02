### 📆 Today Feed & This Week’s Journey – Enhancement Summary

🧠 Overview

This update enhances user engagement by updating both the Today Feed and the This Week’s Journey visualization with richer content, user-generated data, and improved visual design. Changes affect both backend generation (via Supabase + GPT-4o) and frontend display (Flutter UI components).

✅ Section 1: Today Feed – Daily Content Generation

🧩 Functionality
	•	Edge Function on Supabase:
	•	Generates 1 daily content tile per topic using ChatGPT 4o
	•	Topics:
	•	Nutrition
	•	Activity
	•	Sleep
	•	Prevention
	•	Lifestyle

⚠️ Current Bug
	•	Issue: Function works when manually triggered but does not run automatically on schedule
	•	Root Cause Suspected: Cron trigger misconfigured or authorization/scheduling issue
	•	Resolution Needed:
	•	Verify cron syntax in Supabase dashboard
	•	Check service role access & function deployment permissions
	•	Add logging to confirm whether function is hit on schedule

🧪 Content Rules
	•	Content source distribution (7-day rotation):
	•	3/7 Days → Existing behavior change library content
	•	3/7 Days → Fresh AI-generated content (GPT-4o)
	•	1/7 Days → Fun, light topic (e.g., joke, wellness trivia)


✅ Section 2: This Week’s Journey – UX Update

🎯 Design Change
	•	Old Metric: Weekly momentum score
	•	New Metric: Perceived Energy Score (PES), user-reported (scale of 1–5)

📊 Chart/Graph Behavior
	•	X-axis: Days of the week (M, T, W, T, F, S, S)
	•	Y-axis: PES score values (1 to 5)
	•	User Input:
	•	Users enter PES at their own cadence (typically 3–7x/week)
	•	Graph Behavior:
	•	Dots appear on days when PES is entered
	•	Dots are connected by lines to form a trendline across the week

🧱 Implementation Notes
	•	Store PES entries as:
{
  "user_id": "...",
  "date": "2025-06-29",
  "pes_score": 3
}

	•	Only render entries that exist for the current week
	•	If no data exists for a day, show the letter (e.g., “T”) without a value or marker


