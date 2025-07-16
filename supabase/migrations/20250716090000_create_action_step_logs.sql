-- Migration: action_step_logs table enhancement
-- Created for Epic 1.5, Milestone 1.5.4, Task T1 (fix)

/*
This migration augments the action_step_logs table created in
20250714141000_action_step_logs.sql.  It adds missing columns and
constraints needed for Milestone M1.5.4 while remaining idempotent.
*/

-- 1. Rename completed_on → day (safe if already renamed)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'action_step_logs'
      AND column_name  = 'completed_on'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'action_step_logs'
      AND column_name  = 'day'
  ) THEN
    ALTER TABLE public.action_step_logs
      RENAME COLUMN completed_on TO day;
  END IF;
END$$;

-- 2. Add new columns if missing -----------------------------------
ALTER TABLE public.action_step_logs
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS status text CHECK (status in ('completed','skipped')) DEFAULT 'completed' NOT NULL,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- 3. Backfill user_id for existing rows (uses FK to action_steps)
UPDATE public.action_step_logs l
SET    user_id = s.user_id
FROM   public.action_steps s
WHERE  l.action_step_id = s.id
  AND  l.user_id IS NULL;

-- 4. Unique constraint to avoid duplicate logs per user/day/step
CREATE UNIQUE INDEX IF NOT EXISTS uq_action_step_logs_user_day
  ON public.action_step_logs (user_id, action_step_id, day);

-- 5. Trigger to keep updated_at fresh -----------------------------
-- Reuse shared helper if already defined
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_action_step_logs_updated ON public.action_step_logs;
CREATE TRIGGER trg_action_step_logs_updated
  BEFORE UPDATE ON public.action_step_logs
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 6. Enable/verify Row Level Security & policy --------------------
ALTER TABLE public.action_step_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow user CRUD own logs" ON public.action_step_logs;
CREATE POLICY "Allow user CRUD own logs"
  ON public.action_step_logs
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id); 