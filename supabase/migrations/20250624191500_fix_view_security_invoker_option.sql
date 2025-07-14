-- Migration: set security_invoker=true on daily_feed_content_current view
-- Date: 2025-06-24 19:15 UTC

BEGIN;

DROP VIEW IF EXISTS public.daily_feed_content_current;

CREATE VIEW public.daily_feed_content_current AS
SELECT *
  FROM public.daily_feed_content
 WHERE is_active = true
 ORDER BY generated_at DESC
 LIMIT 1;

COMMIT; 