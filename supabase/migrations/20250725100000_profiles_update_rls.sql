-- 20250725100000_profiles_update_rls.sql
-- Adds owner UPDATE policy so app can mark onboarding_complete.

alter table public.profiles enable row level security;

drop policy if exists "profiles_owner_update" on public.profiles;
create policy "profiles_owner_update"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);
