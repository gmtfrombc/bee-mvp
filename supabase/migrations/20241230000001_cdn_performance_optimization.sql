-- Migration: CDN Performance Optimization
-- Epic 1.3: Today Feed (AI Daily Brief)
-- Task: T1.3.1.9 - Set up content delivery and CDN integration
-- Created: 2024-12-30

-- Add performance tracking to content_delivery_optimization
ALTER TABLE public.content_delivery_optimization 
ADD COLUMN IF NOT EXISTS response_time_ms INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS bandwidth_saved_bytes BIGINT DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_warmup_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS warmup_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS compression_ratio NUMERIC(4,2) DEFAULT 1.0;

-- Create performance analytics view
CREATE OR REPLACE VIEW public.cdn_performance_analytics AS
SELECT 
    c.content_date,
    c.topic_category,
    c.title,
    o.cache_hits,
    o.cache_misses,
    o.cache_hits + o.cache_misses as total_requests,
    CASE 
        WHEN (o.cache_hits + o.cache_misses) > 0 
        THEN ROUND((o.cache_hits::numeric / (o.cache_hits + o.cache_misses)::numeric) * 100, 2)
        ELSE 0 
    END as hit_rate_percentage,
    o.compression_type,
    o.content_size,
    o.response_time_ms,
    o.bandwidth_saved_bytes,
    o.compression_ratio,
    o.last_modified,
    o.updated_at
FROM public.daily_feed_content c
JOIN public.content_delivery_optimization o ON c.id = o.content_id
WHERE c.content_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY c.content_date DESC;

-- Create content delivery performance index
CREATE INDEX IF NOT EXISTS idx_content_delivery_performance 
ON public.content_delivery_optimization(cache_hits DESC, cache_misses ASC, response_time_ms ASC);

-- Create content date performance index for faster analytics
CREATE INDEX IF NOT EXISTS idx_content_date_performance 
ON public.daily_feed_content(content_date DESC, topic_category);

-- Create compression analytics index
CREATE INDEX IF NOT EXISTS idx_compression_analytics 
ON public.content_delivery_optimization(compression_type, content_size, bandwidth_saved_bytes);

-- Create function to update compression metrics
CREATE OR REPLACE FUNCTION update_compression_metrics(
    p_content_id INTEGER,
    p_original_size INTEGER,
    p_compressed_size INTEGER,
    p_compression_type TEXT
) RETURNS VOID AS $$
DECLARE
    v_ratio NUMERIC(4,2);
    v_bandwidth_saved BIGINT;
BEGIN
    -- Calculate compression ratio and bandwidth saved
    v_ratio := CASE 
        WHEN p_compressed_size > 0 THEN p_original_size::numeric / p_compressed_size::numeric
        ELSE 1.0 
    END;
    
    v_bandwidth_saved := GREATEST(0, p_original_size - p_compressed_size);
    
    -- Update optimization record
    UPDATE public.content_delivery_optimization 
    SET 
        content_size = p_compressed_size,
        compression_ratio = v_ratio,
        bandwidth_saved_bytes = bandwidth_saved_bytes + v_bandwidth_saved,
        compression_type = p_compression_type,
        updated_at = NOW()
    WHERE content_id = p_content_id;
    
END;
$$ LANGUAGE plpgsql;

-- Create function to track cache warming
CREATE OR REPLACE FUNCTION record_cache_warmup(
    p_content_id INTEGER
) RETURNS VOID AS $$
BEGIN
    UPDATE public.content_delivery_optimization 
    SET 
        last_warmup_at = NOW(),
        warmup_count = warmup_count + 1,
        updated_at = NOW()
    WHERE content_id = p_content_id;
END;
$$ LANGUAGE plpgsql;

