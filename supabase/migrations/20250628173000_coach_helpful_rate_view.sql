-- View for Grafana: daily helpful-rate of AI Coach
-- ✅ Part of GC-6 analytics expansion

create or replace view v_coach_helpful_rate as
select
  date_trunc('day', created_at) as day,
  avg(user_rating)::numeric(10,2) as helpful_rate
from public.coaching_effectiveness
where user_rating is not null
group by 1; 