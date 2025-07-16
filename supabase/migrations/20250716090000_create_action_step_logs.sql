-- Migration: action_step_logs table init
-- Created for Epic 1.5, Milestone 1.5.4, Task T1

-- 1. Table definition
create table if not exists public.action_step_logs (
  id uuid primary key default gen_random_uuid(),
  action_step_id uuid references public.action_steps(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  day date not null,
  status text not null check (status in ('completed', 'skipped')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. Unique constraint to avoid duplicate logs per user/day/step
create unique index if not exists uq_action_step_logs_user_day
  on public.action_step_logs (user_id, action_step_id, day);

-- 3. Trigger function to maintain updated_at
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end; $$ language plpgsql;

drop trigger if exists trg_action_step_logs_updated on public.action_step_logs;
create trigger trg_action_step_logs_updated
  before update on public.action_step_logs
  for each row execute procedure public.set_updated_at();

-- 4. Row Level Security
alter table public.action_step_logs enable row level security;

create policy "Allow user CRUD own logs"
  on public.action_step_logs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id); 