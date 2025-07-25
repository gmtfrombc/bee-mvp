BEGIN;

-- Ensure pgcrypto extension for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- Table: momentum_pillars
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS momentum_pillars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- ---------------------------------------------------------------------------
-- Table: momentum_events
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS momentum_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users (id) ON DELETE CASCADE,
    pillar_id UUID REFERENCES momentum_pillars (id),
    event_type TEXT NOT NULL,
    event_ts TIMESTAMPTZ NOT NULL DEFAULT now(),
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Indexes to improve query performance
CREATE INDEX IF NOT EXISTS idx_momentum_events_user_id ON momentum_events (user_id);
CREATE INDEX IF NOT EXISTS idx_momentum_events_pillar_id ON momentum_events (pillar_id);
CREATE INDEX IF NOT EXISTS idx_momentum_events_event_ts ON momentum_events (event_ts);

-- ---------------------------------------------------------------------------
-- Row Level Security (RLS)
-- ---------------------------------------------------------------------------
-- RLS will be enabled and policies added in a later milestone. For now we leave
-- it disabled to simplify bulk back-fills and iterative development.

COMMIT;
-- end of file 
