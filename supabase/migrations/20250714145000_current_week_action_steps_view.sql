-- Migration: current_week_action_steps_view
-- Epic 1.5 · Milestone 1.5.1 · Task T5

BEGIN;

-- 1️⃣  Ensure idempotency
DROP VIEW IF EXISTS public.current_week_action_steps;

-- 2️⃣  Helper view: returns all Action Steps for the CURRENT ISO-week for the
--     currently authenticated user (auth.uid()) together with how many times
--     the step has been completed in that week.
--
--     • Week begins at Monday 00:00 UTC (date_trunc('week', …)).
--     • RLS continues to protect underlying tables; additional WHERE clause
--       mirrors policy for defense-in-depth.
CREATE VIEW public.current_week_action_steps AS
SELECT a.*,                       -- all columns from action_steps
       COALESCE(COUNT(l.id), 0) AS completed_count
  FROM public.action_steps a
  LEFT JOIN public.action_step_logs l
    ON l.action_step_id = a.id
   AND l.completed_on >= a.week_start
   AND l.completed_on  <  a.week_start + INTERVAL '7 days'
 WHERE a.user_id = auth.uid()
   AND a.week_start >= date_trunc('week', timezone('utc', current_date))::date
   AND a.week_start <  date_trunc('week', timezone('utc', current_date))::date + INTERVAL '7 days'
GROUP BY a.id;

COMMIT; 