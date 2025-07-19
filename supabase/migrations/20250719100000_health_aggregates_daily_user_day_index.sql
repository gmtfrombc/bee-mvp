-- 20250719100000_health_aggregates_daily_user_day_index.sql
-- Adds composite index to accelerate per-user day lookups for biometric flag detection

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_health_aggregates_daily_user_day
ON public.health_aggregates_daily (user_id, day DESC);
