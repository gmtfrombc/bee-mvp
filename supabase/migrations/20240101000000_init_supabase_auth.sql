-- 20240101000000_init_supabase_auth.sql — Bootstrap Supabase-like auth schema for local/CI
-- -----------------------------------------------------------------------------
-- This migration provides the minimal objects required by later migrations that
-- reference `auth.users`, `auth.uid()` and Supabase roles.
-- It is intentionally idempotent so it can run against an environment where
-- Supabase has already provisioned these objects.

-- Ensure pgcrypto for gen_random_uuid()
DO $$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  EXCEPTION
    WHEN others THEN
      -- Some restricted roles (e.g., CI "migration_runner") cannot create
      -- extensions.  Skip if permission is denied and assume pgcrypto exists.
      RAISE NOTICE 'pgcrypto extension unavailable for current role, skipping.';
  END;
END$$;

-- Attempt to enable pg_cron if available (non-critical)
DO $$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
  EXCEPTION
    WHEN others THEN
      -- In restricted environments (e.g., Supabase Cloud) creating pg_cron in
      -- non-postgres databases is not permitted.  Ignore any error and
      -- continue – this extension is optional for the BEE project.
      RAISE NOTICE 'pg_cron unavailable or not permitted in this DB, skipping.';
  END;
END$$;

-- ╭─────────────────────────────────────────────────────────────╮
-- │  auth schema & helpers                                     │
-- ╰─────────────────────────────────────────────────────────────╯
CREATE SCHEMA IF NOT EXISTS auth;

-- ---------------------------------------------------------------------------
-- In Supabase Cloud the `auth.users` table already exists and the executing
-- role (`supabase_admin`) lacks CREATE privilege on the `auth` schema. Using
-- `CREATE TABLE IF NOT EXISTS` still requires that privilege and therefore
-- fails.  Wrap the stub creation in a DO block so that we **attempt** the
-- CREATE only when the table is missing ‑ this avoids the permission check in
-- hosted environments.
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'auth' AND c.relname = 'users'
  ) THEN
    -- Local / CI environment – create minimal stub
    EXECUTE $tbl$
      CREATE TABLE auth.users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT UNIQUE,
        encrypted_password TEXT,
        email_confirmed_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        raw_app_meta_data JSONB DEFAULT '{}',
        raw_user_meta_data JSONB DEFAULT '{}'
      );
    $tbl$;
    RAISE NOTICE 'Created local stub auth.users table.';
  ELSE
    RAISE NOTICE 'auth.users already exists – skipping stub creation.';
  END IF;
END$$;

-- Simulate Supabase's auth.uid() helper that returns the authenticated user id
DO $$
BEGIN
  BEGIN
    CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $uid$
    BEGIN
        RETURN NULLIF(current_setting('request.jwt.claims', true)::jsonb->>'sub', '')::UUID;
    EXCEPTION
        WHEN others THEN
            RETURN NULL;
    END;
    $uid$ LANGUAGE plpgsql SECURITY DEFINER;
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'Skipping auth.uid() creation: %', SQLERRM;
  END;
END$$;

-- Simulate Supabase's auth.role() helper
DO $$
BEGIN
  BEGIN
    CREATE OR REPLACE FUNCTION auth.role() RETURNS TEXT AS $role$
    BEGIN
        RETURN 'service_role';
    END;
    $role$ LANGUAGE plpgsql SECURITY DEFINER;
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'Skipping auth.role() creation: %', SQLERRM;
  END;
END$$;

-- Simulate Supabase's auth.jwt() helper
DO $$
BEGIN
  BEGIN
    CREATE OR REPLACE FUNCTION auth.jwt() RETURNS JSONB AS $jwt$
    BEGIN
        RETURN '{}'::jsonb;
    END;
    $jwt$ LANGUAGE plpgsql SECURITY DEFINER;
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'Skipping auth.jwt() creation: %', SQLERRM;
  END;
END$$;

-- ╭─────────────────────────────────────────────────────────────╮
-- │  Baseline roles (match Supabase)                           │
-- ╰─────────────────────────────────────────────────────────────╯
DO $$
BEGIN
  BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
          CREATE ROLE authenticated;
      END IF;
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
          CREATE ROLE anon;
      END IF;
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
          CREATE ROLE service_role;
      END IF;
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_functions_admin') THEN
          CREATE ROLE supabase_functions_admin;
      END IF;
  EXCEPTION WHEN others THEN
      RAISE NOTICE 'Skipping role creation: %', SQLERRM;
  END;
END$$; 

DO $$
DECLARE
  ext TEXT;
BEGIN
  FOREACH ext IN ARRAY ARRAY['vector', 'http', 'pg_net'] LOOP
    BEGIN
      EXECUTE format('CREATE EXTENSION IF NOT EXISTS %I', ext);
    EXCEPTION
      WHEN others THEN
        -- Permission denied or extension missing → skip gracefully
        RAISE NOTICE '% extension install skipped: %', ext, SQLERRM;
    END;
  END LOOP;
END$$; 

-- Stub pg_cron when extension is unavailable so later migrations that call
-- cron.schedule() parse successfully in vanilla Postgres 14 (CI/Docker).
DO $$
BEGIN
  -- If pg_cron extension/schema is still missing, create a minimal stub.
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'cron') THEN
    CREATE SCHEMA IF NOT EXISTS cron;
    -- No-op implementation that simply returns 0 so callers can proceed.
    CREATE OR REPLACE FUNCTION cron.schedule(
      job_name TEXT,
      schedule TEXT,
      command TEXT
    ) RETURNS BIGINT AS $cron$
    BEGIN
      RETURN 0; -- fake job id
    END;
    $cron$ LANGUAGE plpgsql;
  END IF;
END$$; 