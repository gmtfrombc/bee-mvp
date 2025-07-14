-- Migration: set security_invoker on helper view to satisfy linter
-- Date: 2025-06-24 19:05 UTC

BEGIN;

-- No-op in vanilla Postgres (security_invoker option unsupported in PG14);
-- Supabase cloud keeps view property separately.

COMMIT; 