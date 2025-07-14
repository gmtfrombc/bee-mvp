-- Migration: action_steps table init
-- Created for Epic 1.5, Milestone 1.5.1, Task T1

-- 1. Table definition
create table if not exists public.action_steps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  category text not null check (char_length(category) < 50),
  description text not null check (char_length(description) < 140),
  frequency int not null check (frequency between 3 and 7),
  week_start date not null,
  source text default 'AI-Coach',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. Composite index to speed up per-user weekly queries
create index if not exists idx_action_steps_user_week
  on public.action_steps (user_id, week_start);

-- 3. Trigger function to keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;$$ language plpgsql;

-- 4. Trigger that calls the function before every UPDATE
create trigger trg_action_steps_updated
  before update on public.action_steps
  for each row execute procedure public.set_updated_at(); 