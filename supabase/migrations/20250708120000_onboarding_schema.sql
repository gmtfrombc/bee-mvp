-- 0️⃣  Extensions -----------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- 20250708120000_onboarding_schema.sql
-- Pre-Milestone Mini-Sprint: Onboarding Schema & RLS
-- Creates medical_history, biometrics, energy_rating_schedule enum & table
-- Adds RLS policies and shared audit triggers

-- 1️⃣  Enum -----------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type WHERE typname = 'energy_rating_schedule'
  ) THEN
    CREATE TYPE public.energy_rating_schedule AS ENUM (
      'morning',
      'afternoon',
      'evening',
      'night'
    );
  END IF;
END$$;

-- 2️⃣  Tables ---------------------------------------------------------------
create table if not exists public.medical_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  conditions text[] default '{}'::text[],
  medications jsonb default '{}'::jsonb,
  allergies text[] default '{}'::text[],
  family_history jsonb default '{}'::jsonb,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.biometrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  height_cm numeric(5,2),
  weight_kg numeric(5,2),
  bmi numeric(4,2),
  body_fat numeric(4,1),
  resting_hr int,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.energy_rating_schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  schedule public.energy_rating_schedule not null,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3️⃣  Row-Level Security ---------------------------------------------------
-- Medical History
alter table public.medical_history enable row level security;

drop policy if exists "medical_history_owner_select" on public.medical_history;
create policy "medical_history_owner_select"
  on public.medical_history for select
  using ( auth.uid() = user_id );

drop policy if exists "medical_history_owner_crud" on public.medical_history;
create policy "medical_history_owner_crud"
  on public.medical_history for all
  using ( auth.uid() = user_id )
  with check ( auth.uid() = user_id );

-- Biometrics
alter table public.biometrics enable row level security;

drop policy if exists "biometrics_owner_select" on public.biometrics;
create policy "biometrics_owner_select"
  on public.biometrics for select
  using ( auth.uid() = user_id );

drop policy if exists "biometrics_owner_crud" on public.biometrics;
create policy "biometrics_owner_crud"
  on public.biometrics for all
  using ( auth.uid() = user_id )
  with check ( auth.uid() = user_id );

-- Energy Rating Schedules
alter table public.energy_rating_schedules enable row level security;

drop policy if exists "ers_owner_select" on public.energy_rating_schedules;
create policy "ers_owner_select"
  on public.energy_rating_schedules for select
  using ( auth.uid() = user_id );

drop policy if exists "ers_owner_crud" on public.energy_rating_schedules;
create policy "ers_owner_crud"
  on public.energy_rating_schedules for all
  using ( auth.uid() = user_id )
  with check ( auth.uid() = user_id );

-- 4️⃣  Audit Triggers -------------------------------------------------------
-- Medical History

-- ... existing code ...
drop trigger if exists audit_medical_history on public.medical_history;
create trigger audit_medical_history
  after insert or update or delete on public.medical_history
  for each row execute procedure _shared.audit();

-- Biometrics

drop trigger if exists audit_biometrics on public.biometrics;
create trigger audit_biometrics
  after insert or update or delete on public.biometrics
  for each row execute procedure _shared.audit();

-- Energy Rating Schedules

drop trigger if exists audit_energy_rating_schedules on public.energy_rating_schedules;
create trigger audit_energy_rating_schedules
  after insert or update or delete on public.energy_rating_schedules
  for each row execute procedure _shared.audit(); 