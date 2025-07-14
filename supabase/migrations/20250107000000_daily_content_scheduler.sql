-- Migration: Daily Content Generation Scheduler
-- Epic: 1.2.1 - Today Feed AI Content Generation Recovery
-- Task: T1.2.1.1.3 - Add daily content generation scheduling
-- Created: 2025-01-07

-- Enable RLS
ALTER DATABASE postgres SET row_security = on;

-- =====================================================
-- ENABLE REQUIRED EXTENSIONS
-- =====================================================
-- Enable pg_cron / pg_net extensions if available (skip if not installed)
DO $$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
  EXCEPTION
    WHEN undefined_file THEN
      RAISE NOTICE 'pg_cron extension not installed – skipping.';
  END;

  BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_net;
  EXCEPTION
    WHEN undefined_file THEN
      RAISE NOTICE 'pg_net extension not installed – skipping.';
  END;
END$$;

-- =====================================================
-- CONTENT GENERATION TRACKING
-- =====================================================
-- Table to track daily content generation jobs
CREATE TABLE IF NOT EXISTS public.content_generation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_date DATE NOT NULL,
    job_type TEXT NOT NULL CHECK (job_type IN ('daily_scheduled', 'manual_trigger', 'backfill', 'emergency_regen')),
    
    -- Job execution details
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    status TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed', 'cancelled', 'skipped')),
    
    -- Results summary
    content_generated BOOLEAN DEFAULT false,
    content_id INTEGER REFERENCES public.daily_feed_content(id),
    topic_category TEXT,
    ai_confidence_score NUMERIC(3,2),
    safety_score NUMERIC(3,2),
    
    -- Error tracking
    error_message TEXT,
    error_details JSONB,
    
    -- Performance metrics
    execution_time_ms INTEGER,
    generation_time_ms INTEGER,
    
    -- Audit fields
    triggered_by TEXT DEFAULT 'system',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for content generation jobs
CREATE INDEX IF NOT EXISTS idx_content_generation_jobs_date_status 
ON public.content_generation_jobs(job_date DESC, status);

CREATE INDEX IF NOT EXISTS idx_content_generation_jobs_created 
ON public.content_generation_jobs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_content_generation_jobs_status 
ON public.content_generation_jobs(status) WHERE status IN ('running', 'failed');

-- Enable Row Level Security (RLS)
ALTER TABLE public.content_generation_jobs ENABLE ROW LEVEL SECURITY;

-- RLS Policy for content generation jobs (publicly readable for monitoring)
CREATE POLICY "Content generation jobs are publicly readable" ON public.content_generation_jobs
    FOR SELECT USING (true);

-- =====================================================
-- CONTENT GENERATION FUNCTIONS
-- =====================================================

-- Function to trigger daily content generation
CREATE OR REPLACE FUNCTION trigger_daily_content_generation(
    p_target_date DATE DEFAULT CURRENT_DATE,
    p_force_regenerate BOOLEAN DEFAULT false,
    p_triggered_by TEXT DEFAULT 'system'
) RETURNS UUID AS $$
DECLARE
    v_job_id UUID;
    v_function_url TEXT;
    v_service_key TEXT;
    v_response JSONB;
BEGIN
    -- Create job record
    INSERT INTO public.content_generation_jobs (
        job_date, 
        job_type, 
        triggered_by,
        started_at
    ) VALUES (
        p_target_date,
        CASE WHEN p_triggered_by = 'system' THEN 'daily_scheduled' ELSE 'manual_trigger' END,
        p_triggered_by,
        NOW()
    ) RETURNING id INTO v_job_id;
    
    -- Get function URL and service key from settings
    -- In production, these would be set via environment variables
    v_function_url := current_setting('app.daily_content_generator_url', true);
    v_service_key := current_setting('app.service_role_key', true);
    
    -- Fallback URLs for development
    IF v_function_url IS NULL OR v_function_url = '' THEN
        v_function_url := 'http://localhost:54321/functions/v1/daily-content-generator';
    END IF;
    
    BEGIN
        -- Call the daily content generator Edge Function
        SELECT content INTO v_response
        FROM pg_net.http_post(
            url := v_function_url,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || COALESCE(v_service_key, 'dummy-key-for-dev')
            ),
            body := jsonb_build_object(
                'target_date', p_target_date::text,
                'force_regenerate', p_force_regenerate,
                'job_id', v_job_id::text
            ),
            timeout_milliseconds := 30000
        );
        
        -- Update job status based on response
        IF v_response IS NOT NULL AND (v_response->>'success')::boolean = true THEN
            UPDATE public.content_generation_jobs SET
                status = 'completed',
                completed_at = NOW(),
                content_generated = true,
                content_id = (v_response->'content'->>'id')::integer,
                topic_category = v_response->'content'->>'topic_category',
                ai_confidence_score = (v_response->'content'->>'ai_confidence_score')::numeric,
                execution_time_ms = (v_response->>'generation_time_ms')::integer,
                updated_at = NOW()
            WHERE id = v_job_id;
        ELSE
            UPDATE public.content_generation_jobs SET
                status = 'failed',
                completed_at = NOW(),
                error_message = COALESCE(v_response->>'message', 'Unknown error from content generator'),
                error_details = v_response,
                updated_at = NOW()
            WHERE id = v_job_id;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        -- Handle HTTP or other errors
        UPDATE public.content_generation_jobs SET
            status = 'failed',
            completed_at = NOW(),
            error_message = SQLERRM,
            error_details = jsonb_build_object(
                'error_code', SQLSTATE,
                'error_message', SQLERRM,
                'function_url', v_function_url
            ),
            updated_at = NOW()
        WHERE id = v_job_id;
    END;
    
    RETURN v_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update content generation job status
