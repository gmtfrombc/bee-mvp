-- 01_base_schema.sql – base objects for DB tests
-- Creates minimal auth schema + _shared.audit trigger so migrations/tests run locally.
-- Idempotent: uses IF NOT EXISTS.

-- ╭─────────────────────────────────────────────────────────────╮
-- │  Auth schema + helper                                      │
-- ╰─────────────────────────────────────────────────────────────╯
CREATE SCHEMA IF NOT EXISTS auth;

-- Ensure pgcrypto for uuid generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS auth.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  encrypted_password TEXT,
  email_confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Simulate Supabase auth.uid()
CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
BEGIN
  RETURN NULLIF(current_setting('request.jwt.claims', true)::jsonb->>'sub', '')::UUID;
EXCEPTION
  WHEN others THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ╭─────────────────────────────────────────────────────────────╮
-- │  Shared audit schema                                       │
-- ╰─────────────────────────────────────────────────────────────╯
CREATE SCHEMA IF NOT EXISTS _shared;

CREATE TABLE IF NOT EXISTS _shared.audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT,
  action TEXT,
  old_row JSONB,
  new_row JSONB,
  changed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION _shared.audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO _shared.audit_log(table_name, action, old_row, new_row)
  VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW));
  RETURN COALESCE(NEW, OLD);
END;
$$; 
-- ╭─────────────────────────────────────────────────────────────╮
-- │  Base roles                                                │
-- ╰─────────────────────────────────────────────────────────────╯
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'authenticated'
  ) THEN
    CREATE ROLE authenticated;
  END IF;
END$$; 