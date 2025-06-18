-- Allow Edge Functions (service_role) to insert effectiveness metrics without violating RLS

alter table public.coaching_effectiveness enable row level security;

drop policy if exists service_role_insert on public.coaching_effectiveness;

create policy service_role_insert
  on public.coaching_effectiveness
  for insert
  to service_role
  with check (true); 