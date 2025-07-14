-- Migration: action_step_logs table init
-- Created for Epic 1.5, Milestone 1.5.1, Task T2

-- 1. Table definition
create table if not exists public.action_step_logs (
  id uuid primary key default gen_random_uuid(),
  action_step_id uuid references public.action_steps(id) on delete cascade,
  completed_on date not null,
  created_at timestamptz default now()
);

-- 2. Index to speed up joins and look-ups
create index if not exists idx_action_step_logs_action_step_id
  on public.action_step_logs (action_step_id); 