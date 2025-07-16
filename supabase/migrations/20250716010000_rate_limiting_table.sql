-- =====================================================
-- Rate Limiting table for Edge Functions and other API call quotas
-- =====================================================

CREATE TABLE IF NOT EXISTS public.rate_limiting (
    user_id UUID NOT NULL,
    function_name TEXT NOT NULL,
    window_start TIMESTAMPTZ NOT NULL,
    request_count INTEGER NOT NULL DEFAULT 0,
    last_request_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT rate_limiting_pkey PRIMARY KEY (user_id, function_name, window_start)
);

-- Indexes to speed up lookup by function name within a window
CREATE INDEX IF NOT EXISTS idx_rate_limiting_func_window
    ON public.rate_limiting(function_name, window_start DESC);

-- Enable Row Level Security
ALTER TABLE public.rate_limiting ENABLE ROW LEVEL SECURITY;

-- Policy: users can view their own rate-limit records
DROP POLICY IF EXISTS "Users can view own rate limits" ON public.rate_limiting;
CREATE POLICY "Users can view own rate limits"
    ON public.rate_limiting
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: service role has full access (supplied to edge functions)
DROP POLICY IF EXISTS "Service role can manage rate limits" ON public.rate_limiting;
CREATE POLICY "Service role can manage rate limits"
    ON public.rate_limiting
    FOR ALL
    TO service_role
    USING (true); 