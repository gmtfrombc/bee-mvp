-- Migration: Security fixes – remove SECURITY DEFINER from view & enable RLS on api_latency
-- Generated 2025-06-19 by AI assistant to address Supabase linter errors

-- 1️⃣ Recreate coach_interactions_public view with SECURITY INVOKER

-- Drop existing view (if present)
DROP VIEW IF EXISTS public.coach_interactions_public CASCADE;

-- Recreate view ensuring it runs with the privileges of the querying user
CREATE VIEW public.coach_interactions_public
WITH (security_invoker = true) AS
SELECT
  id,
  user_id,
  sender,
  LEFT(message, 100) AS message_preview,
  metadata - 'pii' AS metadata_sanitized,
  created_at
FROM public.coach_interactions;

COMMENT ON VIEW public.coach_interactions_public IS
  'Redacted view for analytics – trims message preview and removes possible PII keys (SECURITY INVOKER).';

-- Grant minimal read access to standard roles (if required). Adjust as needed.
GRANT SELECT ON public.coach_interactions_public TO authenticated, anon;


-- 2️⃣ Enable Row-Level Security on api_latency table

-- Ensure the table exists before applying changes
DO $$
BEGIN
  IF to_regclass('public.api_latency') IS NOT NULL THEN
    ALTER TABLE public.api_latency ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Restrict default access – explicit policies required for reads/writes.
REVOKE ALL PRIVILEGES ON public.api_latency FROM anon, authenticated;

-- Allow the Supabase service role full access so monitoring jobs can log data
CREATE POLICY "api_latency_service_role_rw" ON public.api_latency
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- (Optional) Add read-only access for internal dashboards
-- CREATE POLICY "api_latency_select_dashboard" ON public.api_latency
--   FOR SELECT TO dashboard_role USING (true); 