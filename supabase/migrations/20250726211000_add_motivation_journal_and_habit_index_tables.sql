BEGIN;

-- Ensure pgcrypto for UUID
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- Table: motivation_journal
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS motivation_journal (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users (id) ON DELETE CASCADE,
    date DATE NOT NULL,
    prompt TEXT,
    response TEXT,
    motivation_type TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    UNIQUE (user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_motivation_journal_user_date ON motivation_journal (user_id, date);

-- ---------------------------------------------------------------------------
-- Table: habit_index
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS habit_index (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users (id) ON DELETE CASCADE,
    index_date DATE NOT NULL,
    habit_score NUMERIC NOT NULL,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    UNIQUE (user_id, index_date)
);

CREATE INDEX IF NOT EXISTS idx_habit_index_user_date ON habit_index (user_id, index_date);

-- ---------------------------------------------------------------------------
-- Row Level Security (RLS)
-- ---------------------------------------------------------------------------
ALTER TABLE motivation_journal DISABLE ROW LEVEL SECURITY;
ALTER TABLE habit_index DISABLE ROW LEVEL SECURITY;

COMMIT;
