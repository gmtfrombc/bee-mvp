-- ============================================================================
-- Robust RLS enablement for PHI tables (idempotent / IF EXISTS)
-- This second pass guarantees RLS is enabled even if the previous migration
-- skipped because pg_tables didn't list certain relation types (e.g. partitions
-- or matviews).
-- ============================================================================

DO $$ DECLARE
    tables text[] := ARRAY['pmh','patients','scores','vitals','mental_health','lab_results'];
    tbl text;
    reltext text;
BEGIN
  FOREACH tbl IN ARRAY tables LOOP
    reltext := format('public.%s', tbl);
    IF to_regclass(reltext) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
      -- Drop policy if the table already had one, ignore errors if it didn't
      BEGIN
        EXECUTE format('DROP POLICY IF EXISTS service_role_bypass ON public.%I', tbl);
      EXCEPTION WHEN undefined_object THEN
        -- no-op
      END;
      EXECUTE format('CREATE POLICY service_role_bypass ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true)', tbl);
    END IF;
  END LOOP;
END $$; 