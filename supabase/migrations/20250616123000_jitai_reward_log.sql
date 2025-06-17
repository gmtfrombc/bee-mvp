-- Migration: JITAI Reward Log (T1.3.9.16)
-- Description: Logs contextual-bandit rewards for interventions
-- Date: 2025-06-16

CREATE TABLE IF NOT EXISTS public.jitai_reward_log (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trigger_id TEXT NOT NULL,
    intervention_type TEXT NOT NULL,
    context JSONB DEFAULT '{}',
    reward NUMERIC(4,3) NOT NULL CHECK (reward >= 0),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Performance index
CREATE INDEX IF NOT EXISTS idx_jitai_reward_user_date ON public.jitai_reward_log(user_id, recorded_at DESC);

-- Enable RLS
ALTER TABLE public.jitai_reward_log ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own rewards" ON public.jitai_reward_log
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can insert rewards" ON public.jitai_reward_log
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

COMMENT ON TABLE public.jitai_reward_log IS 'Stores reward signals for contextual-bandit learning of JITAI interventions'; 