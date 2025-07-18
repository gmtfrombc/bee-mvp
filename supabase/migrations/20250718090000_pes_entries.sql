-- 20250718090000_pes_entries.sql
-- Perceived Energy Score (PES) entries table with RLS and unique (user_id, date)

-- Enable pgcrypto extension for UUID generation (safe if already enabled)
create extension if not exists "pgcrypto";

-- Create pes_entries table
create table if not exists public.pes_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  score integer not null check (score between 1 and 5),
  created_at timestamptz not null default now(),
  unique (user_id, date)
);

-- Enable Row Level Security (RLS)
alter table public.pes_entries enable row level security;

-- Select policy: users can read their own entries only
create policy "select_own_pes_entries" on public.pes_entries
  for select using (auth.uid() = user_id);

-- Insert policy: users can insert only their own entries
create policy "insert_own_pes_entries" on public.pes_entries
  for insert with check (auth.uid() = user_id);

-- Update policy: users can update their own entries
create policy "update_own_pes_entries" on public.pes_entries
  for update using (auth.uid() = user_id);

-- Delete policy: users can delete their own entries
create policy "delete_own_pes_entries" on public.pes_entries
  for delete using (auth.uid() = user_id); 