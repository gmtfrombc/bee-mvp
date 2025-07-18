-- 30-Day Manual Biometrics Trend View
-- Creates a view returning the latest biometrics entries for the last 30 days
-- per user, sorted descending by created_at.
-- RLS is inherited from the underlying table `manual_biometrics`.

-- Drop and recreate so migration is idempotent when re-applied in CI pipelines
DROP VIEW IF EXISTS public.manual_biometrics_trend_30d CASCADE;

CREATE VIEW public.manual_biometrics_trend_30d AS
SELECT
  id,
  user_id,
  weight_kg,
  height_cm,
  created_at,
  created_at::date AS day
FROM public.manual_biometrics
WHERE created_at >= (now() - interval '30 days')
ORDER BY created_at DESC;

-- Grant select to authenticated role (same as table)
GRANT SELECT ON public.manual_biometrics_trend_30d TO authenticated; 