-- Migration: action_step_logs table init
-- Created for Epic 1.5, Milestone 1.5.1, Task T2

-- Ensure idempotency in repeated CI runs
DROP TABLE IF EXISTS public.action_step_logs CASCADE;

-- 1. Table definition
CREATE TABLE IF NOT EXISTS public.action_step_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_step_id UUID REFERENCES public.action_steps (id) ON DELETE CASCADE,
    completed_on DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Index to speed up joins and look-ups
CREATE INDEX IF NOT EXISTS idx_action_step_logs_action_step_id
ON public.action_step_logs (action_step_id);
