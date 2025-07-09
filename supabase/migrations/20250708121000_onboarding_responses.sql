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

-- 2️⃣  Auto-create auth.users row on insert to satisfy FK in tests
create or replace function public.ensure_user_exists() returns trigger as $$
begin
  if not exists (select 1 from auth.users where id = NEW.user_id) then
    insert into auth.users(id) values (NEW.user_id);
  end if;
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists onboarding_user_autocreate on public.onboarding_responses;
create trigger onboarding_user_autocreate
  before insert on public.onboarding_responses
  for each row execute function public.ensure_user_exists(); 