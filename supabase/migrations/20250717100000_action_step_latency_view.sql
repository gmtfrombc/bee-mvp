-- Migration: create view for p95 latency of action-step check-ins (Epic 1.5 – R1)
-- Created at: 2025-07-17 10:00 UTC

begin;

-- 1. View definition -----------------------------------------------------------
-- This view computes the 95th-percentile latency (ms) between the moment a
-- user logs an action-step completion/skip and the resulting momentum update
-- emitted by the edge function. It groups results by hour for easy charting in
-- Grafana.

create or replace view public.v_action_step_checkin_latency_p95 as
select
  date_trunc('hour', l.created_at)                            as bucket,
  percentile_cont(0.95) within group (
      order by extract(epoch from (u.created_at - l.created_at)) * 1000
  )::numeric(10,2)                                            as p95_latency_ms
from public.action_step_logs l
join public.momentum_updates u
  on u.user_id = l.user_id
 and u.action_step_id = l.action_step_id
 and u.day = l.day
where l.created_at >= now() - interval '30 days'
group by 1
order by 1;

comment on view public.v_action_step_checkin_latency_p95 is
  'Hourly p95 latency (ms) between action_step_logs insertion and momentum_updates.
   Used by Grafana panel "Action-Step Check-in p95 Latency"';

-- 2. Grant read-only access to dashboard roles (authenticated, anon) -----------
grant select on public.v_action_step_checkin_latency_p95 to authenticated, anon;

commit; 