CREATE OR REPLACE FUNCTION update_content_generation_job_status(
    p_job_id UUID,
    p_status TEXT,
    p_content_id INTEGER DEFAULT NULL,
    p_topic_category TEXT DEFAULT NULL,
    p_ai_confidence_score NUMERIC DEFAULT NULL,
    p_safety_score NUMERIC DEFAULT NULL,
    p_error_message TEXT DEFAULT NULL,
    p_execution_time_ms INTEGER DEFAULT NULL,
    p_generation_time_ms INTEGER DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    UPDATE public.content_generation_jobs 
    SET 
        status = p_status,
        completed_at = CASE WHEN p_status IN ('completed', 'failed', 'cancelled', 'skipped') THEN NOW() ELSE completed_at END,
        content_id = COALESCE(p_content_id, content_id),
        topic_category = COALESCE(p_topic_category, topic_category),
        ai_confidence_score = COALESCE(p_ai_confidence_score, ai_confidence_score),
        safety_score = COALESCE(p_safety_score, safety_score),
        content_generated = CASE WHEN p_status = 'completed' AND p_content_id IS NOT NULL THEN true ELSE content_generated END,
        error_message = COALESCE(p_error_message, error_message),
        execution_time_ms = COALESCE(p_execution_time_ms, execution_time_ms),
        generation_time_ms = COALESCE(p_generation_time_ms, generation_time_ms),
        updated_at = NOW()
    WHERE id = p_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get content generation job status
CREATE OR REPLACE FUNCTION get_content_generation_job_status(
    p_job_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    job_id UUID,
    job_date DATE,
    status TEXT,
    content_generated BOOLEAN,
    content_id INTEGER,
    topic_category TEXT,
    ai_confidence_score NUMERIC,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    execution_time_ms INTEGER,
    error_message TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cgj.id,
        cgj.job_date,
        cgj.status,
        cgj.content_generated,
        cgj.content_id,
        cgj.topic_category,
        cgj.ai_confidence_score,
        cgj.started_at,
        cgj.completed_at,
        cgj.execution_time_ms,
        cgj.error_message
    FROM public.content_generation_jobs cgj
    WHERE cgj.job_date = p_job_date
    ORDER BY cgj.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if content generation is needed for a date
CREATE OR REPLACE FUNCTION is_content_generation_needed(
    p_target_date DATE DEFAULT CURRENT_DATE
) RETURNS BOOLEAN AS $$
DECLARE
    v_content_exists BOOLEAN := false;
    v_job_running BOOLEAN := false;
BEGIN
    -- Check if content already exists for this date
    SELECT EXISTS(
        SELECT 1 FROM public.daily_feed_content 
        WHERE content_date = p_target_date
    ) INTO v_content_exists;
    
    -- Check if a generation job is currently running
    SELECT EXISTS(
        SELECT 1 FROM public.content_generation_jobs 
        WHERE job_date = p_target_date 
        AND status = 'running'
        AND started_at > NOW() - INTERVAL '1 hour' -- Consider jobs older than 1 hour as stale
    ) INTO v_job_running;
    
    -- Generation is needed if content doesn't exist and no job is running
    RETURN NOT v_content_exists AND NOT v_job_running;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SCHEDULED JOBS SETUP
-- =====================================================

-- Schedule daily content generation at 3 AM UTC
-- This is the core requirement for T1.2.1.1.3
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname='cron') THEN
    PERFORM cron.schedule(
      'daily-content-generation',
      '0 3 * * *',
      $$
      SELECT trigger_daily_content_generation(CURRENT_DATE);
      $$
    );
  END IF;
END$$;

-- Schedule a backup generation check at 4 AM UTC in case 3 AM failed
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname='cron') THEN
    PERFORM cron.schedule(
      'daily-content-generation-backup',
      '0 4 * * *',
      $$
      SELECT CASE 
          WHEN is_content_generation_needed(CURRENT_DATE) 
          THEN trigger_daily_content_generation(CURRENT_DATE, false, 'backup_system')
          ELSE NULL::UUID
      END;
      $$
    );
  END IF;
END$$;

-- Schedule cleanup of old generation job records (keep 90 days)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname='cron') THEN
    PERFORM cron.schedule(
      'cleanup-content-generation-jobs',
      '0 2 * * 0',
      $$
      DELETE FROM public.content_generation_jobs 
      WHERE created_at < NOW() - INTERVAL '90 days';
      $$
    );
  END IF;
