-- Migration: set security_invoker on helper view to satisfy linter
-- Date: 2025-06-24 19:05 UTC

BEGIN;

ALTER VIEW public.daily_feed_content_current SET (security_invoker = true);

COMMIT; 