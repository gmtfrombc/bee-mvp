-- Allow service_role full access (read/write) to coaching_effectiveness to enable Edge Function logging

alter table public.coaching_effectiveness enable row level security;

drop policy if exists service_role_full on public.coaching_effectiveness;

create policy service_role_full
  on public.coaching_effectiveness
  for all
  to service_role
  using (true)
  with check (true); 