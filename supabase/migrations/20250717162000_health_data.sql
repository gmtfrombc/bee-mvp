-- 20250717162000_health_data.sql
-- Health-Data Module Foundation – migration for energy_levels & biometric_manual_inputs tables with RLS

-- Enable pgcrypto extension for UUID generation (safe if already enabled)
create extension if not exists "pgcrypto";

-- Create energy_levels table
create table if not exists public.energy_levels (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  level text not null check (level in ('veryLow','low','medium','high','veryHigh')),
  recorded_at timestamptz not null default now()
);

-- Create biometric_manual_inputs table
create table if not exists public.biometric_manual_inputs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('weight','systolicBP','diastolicBP','heartRate','bodyFat')),
  value numeric not null,
  unit text not null,
  recorded_at timestamptz not null default now()
);

-- Enable Row Level Security
alter table public.energy_levels enable row level security;
alter table public.biometric_manual_inputs enable row level security;

-- Select policies (owner-only access)
create policy "select_own_energy_levels" on public.energy_levels
  for select using (auth.uid() = user_id);

create policy "select_own_biometric_inputs" on public.biometric_manual_inputs
  for select using (auth.uid() = user_id);

-- Insert policies
create policy "insert_own_energy_levels" on public.energy_levels
  for insert with check (auth.uid() = user_id);

create policy "insert_own_biometric_inputs" on public.biometric_manual_inputs
  for insert with check (auth.uid() = user_id);

-- Update policies
create policy "update_own_energy_levels" on public.energy_levels
  for update using (auth.uid() = user_id);

create policy "update_own_biometric_inputs" on public.biometric_manual_inputs
  for update using (auth.uid() = user_id);

-- Delete policies
create policy "delete_own_energy_levels" on public.energy_levels
  for delete using (auth.uid() = user_id);

create policy "delete_own_biometric_inputs" on public.biometric_manual_inputs
  for delete using (auth.uid() = user_id); 