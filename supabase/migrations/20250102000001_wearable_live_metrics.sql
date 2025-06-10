-- Wearable Live Metrics Schema for T2.2.2.10
-- Database tables for storing real-time wearable streaming metrics for Grafana dashboard

-- Create wearable_live_metrics table
CREATE TABLE IF NOT EXISTS public.wearable_live_metrics (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    messages_per_minute NUMERIC(10,2) DEFAULT 0 CHECK (messages_per_minute >= 0),
    median_latency_ms NUMERIC(10,2) DEFAULT 0 CHECK (median_latency_ms >= 0),
    error_rate NUMERIC(3,2) DEFAULT 0 CHECK (error_rate >= 0.0 AND error_rate <= 1.0),
    total_messages INTEGER DEFAULT 0 CHECK (total_messages >= 0),
    total_errors INTEGER DEFAULT 0 CHECK (total_errors >= 0),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_wearable_live_metrics_timestamp 
ON public.wearable_live_metrics(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_wearable_live_metrics_user_timestamp 
ON public.wearable_live_metrics(user_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_wearable_live_metrics_messages_per_minute 
ON public.wearable_live_metrics(messages_per_minute DESC);

-- Create view for Grafana queries
CREATE OR REPLACE VIEW public.wearable_live_metrics_aggregated AS
SELECT 
    date_trunc('minute', timestamp) as minute_timestamp,
    COUNT(*) as data_points,
    AVG(messages_per_minute) as avg_messages_per_minute,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY median_latency_ms) as median_latency_ms,
    AVG(error_rate) as avg_error_rate,
    MAX(total_messages) as max_total_messages,
    MAX(total_errors) as max_total_errors
FROM public.wearable_live_metrics
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY date_trunc('minute', timestamp)
ORDER BY minute_timestamp DESC;

-- Function to clean up old metrics data
CREATE OR REPLACE FUNCTION cleanup_wearable_live_metrics()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete metrics older than 7 days
    DELETE FROM public.wearable_live_metrics
    WHERE timestamp < NOW() - INTERVAL '7 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Log cleanup activity
    INSERT INTO public.system_logs (
        log_level, 
        message, 
        metadata,
        created_at
    ) VALUES (
        'INFO',
        'Cleaned up wearable live metrics',
        jsonb_build_object(
            'deleted_count', deleted_count,
            'retention_days', 7
        ),
        NOW()
    );
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create system_logs table if it doesn't exist (for cleanup logging)
CREATE TABLE IF NOT EXISTS public.system_logs (
    id SERIAL PRIMARY KEY,
    log_level TEXT NOT NULL,
    message TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Grant permissions for service role and authenticated users
GRANT SELECT, INSERT ON public.wearable_live_metrics TO service_role;
GRANT SELECT ON public.wearable_live_metrics TO authenticated;
GRANT SELECT ON public.wearable_live_metrics_aggregated TO authenticated, anon;
GRANT EXECUTE ON FUNCTION cleanup_wearable_live_metrics() TO service_role;

-- Enable RLS
ALTER TABLE public.wearable_live_metrics ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can view their own metrics" ON public.wearable_live_metrics
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can insert metrics" ON public.wearable_live_metrics
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- Comment the table and view
COMMENT ON TABLE public.wearable_live_metrics IS 'Real-time metrics for wearable live streaming monitoring (T2.2.2.10)';
COMMENT ON VIEW public.wearable_live_metrics_aggregated IS 'Aggregated metrics view for Grafana dashboard consumption';
COMMENT ON FUNCTION cleanup_wearable_live_metrics() IS 'Cleanup function to remove old wearable metrics data'; 