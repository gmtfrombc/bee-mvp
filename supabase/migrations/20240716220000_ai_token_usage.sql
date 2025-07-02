-- Create table to capture token usage & cost per AI call
-- ✅ Part of GC-6 analytics expansion

-- 1. Table definition
create table if not exists ai_token_usage (
  id bigserial primary key,
  user_id uuid references auth.users(id) on delete cascade,
  path text not null,
  total_tokens integer not null,
  cost_usd numeric(10,6) default 0 not null,
  captured_at timestamptz not null default now()
);

-- 2. Indexes for common queries (by user & by date)
create index if not exists ai_token_usage_user_idx on ai_token_usage(user_id);
create index if not exists ai_token_usage_captured_idx on ai_token_usage(captured_at desc);

-- 3. (Optional) Enable RLS but allow service role inserts
alter table ai_token_usage enable row level security;

-- Allow service role (supabase_functions_admin) full access
create policy "ai_token_usage_admin" on ai_token_usage
  for all
  to supabase_functions_admin
  using (true);

-- Allow authenticated users to select only their own rows (for potential future dashboard views)
create policy "ai_token_usage_owner_select" on ai_token_usage
  for select
  to authenticated
  using (auth.uid() = user_id); 