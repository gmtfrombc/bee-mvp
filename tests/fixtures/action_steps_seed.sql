insert into auth.users (id, email, encrypted_password, email_confirmed_at)
values
  ('00000000-0000-0000-0000-000000000001', 'seed_user@example.com', 'PLACEHOLDER_HASH', now())
on conflict (id) do nothing;

insert into public.action_steps (user_id, category, description, frequency, week_start)
values
  ('00000000-0000-0000-0000-000000000001', 'Movement', 'Walk 5,000 steps', 5, date_trunc('week', now())),
  ('00000000-0000-0000-0000-000000000001', 'Mindfulness', 'Meditate 10 minutes', 7, date_trunc('week', now()))
on conflict do nothing; 