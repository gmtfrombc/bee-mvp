-- Coach Memory table for personalization tags
-- Migration generated for M1.11.5 (Task A4)

begin;

create table if not exists public.coach_memory (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    motivation_type text,
    readiness_level text,
    coach_style text,
    inserted_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Ensure one row per user
create unique index if not exists coach_memory_user_idx on public.coach_memory(user_id);

-- Row Level Security: owners can access their row
alter table public.coach_memory enable row level security;

-- Drop policy if it exists before creating
drop policy if exists "Users can manage own coach_memory" on public.coach_memory;

create policy "Users can manage own coach_memory" on public.coach_memory
    for all using (auth.uid() = user_id);

-- Trigger to update updated_at on modification
create or replace function public.set_updated_at_coach_memory()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Drop existing trigger if already defined
drop trigger if exists set_timestamp on public.coach_memory;

create trigger set_timestamp
before update on public.coach_memory
for each row execute procedure public.set_updated_at_coach_memory();

commit; 