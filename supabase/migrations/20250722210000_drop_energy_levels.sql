-- Migration: Drop deprecated energy_levels table (PES rollout)
-- Description: Removes legacy energy_levels table and associated objects.
-- Generated at 2025-07-22 21:00 UTC

set check_function_bodies = off;

-- Drop table and cascade to associated policies, triggers, etc.
drop table if exists public.energy_levels cascade;
