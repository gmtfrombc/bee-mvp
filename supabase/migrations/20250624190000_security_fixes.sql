-- Migration: security fixes for linter warnings
-- Date: 2025-06-24 19:00 UTC

BEGIN;

-- 1. Recreate helper view without SECURITY DEFINER
DROP VIEW IF EXISTS public.daily_feed_content_current;
CREATE VIEW public.daily_feed_content_current AS
SELECT *
  FROM public.daily_feed_content
 WHERE is_active = true
 ORDER BY generated_at DESC
 LIMIT 1;

-- 2. Enable RLS on app_settings and add restrictive default policy
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- deny by default; service_role bypasses RLS automatically
CREATE POLICY app_settings_no_access
    ON public.app_settings
    FOR ALL
    USING (false);

COMMIT; 