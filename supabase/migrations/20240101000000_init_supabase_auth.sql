-- 20240101000000_init_supabase_auth.sql — Bootstrap Supabase-like auth schema for local/CI
-- -----------------------------------------------------------------------------
-- This migration provides the minimal objects required by later migrations that
-- reference `auth.users`, `auth.uid()` and Supabase roles.
-- It is intentionally idempotent so it can run against an environment where
-- Supabase has already provisioned these objects.

-- Ensure pgcrypto for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ╭─────────────────────────────────────────────────────────────╮
-- │  auth schema & helpers                                     │
-- ╰─────────────────────────────────────────────────────────────╯
CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    encrypted_password TEXT,
    email_confirmed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    raw_app_meta_data JSONB DEFAULT '{}'::jsonb,
    raw_user_meta_data JSONB DEFAULT '{}'::jsonb
);

-- Simulate Supabase's auth.uid() helper that returns the authenticated user id
CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
BEGIN
    RETURN NULLIF(current_setting('request.jwt.claims', true)::jsonb->>'sub', '')::UUID;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ╭─────────────────────────────────────────────────────────────╮
-- │  Baseline roles (match Supabase)                           │
-- ╰─────────────────────────────────────────────────────────────╯
DO $$
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
END$$; 