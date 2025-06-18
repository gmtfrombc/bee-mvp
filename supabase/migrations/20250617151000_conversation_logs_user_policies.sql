-- RLS policies allowing each user to read/write only their own conversation logs

alter table public.conversation_logs enable row level security;

drop policy if exists user_select on public.conversation_logs;

drop policy if exists user_insert on public.conversation_logs;

create policy user_select
  on public.conversation_logs
  for select
  using (user_id = auth.uid());

create policy user_insert
  on public.conversation_logs
  for insert
  with check (user_id = auth.uid()); 