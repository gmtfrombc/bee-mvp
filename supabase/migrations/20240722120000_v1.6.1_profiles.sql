-- 20240722120000_v1.6.1_profiles.sql
-- Milestone: M1.6.1 · Supabase Auth Backend Setup
-- Creates public.profiles table linked to auth.users (email/password auth)
-- Adds owner-only RLS policies and attaches shared audit trigger.

-- 1️⃣  Table ----------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  onboarding_complete boolean default false,
  created_at timestamptz default now()
);

-- 2️⃣  RLS ------------------------------------------------------------------
alter table public.profiles enable row level security;

-- Owner can read own profile
create policy if not exists "profiles_owner_select"
  on public.profiles for select
  using ( auth.uid() = id );

-- Owner can insert own row (first-time profile creation)
create policy if not exists "profiles_owner_insert"
  on public.profiles for insert
  with check ( auth.uid() = id );

-- 3️⃣  Audit trigger ---------------------------------------------------------
create trigger if not exists audit_profiles
  after insert or update or delete on public.profiles
  for each row execute procedure _shared.audit(); 