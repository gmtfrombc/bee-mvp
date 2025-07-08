-- 20250708121000_onboarding_responses.sql
-- Milestone M1.11.1 · Task T1
-- Creates onboarding_responses table (DDL only)

-- 1️⃣  Table ---------------------------------------------------------------
create table if not exists public.onboarding_responses(
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    answers jsonb not null,
    inserted_at timestamptz default now(),
    updated_at timestamptz default now()
); 