END$$;

-- =====================================================
-- MONITORING AND ANALYTICS
-- =====================================================

-- Create view for content generation monitoring
CREATE OR REPLACE VIEW public.content_generation_monitoring AS
SELECT 
    cgj.job_date,
    cgj.status,
    cgj.content_generated,
    cgj.topic_category,
    cgj.ai_confidence_score,
    cgj.safety_score,
    cgj.execution_time_ms,
    cgj.generation_time_ms,
    cgj.started_at,
    cgj.completed_at,
    cgj.error_message,
    cgj.triggered_by,
    dfc.title as content_title,
    dfc.summary as content_summary,
    dfc.created_at as content_created_at
FROM public.content_generation_jobs cgj
LEFT JOIN public.daily_feed_content dfc ON cgj.content_id = dfc.id
WHERE cgj.job_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY cgj.job_date DESC, cgj.created_at DESC;

-- Create view for content generation success metrics
CREATE OR REPLACE VIEW public.content_generation_metrics AS
SELECT 
    DATE_TRUNC('week', job_date) as week_start,
    COUNT(*) as total_jobs,
    COUNT(*) FILTER (WHERE status = 'completed') as successful_jobs,
    COUNT(*) FILTER (WHERE status = 'failed') as failed_jobs,
    COUNT(*) FILTER (WHERE content_generated = true) as content_generated_count,
    ROUND(AVG(execution_time_ms), 2) as avg_execution_time_ms,
    ROUND(AVG(ai_confidence_score), 3) as avg_ai_confidence,
    ROUND(AVG(safety_score), 3) as avg_safety_score,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'completed')::numeric / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) as success_rate_percent
FROM public.content_generation_jobs
WHERE job_date >= CURRENT_DATE - INTERVAL '12 weeks'
GROUP BY DATE_TRUNC('week', job_date)
ORDER BY week_start DESC;

-- =====================================================
-- PERMISSIONS
-- =====================================================

-- Grant necessary permissions for authenticated users
GRANT SELECT ON public.content_generation_jobs TO authenticated;
GRANT SELECT ON public.content_generation_monitoring TO authenticated;
GRANT SELECT ON public.content_generation_metrics TO authenticated;

-- Grant permissions for service role (for the Edge Functions)
GRANT ALL ON public.content_generation_jobs TO service_role;
GRANT ALL ON public.content_generation_monitoring TO service_role;
GRANT ALL ON public.content_generation_metrics TO service_role;

-- Note: No sequence permissions needed for UUID primary key with gen_random_uuid()
-- GRANT USAGE, SELECT ON SEQUENCE public.content_generation_jobs_id_seq TO authenticated, service_role;

-- Grant function execution permissions
GRANT EXECUTE ON FUNCTION trigger_daily_content_generation(DATE, BOOLEAN, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION update_content_generation_job_status(UUID, TEXT, INTEGER, TEXT, NUMERIC, NUMERIC, TEXT, INTEGER, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION get_content_generation_job_status(DATE) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION is_content_generation_needed(DATE) TO authenticated, service_role;

-- =====================================================
-- DOCUMENTATION
-- =====================================================

-- Comments for documentation
COMMENT ON TABLE public.content_generation_jobs IS 'Tracks daily content generation jobs for monitoring and debugging';
COMMENT ON VIEW public.content_generation_monitoring IS 'Real-time monitoring view for content generation pipeline';
COMMENT ON VIEW public.content_generation_metrics IS 'Weekly success metrics for content generation performance';

COMMENT ON COLUMN public.content_generation_jobs.job_date IS 'Date for which content is being generated (YYYY-MM-DD)';
COMMENT ON COLUMN public.content_generation_jobs.job_type IS 'Type of generation job (daily_scheduled, manual_trigger, backfill, emergency_regen)';
COMMENT ON COLUMN public.content_generation_jobs.status IS 'Current status of the generation job';
COMMENT ON COLUMN public.content_generation_jobs.content_generated IS 'Whether content was successfully generated and stored';
COMMENT ON COLUMN public.content_generation_jobs.ai_confidence_score IS 'AI confidence score for the generated content (0.0 to 1.0)';
COMMENT ON COLUMN public.content_generation_jobs.safety_score IS 'Content safety score from validation (0.0 to 1.0)';
COMMENT ON COLUMN public.content_generation_jobs.execution_time_ms IS 'Total job execution time in milliseconds';
COMMENT ON COLUMN public.content_generation_jobs.generation_time_ms IS 'AI content generation time in milliseconds';

-- Log successful deployment
INSERT INTO public.content_generation_jobs (
    job_date, 
    job_type, 
    status, 
    triggered_by,
    started_at,
    completed_at,
    content_generated,
    error_message
) VALUES (
    CURRENT_DATE,
    'manual_trigger',
    'completed',
    'migration_setup',
    NOW(),
    NOW(),
    false,
    'Daily content generation scheduler successfully deployed'
); 