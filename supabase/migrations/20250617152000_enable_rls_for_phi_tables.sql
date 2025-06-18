-- ============================================================================
-- Enable Row Level Security + baseline policies for core PHI tables
-- This migration addresses Supabase dashboard warnings "RLS Disabled in Public"
-- for the following tables (audit 2025-06-17):
--   • public.pmh
--   • public.patients
--   • public.scores
--   • public.vitals
--   • public.mental_health
--   • public.lab_results
--
-- GUIDING PRINCIPLES
-- 1. RLS must always be enabled on tables containing PHI.
-- 2. The default posture is "deny all" – we only open the minimal paths
--    necessary for functionality.
-- 3. Edge Functions execute with the `service_role` key and therefore need a
--    blanket bypass policy (USING TRUE / WITH CHECK TRUE).
-- 4. Mobile/Client roles (`authenticated`, `anon`) will be granted access in
--    follow-up, fine-grained policies once column ownership semantics for each
--    table are finalised. For now they remain blocked which is the safest
--    default.
-- ============================================================================

-- Helper function to enable RLS & create a service_role bypass in a single
-- statement block.  We wrap each table in its own DO block so the migration
-- continues even if a table has already been secured in a previous deploy.

-- Template:
-- DO $$ BEGIN
--   ALTER TABLE public.<table_name> ENABLE ROW LEVEL SECURITY;
--   DROP POLICY IF EXISTS service_role_bypass ON public.<table_name>;
--   CREATE POLICY service_role_bypass
--     ON public.<table_name>
--     FOR ALL
--     TO service_role
--     USING (true)
--     WITH CHECK (true);
-- END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'pmh') THEN
    ALTER TABLE public.pmh ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS service_role_bypass ON public.pmh;
    CREATE POLICY service_role_bypass
      ON public.pmh
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'patients') THEN
    ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS service_role_bypass ON public.patients;
    CREATE POLICY service_role_bypass
      ON public.patients
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'scores') THEN
    ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS service_role_bypass ON public.scores;
    CREATE POLICY service_role_bypass
      ON public.scores
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'vitals') THEN
    ALTER TABLE public.vitals ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS service_role_bypass ON public.vitals;
    CREATE POLICY service_role_bypass
      ON public.vitals
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'mental_health') THEN
    ALTER TABLE public.mental_health ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS service_role_bypass ON public.mental_health;
    CREATE POLICY service_role_bypass
      ON public.mental_health
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'lab_results') THEN
    ALTER TABLE public.lab_results ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS service_role_bypass ON public.lab_results;
    CREATE POLICY service_role_bypass
      ON public.lab_results
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$; 