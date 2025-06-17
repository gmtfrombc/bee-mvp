-- Migration: create coach_interaction_metrics table
-- Generated 2025-06-16 for Epic 2.3 M2.3.3

create table if not exists public.coach_interaction_metrics (
    user_id uuid not null references auth.users(id) on delete cascade,
    metric_date date not null,
    response_time_avg numeric,
    satisfaction_avg numeric,
    persona_mix jsonb default '{}'::jsonb,
    created_at timestamptz not null default now(),
    primary key (user_id, metric_date)
);

comment on table public.coach_interaction_metrics is 'Daily aggregate metrics derived from coach_interactions.';

create index if not exists coach_interaction_metrics_created_idx on public.coach_interaction_metrics(created_at);

-- RLS: users can select their own aggregates
alter table public.coach_interaction_metrics enable row level security;
create policy "User can read own metrics" on public.coach_interaction_metrics
    for select using (auth.uid() = user_id);

-- service_role full access
create policy "Service role all metrics" on public.coach_interaction_metrics
    for all
    using (auth.role() = 'service_role')
    with check (auth.role() = 'service_role'); 