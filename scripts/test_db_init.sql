CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  encrypted_password TEXT,
  email_confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Simulated Supabase auth.uid() helper
CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
BEGIN
  RETURN NULLIF(current_setting('request.jwt.claims', true)::jsonb->>'sub', '')::UUID;
EXCEPTION
  WHEN others THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Engagement events table section removed; rely on real migration 20241201000000_engagement_events.sql
-- (previous inline stub has been commented out to surface ordering issues locally)
-- CREATE TABLE IF NOT EXISTS engagement_events (
--   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
--   timestamp TIMESTAMPTZ DEFAULT NOW(),
--   event_type TEXT NOT NULL,
--   value JSONB DEFAULT '{}'::jsonb,
--   is_deleted BOOLEAN DEFAULT FALSE
-- );

-- Indexes
-- CREATE INDEX IF NOT EXISTS idx_engagement_events_user_timestamp ON engagement_events(user_id, timestamp DESC);
-- CREATE INDEX IF NOT EXISTS idx_engagement_events_value ON engagement_events USING GIN(value);
-- CREATE INDEX IF NOT EXISTS idx_engagement_events_type ON engagement_events(event_type);

-- Constraints
-- ALTER TABLE engagement_events
--   ADD CONSTRAINT IF NOT EXISTS check_event_type_not_empty CHECK (event_type <> '' AND LENGTH(TRIM(event_type)) > 0);
-- ALTER TABLE engagement_events
--   ADD CONSTRAINT IF NOT EXISTS check_timestamp_not_future CHECK (timestamp <= NOW() + INTERVAL '1 minute');

-- RLS policies
-- ALTER TABLE engagement_events ENABLE ROW LEVEL SECURITY;

-- DROP POLICY IF EXISTS "Users can view own events" ON engagement_events;
-- DROP POLICY IF EXISTS "Users can insert own events" ON engagement_events;

-- CREATE POLICY "Users can view own events" ON engagement_events FOR SELECT USING (auth.uid() = user_id);
-- CREATE POLICY "Users can insert own events" ON engagement_events FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Minimal shared audit log
CREATE SCHEMA IF NOT EXISTS _shared;
CREATE TABLE IF NOT EXISTS _shared.audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT,
  action TEXT,
  old_row JSONB,
  new_row JSONB,
  changed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION _shared.audit() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO _shared.audit_log(table_name, action, old_row, new_row)
  VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW));
  RETURN COALESCE(NEW, OLD);
END;
$$; 