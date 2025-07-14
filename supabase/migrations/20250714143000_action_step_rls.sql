-- Migration: action_step_rls
-- Epic 1.5 · Milestone 1.5.1 · Task T4

-- 1. Enable Row Level Security for action_steps
alter table public.action_steps enable row level security;

-- 2. Policies on action_steps
drop policy if exists select_own on public.action_steps;
create policy select_own
  on public.action_steps
  for select
  using (auth.uid() = user_id);

drop policy if exists modify_own on public.action_steps;
create policy modify_own
  on public.action_steps
  for insert
  with check (auth.uid() = user_id)
  using (auth.uid() = user_id);

-- 3. Enable Row Level Security for action_step_logs
alter table public.action_step_logs enable row level security;

-- 4. Policies on action_step_logs
drop policy if exists select_own on public.action_step_logs;
create policy select_own
  on public.action_step_logs
  for select
  using (
    exists (
      select 1 from public.action_steps s
      where s.id = action_step_id and s.user_id = auth.uid()
    )
  );

drop policy if exists insert_own on public.action_step_logs;
create policy insert_own
  on public.action_step_logs
  for insert
  with check (
    exists (
      select 1 from public.action_steps s
      where s.id = action_step_id and s.user_id = auth.uid()
    )
  )
  using (
    exists (
      select 1 from public.action_steps s
      where s.id = action_step_id and s.user_id = auth.uid()
    )
  );

-- No UPDATE policy is defined; action_step_logs is append-only. 