-- Create function to get performance recommendations
CREATE OR REPLACE FUNCTION get_performance_recommendations(
    p_days INTEGER DEFAULT 7
) RETURNS TABLE(
    recommendation_type TEXT,
    priority TEXT,
    description TEXT,
    metric_value NUMERIC,
    threshold_value NUMERIC
) AS $$
BEGIN
    -- Cache hit rate recommendations
    RETURN QUERY
    SELECT 
        'cache_hit_rate'::TEXT,
        CASE WHEN avg_hit_rate < 50 THEN 'high' WHEN avg_hit_rate < 70 THEN 'medium' ELSE 'low' END,
        'Cache hit rate is ' || ROUND(avg_hit_rate, 1) || '%. Consider increasing cache duration or implementing cache warming.',
        avg_hit_rate,
        80.0
    FROM (
        SELECT AVG(
            CASE 
                WHEN (cache_hits + cache_misses) > 0 
                THEN (cache_hits::numeric / (cache_hits + cache_misses)::numeric) * 100
                ELSE 0 
            END
        ) as avg_hit_rate
        FROM public.content_delivery_optimization o
        JOIN public.daily_feed_content c ON o.content_id = c.id
        WHERE c.content_date >= CURRENT_DATE - INTERVAL '%s days' % p_days
    ) hit_rate_data
    WHERE avg_hit_rate < 80;

    -- Compression usage recommendations
    RETURN QUERY
    SELECT 
        'compression_usage'::TEXT,
        CASE WHEN compression_usage < 30 THEN 'high' WHEN compression_usage < 60 THEN 'medium' ELSE 'low' END,
        'Only ' || ROUND(compression_usage, 1) || '% of content uses compression. Enable gzip/brotli for better performance.',
        compression_usage,
        80.0
    FROM (
        SELECT 
            (COUNT(*) FILTER (WHERE compression_type IN ('gzip', 'br'))::numeric / COUNT(*)::numeric) * 100 as compression_usage
        FROM public.content_delivery_optimization o
        JOIN public.daily_feed_content c ON o.content_id = c.id
        WHERE c.content_date >= CURRENT_DATE - INTERVAL '%s days' % p_days
    ) compression_data
    WHERE compression_usage < 80;

    -- Response time recommendations
    RETURN QUERY
    SELECT 
        'response_time'::TEXT,
        CASE WHEN avg_response_time > 2000 THEN 'high' WHEN avg_response_time > 1000 THEN 'medium' ELSE 'low' END,
        'Average response time is ' || ROUND(avg_response_time, 0) || 'ms. Target is <500ms for optimal performance.',
        avg_response_time,
        500.0
    FROM (
        SELECT AVG(response_time_ms) as avg_response_time
        FROM public.content_delivery_optimization o
        JOIN public.daily_feed_content c ON o.content_id = c.id
        WHERE c.content_date >= CURRENT_DATE - INTERVAL '%s days' % p_days
        AND response_time_ms > 0
    ) response_data
    WHERE avg_response_time > 500;

END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update performance metrics
CREATE OR REPLACE FUNCTION update_delivery_performance() RETURNS TRIGGER AS $$
BEGIN
    -- Update last_modified when optimization record changes
    NEW.updated_at = NOW();
    
    -- Calculate performance score based on metrics
    IF NEW.cache_hits + NEW.cache_misses > 0 THEN
        -- Update content with performance data if needed
        UPDATE public.daily_feed_content 
        SET updated_at = NOW()
        WHERE id = NEW.content_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_delivery_performance
    BEFORE UPDATE ON public.content_delivery_optimization
    FOR EACH ROW
    EXECUTE FUNCTION update_delivery_performance();

-- Grant necessary permissions
GRANT SELECT ON public.cdn_performance_analytics TO authenticated, anon;
GRANT EXECUTE ON FUNCTION update_compression_metrics(INTEGER, INTEGER, INTEGER, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION record_cache_warmup(INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION get_performance_recommendations(INTEGER) TO authenticated, anon, service_role;

-- Create performance monitoring view for admin dashboard
CREATE OR REPLACE VIEW public.cdn_performance_summary AS
SELECT 
    COUNT(*) as total_content_items,
    AVG(
        CASE 
            WHEN (cache_hits + cache_misses) > 0 
            THEN (cache_hits::numeric / (cache_hits + cache_misses)::numeric) * 100
            ELSE 0 
        END
    ) as avg_hit_rate,
    SUM(bandwidth_saved_bytes) as total_bandwidth_saved,
    AVG(compression_ratio) as avg_compression_ratio,
    COUNT(*) FILTER (WHERE compression_type IN ('gzip', 'br')) as compressed_items,
    AVG(response_time_ms) FILTER (WHERE response_time_ms > 0) as avg_response_time_ms,
    MAX(last_warmup_at) as last_warmup_time
FROM public.content_delivery_optimization o
JOIN public.daily_feed_content c ON o.content_id = c.id
WHERE c.content_date >= CURRENT_DATE - INTERVAL '30 days';

GRANT SELECT ON public.cdn_performance_summary TO authenticated, anon; 