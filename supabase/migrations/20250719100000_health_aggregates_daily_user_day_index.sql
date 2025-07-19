-- 20250719100000_health_aggregates_daily_user_day_index.sql
-- Adds composite index to accelerate per-user day lookups for biometric flag detection

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'health_aggregates_daily' AND n.nspname = 'public'
  ) THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_health_aggregates_daily_user_day ON public.health_aggregates_daily (user_id, day DESC)';
  END IF;
END $$;
