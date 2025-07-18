-- 30-Day Manual Biometrics – foundational table
-- Creates table expected by downstream trend view migration.

CREATE TABLE IF NOT EXISTS public.manual_biometrics (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weight_kg   NUMERIC NOT NULL CHECK (weight_kg BETWEEN 30 AND 250),
  height_cm   NUMERIC NOT NULL CHECK (height_cm BETWEEN 120 AND 250),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS and basic owner-only select/insert policies (keeps security consistent; more detailed policies added later)
ALTER TABLE public.manual_biometrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_manual_biometrics" ON public.manual_biometrics;
CREATE POLICY "select_own_manual_biometrics" ON public.manual_biometrics
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_manual_biometrics" ON public.manual_biometrics;
CREATE POLICY "insert_own_manual_biometrics" ON public.manual_biometrics
  FOR INSERT WITH CHECK (auth.uid() = user_id); 