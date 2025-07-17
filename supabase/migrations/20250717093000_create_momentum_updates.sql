-- Migration: create momentum_updates table for action step momentum updates
-- Created at: 2025-07-17 09:30 UTC

begin;

create table if not exists public.momentum_updates (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    action_step_id uuid references public.action_steps(id) on delete cascade not null,
    day date not null,
    status text not null check (status in ('completed','skipped')),
    correlation_id text not null unique,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Timestamp trigger to keep updated_at fresh
do $outer$
begin
    if not exists (select 1 from pg_proc where proname = 'set_updated_at') then
        create function set_updated_at() returns trigger as $$
        begin
            new.updated_at = now();
            return new;
        end;
        $$ language plpgsql;
    end if;
end;
$outer$ language plpgsql;

create trigger momentum_updates_set_updated_at
before update on public.momentum_updates
for each row execute procedure set_updated_at();

-- Enable RLS
alter table public.momentum_updates enable row level security;

-- Policy: owner can select / insert / update / delete
create policy momentum_updates_owner on public.momentum_updates
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

commit; 