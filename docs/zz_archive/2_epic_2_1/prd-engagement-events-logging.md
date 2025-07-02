# PRD – Engagement Events Logging (Core Engagement Module)

**Filename:** `prd-engagement-events-logging.md`  
**Module:** Core Engagement  
**Milestone:** 1 · Data Backbone

---

## 1. Introduction / Overview
The Engagement Events Logging subsystem captures every behavioral touchpoint that BEE must track (app opens, goal completions, wearable imports, coach messages).  It provides the canonical data pipeline that powers dashboards, nudges, analytics, and ML models.

## 2. Goals
1. Store all user‑behavior events in a single Postgres table with minimal schema.
2. Enforce per‑user Row‑Level Security (RLS).
3. Expose REST / GraphQL endpoints for CRUD and realtime subscriptions.
4. Support Supabase Realtime to stream new events to the Flutter app.

## 3. User Stories
- **System** – “As BEE, I log every user interaction so downstream services can act on it.”
- **Flutter Client** – “I subscribe to my own events to update the dashboard instantly.”
- **Nudge Engine** – “I query events to decide if a user is inactive for 48 h.”
- **Analyst** – “I run cohort SQL to study weekly engagement trends.”

## 4. Functional Requirements
1. **Schema** — table `engagement_events` with columns:  
   - `id` UUID primary key  
   - `user_id` UUID (FK → auth.users)  
   - `timestamp` TIMESTAMP WITH TZ, default `now()`  
   - `event_type` TEXT (e.g., `app_open`, `goal_complete`, `steps_import`)  
   - `value` JSONB (arbitrary payload)  
2. **Row‑Level Security** — Users can `SELECT`, `INSERT` their own rows only.  
3. **Indexes** — composite `(user_id, timestamp DESC)` and GIN on `value`.  
4. **API exposure** — Supabase auto‑generated REST & GraphQL; enable Realtime channel.  
5. **Batch import endpoint** — Cloud Function may bulk insert events via service role.  
6. **Data retention** — soft delete flag `is_deleted` BOOLEAN, default false.

## 5. Non‑Goals
- No deduplication logic (handled in upstream ETL).  
- No transformation/aggregation (done in analytics layer).  
- No wearable parsing specifics (separate PRD).

## 6. Design Considerations
- Keep schema generic via `event_type` + JSONB to avoid table sprawl.  
- Use `pgjwt` extension for service‑role inserts from Cloud Functions.  
- Ensure timestamps are always UTC.

## 7. Technical Considerations
- Supabase migration via SQL `202XXXXXX_engagement_events.sql`.  
- RLS policy SQL included in same migration file.  
- Seed script to generate mock events for testing.  
- Tests: insert/select with RLS using anon key.

## 8. Success Metrics
- 100 % of user interactions create an event row.  
- RLS audit confirms zero cross‑user leakage.  
- Realtime latency < 500 ms from insert to dashboard update.

## 9. Open Questions
- Do we need a dedicated enum table for `event_type`?  
- What is the expected event throughput per day at scale?

