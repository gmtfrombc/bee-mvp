## ⚡ Perceived Energy Score (PES) – Technical Specification

# 🧠 Overview

The Perceived Energy Score (PES) allows users to log how energized they feel on a scale from 1 to 5. This value is user-entered, reflects subjective wellness, and contributes to both visual trend displays and backend behavioral analytics. It will also dynamically inform the AI Coach’s messaging.

# 🖱️ 1. User Interaction

📝 Entry Mechanism
	•	Prompt shown on the Momentum Screen (or via a floating FAB if contextually appropriate)
	•	User selects a value from 1 (very low energy) to 5 (high energy)
	•	Simple UI: Horizontal slider or button row (e.g., 😫😐🙂😄⚡)

📆 Frequency
	•	User can submit once per day
	•	Cadence is up to user (from once per week to daily)
	•	If a score already exists for today, prompt is hidden or disabled

⸻

# 📊 2. Visualization

On Momentum Screen → “This Week’s Journey”
	•	X-axis: Days of the current week (e.g., M, T, W, etc.)
	•	Y-axis: PES values from 1 to 5
	•	Display:
	•	Dot above each day with submitted PES
	•	Dots are connected with a line to show the trend
	•	If no entry for a day, show day label but no dot

Expanded View – Modal Bottom Sheet
	•	Triggered by tapping the weekly chart
	•	Displays:
	•	Trend graph for past several weeks
	•	Option to toggle views: Week / Month
	•	Option to overlay “AI Coach Messages” for context

# 🗄️ 3. Data Schema & Storage

Supabase Table: pes_entries

CREATE TABLE pes_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  date DATE NOT NULL,
  score INTEGER CHECK (score BETWEEN 1 AND 5),
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE (user_id, date) -- one entry per day per user
);

Client Logic
	•	Query latest 7 entries for week chart
	•	Query rolling 28–90 days for modal view
	•	Debounce submissions to prevent accidental double entry

⸻

# 📈 4. Backend Use & Analytics

Contribution to Momentum Score (Engagement Metric)
	•	PES is one of several behavioral indicators
	•	Weighted into momentum_score based on:
	•	Frequency of entries
	•	Trends (increasing vs. decreasing energy)
	•	Correlation with other metrics (e.g., steps, messages, task completion)

AI Coach Integration
	•	PES entries are stored and accessible by AI logic
	•	Used to trigger message patterns such as:
	•	“Hey, I noticed your energy has been dropping lately—anything on your mind?”
	•	“Nice! You’ve logged great energy levels all week! Want to keep the streak going?”

⸻

# 🧠 5. Recommendations for Implementation

Area                        Recommendation
Frontend (Flutter)          Use LineChart or similar for trend line with dots
Data Sync                   Ensure offline-safe local storage with sync to Supabase
AI Access                   Expose pes_entries via secured backend endpoint or allow GPT context injection
Rate Limiting               Prevent >1 entry per day per user
Privacy                     PES is user-facing but treated as personal health signal for internal logic
