-- 20250724140000_create_biometric_flags.sql
-- Creates biometric_flags table and applies row-level security (RLS)

-- 1. Table definition
CREATE TABLE biometric_flags (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users NOT NULL,
    flag_type text CHECK (flag_type IN ('low_steps', 'low_sleep')),
    detected_on timestamptz NOT NULL DEFAULT now(),
    details jsonb,
    resolved boolean NOT NULL DEFAULT false
);

-- 2. Indexes
CREATE INDEX idx_biometric_flags_user_time ON biometric_flags (user_id, detected_on DESC);

-- 3. Row-Level Security (RLS)
ALTER TABLE biometric_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY owner_can_manage_own_flags ON biometric_flags
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
