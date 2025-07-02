# ⚡ Momentum Score – Implementation Guide (v2)

## 🎯 Purpose

This guide details the robust technical strategy for implementing the Momentum Score system, including signal integration, schema design, and raw data storage to support predictive modeling and user feedback.

---

## 🧭 Implementation Roadmap

### ✅ Step 1: Implement Behavioral Signal Integrations

#### Purpose
Enable high-signal, actionable user behaviors to be scored in real time and incorporated into the daily Momentum Score calculation.

#### Cursor AI Assistant Tasks

For each behavioral signal, implement the following:

| Signal | Data Source | Integration Task |
|--------|-------------|------------------|
| **Coach Interactions** | Chat transcript (AI coach, provider) | Use LLM to classify motivational tone (e.g. intrinsic, external); store tag + timestamp |
| **Action Step Completion** | User task system | Log completion status and timestamps to `momentum_events`; tag as `action_step` |
| **Today Tile Interaction** | App clickstream | Log when user taps/scrolls/interacts with tile or coach messages tied to tile |
| **Sleep/Steps Syncing** | HealthKit/Garmin | Log daily values and consistency; sync into `biometric_streams` table |
| **Progress to Goal** | Goal metadata | Track % completion toward SMART goals (weight, exercise, etc.) |
| **Motivation Score** | PES + motivation journal + NLP | Calculate and store daily score from micro-check-ins |
| **Biometric Changes** | Device data (user-validated) | Tag biometric changes that are confirmed by user input |
| **Internal Motivation Score** | NLP from journals, transcripts | Output a daily value (0–100) that reflects internalization, store as `motivation_score` |

Each event must:
- Include: `user_id`, `event_type`, `timestamp`, `raw_value`, `normalized_score`, `source`
- Be normalized to a 0–1 scale before fusion into pillar subscores

---

### ✅ Step 2: Schema Redesign

#### Purpose
Structure data to support modular scoring, retrospective analysis, and ML-readiness.

#### Cursor AI Assistant Tasks

Create the following tables with normalization and versioning in mind:

#### `momentum_events`
Logs all events (actions, interactions, signals) contributing to momentum.

```sql
CREATE TABLE momentum_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users,
  event_type TEXT,
  raw_value FLOAT,
  normalized_score FLOAT,
  source TEXT,
  tag TEXT,
  created_at TIMESTAMP DEFAULT now()
);
```

#### `momentum_pillars`
Stores pre-computed daily subscores for each momentum pillar.

```sql
CREATE TABLE momentum_pillars (
  user_id UUID REFERENCES auth.users,
  date DATE,
  cognitive_score FLOAT,
  behavioral_score FLOAT,
  relational_score FLOAT,
  biometric_score FLOAT,
  overall_score FLOAT,
  version TEXT DEFAULT 'v1',
  PRIMARY KEY (user_id, date)
);
```

#### `raw_behavioral_logs` (Optional)
Archive raw interaction data for future validation or model refinement.

```sql
CREATE TABLE raw_behavioral_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  interaction_type TEXT,
  raw_data JSONB,
  source TEXT,
  timestamp TIMESTAMP DEFAULT now()
);
```

---

### ✅ Step 3: Store Raw Values for Validation

#### Purpose
Enable retrospective analysis, model training, and score tuning based on outcome metrics (goal attainment, retention, biometric change).

#### Cursor AI Assistant Tasks

Log all relevant raw data in the following formats:

| Data Type | Storage Table | Required Fields |
|-----------|---------------|-----------------|
| **Biometric Streams** | `biometric_streams` | user_id, date, value, source |
| **Action Logs** | `momentum_events` | event_type = "action_step", raw_value = % completed |
| **Goal Logs** | `goal_progress_log` | goal_id, user_id, % completed, timestamps |
| **Coach Visit Logs** | `visit_adherence_log` | visit_id, user_id, scheduled_time, actual_time, status |

Use consistent timestamp formats and link events to sessions or messages when possible.

---

## ✅ Additional Recommendations

- **Daily Score Recalculation Cron**: Run daily to calculate and store Momentum Pillar Scores.
- **Historical Score Backfill**: Recalculate historical scores with updated weights and data.
- **Momentum API**: Expose API endpoint to retrieve `momentum_pillars` data for frontend.

---

Last Updated: June 30, 2025
