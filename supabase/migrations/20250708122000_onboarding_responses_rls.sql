-- 20250708122000_onboarding_responses_rls.sql
-- Milestone M1.11.1 · Task T4
-- Adds row-level security (RLS) policies for onboarding_responses table

-- 1️⃣  Enable RLS -----------------------------------------------------------
alter table public.onboarding_responses enable row level security;

-- 2️⃣  Policies -------------------------------------------------------------

drop policy if exists onboarding_responses_owner_select on public.onboarding_responses;
create policy onboarding_responses_owner_select
on public.onboarding_responses for select
using (auth.uid() = user_id);

drop policy if exists onboarding_responses_owner_crud on public.onboarding_responses;
create policy onboarding_responses_owner_crud
on public.onboarding_responses for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id); 