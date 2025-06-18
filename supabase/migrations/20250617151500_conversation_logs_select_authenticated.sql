-- Ensure mobile clients (authenticated or anon) can read their own conversation logs

alter table public.conversation_logs enable row level security;

-- Remove any existing policy to avoid duplicates
DROP POLICY IF EXISTS user_select_auth ON public.conversation_logs;

CREATE POLICY user_select_auth
  ON public.conversation_logs
  FOR SELECT
  TO authenticated, anon
  USING (user_id = auth.uid()); 