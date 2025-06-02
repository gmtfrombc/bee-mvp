-- Migration: Score Calculation Scheduler
-- Purpose: Set up automated daily momentum score calculation
-- Epic: 1.1 · Momentum Meter
-- Task: T1.1.2.6 · Create Supabase Edge Functions for score calculation
-- 
-- Dependencies:
--   - Requires momentum_meter.sql migration (20241215000000)
--   - Requires momentum-score-calculator Edge Function
--   - Requires pg_cron extension
--
-- Created: 2024-12-17
-- Author: BEE Development Team

-- =====================================================
-- ENABLE REQUIRED EXTENSIONS
-- =====================================================
-- Enable pg_cron for scheduled jobs
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Enable pg_net for HTTP requests (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- =====================================================
-- SCORE CALCULATION TRACKING
-- =====================================================
-- Table to track daily score calculation jobs

CREATE TABLE IF NOT EXISTS score_calculation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_date DATE NOT NULL,
    job_type TEXT NOT NULL CHECK (job_type IN ('daily_batch', 'manual_trigger', 'backfill')),
    
    -- Job execution details
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    status TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed', 'cancelled')),
    
    -- Results summary
    users_processed INTEGER DEFAULT 0,
    users_successful INTEGER DEFAULT 0,
    users_failed INTEGER DEFAULT 0,
    
    -- Error tracking
    error_message TEXT,
    error_details JSONB,
    
    -- Performance metrics
    execution_time_ms INTEGER,
    
    -- Audit fields
    triggered_by TEXT DEFAULT 'system',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for score calculation jobs
CREATE INDEX idx_score_jobs_date_status 
ON score_calculation_jobs(job_date, status);

CREATE INDEX idx_score_jobs_status_created 
ON score_calculation_jobs(status, created_at);

-- =====================================================
-- SCORE CALCULATION FUNCTIONS
-- =====================================================
-- Function to trigger score calculation Edge Function

CREATE OR REPLACE FUNCTION trigger_daily_score_calculation(
    p_target_date DATE DEFAULT CURRENT_DATE
) RETURNS UUID AS $$
DECLARE
    job_id UUID;
    response_data JSONB;
BEGIN
    -- Create job record
    INSERT INTO score_calculation_jobs (
        job_date,
        job_type,
        triggered_by
    ) VALUES (
        p_target_date,
        'daily_batch',
        'scheduled_job'
    ) RETURNING id INTO job_id;
    
    -- Call the score calculation Edge Function
    SELECT INTO response_data net.http_post(
        url := current_setting('app.supabase_url') || '/functions/v1/momentum-score-calculator',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.supabase_service_key')
        ),
        body := jsonb_build_object(
            'calculate_all_users', true,
            'target_date', p_target_date::text
        )
    );
    
    -- Update job with initial response
    UPDATE score_calculation_jobs 
    SET 
        updated_at = NOW(),
        error_details = CASE 
            WHEN response_data->>'success' = 'true' THEN NULL
            ELSE response_data
        END
    WHERE id = job_id;
    
    RETURN job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update job status (called by Edge Function)
CREATE OR REPLACE FUNCTION update_score_calculation_job(
    p_job_id UUID,
    p_status TEXT,
    p_users_processed INTEGER DEFAULT NULL,
    p_users_successful INTEGER DEFAULT NULL,
    p_users_failed INTEGER DEFAULT NULL,
    p_error_message TEXT DEFAULT NULL,
    p_execution_time_ms INTEGER DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    UPDATE score_calculation_jobs 
    SET 
        status = p_status,
        completed_at = CASE WHEN p_status IN ('completed', 'failed', 'cancelled') THEN NOW() ELSE completed_at END,
        users_processed = COALESCE(p_users_processed, users_processed),
        users_successful = COALESCE(p_users_successful, users_successful),
        users_failed = COALESCE(p_users_failed, users_failed),
        error_message = COALESCE(p_error_message, error_message),
        execution_time_ms = COALESCE(p_execution_time_ms, execution_time_ms),
        updated_at = NOW()
    WHERE id = p_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get calculation job status
CREATE OR REPLACE FUNCTION get_calculation_job_status(
    p_job_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    job_id UUID,
    job_date DATE,
    status TEXT,
    users_processed INTEGER,
    users_successful INTEGER,
    users_failed INTEGER,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    execution_time_ms INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        scj.id,
        scj.job_date,
        scj.status,
        scj.users_processed,
        scj.users_successful,
        scj.users_failed,
        scj.started_at,
        scj.completed_at,
        scj.execution_time_ms
    FROM score_calculation_jobs scj
    WHERE scj.job_date = p_job_date
    ORDER BY scj.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SCHEDULED JOBS SETUP
-- =====================================================
-- Schedule daily score calculation at 1 AM UTC
-- Temporarily commented out for local development

-- SELECT cron.schedule(
--     'daily-momentum-calculation',
--     '0 1 * * *', -- 1 AM UTC daily
--     $$
--     SELECT trigger_daily_score_calculation(CURRENT_DATE - INTERVAL '1 day');
--     $$
-- );

-- Schedule cleanup of old job records (keep 90 days)
-- SELECT cron.schedule(
--     'cleanup-score-calculation-jobs',
--     '0 2 * * 0', -- 2 AM UTC every Sunday
--     $$
--     DELETE FROM score_calculation_jobs 
--     WHERE created_at < NOW() - INTERVAL '90 days';
--     $$
-- );

-- =====================================================
-- MONITORING AND ALERTING
-- =====================================================
-- View for monitoring score calculation performance

CREATE OR REPLACE VIEW score_calculation_monitoring AS
SELECT 
    job_date,
    status,
    users_processed,
    users_successful,
    users_failed,
    ROUND(users_successful::DECIMAL / NULLIF(users_processed, 0) * 100, 2) as success_rate,
    execution_time_ms,
    ROUND(execution_time_ms::DECIMAL / 1000, 2) as execution_time_seconds,
    started_at,
    completed_at,
    error_message,
    CASE 
        WHEN status = 'completed' AND users_failed = 0 THEN 'healthy'
        WHEN status = 'completed' AND users_failed > 0 THEN 'warning'
        WHEN status = 'failed' THEN 'critical'
        WHEN status = 'running' AND started_at < NOW() - INTERVAL '1 hour' THEN 'stuck'
        ELSE 'normal'
    END as health_status
FROM score_calculation_jobs
WHERE job_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY job_date DESC;

-- Function to check for failed or stuck jobs
CREATE OR REPLACE FUNCTION check_score_calculation_health()
RETURNS TABLE (
    alert_type TEXT,
    job_date DATE,
    status TEXT,
    message TEXT
) AS $$
BEGIN
    -- Check for failed jobs in last 7 days
    RETURN QUERY
    SELECT 
        'failed_job'::TEXT,
        scj.job_date,
        scj.status,
        COALESCE(scj.error_message, 'Job failed without error message')::TEXT
    FROM score_calculation_jobs scj
    WHERE scj.job_date >= CURRENT_DATE - INTERVAL '7 days'
      AND scj.status = 'failed';
    
    -- Check for stuck jobs (running > 1 hour)
    RETURN QUERY
    SELECT 
        'stuck_job'::TEXT,
        scj.job_date,
        scj.status,
        ('Job has been running for ' || EXTRACT(EPOCH FROM (NOW() - scj.started_at))/3600 || ' hours')::TEXT
    FROM score_calculation_jobs scj
    WHERE scj.status = 'running'
      AND scj.started_at < NOW() - INTERVAL '1 hour';
    
    -- Check for missing jobs (no job for yesterday)
    RETURN QUERY
    SELECT 
        'missing_job'::TEXT,
        (CURRENT_DATE - INTERVAL '1 day')::DATE,
        'missing'::TEXT,
        'No score calculation job found for yesterday'::TEXT
    WHERE NOT EXISTS (
        SELECT 1 FROM score_calculation_jobs 
        WHERE job_date = CURRENT_DATE - INTERVAL '1 day'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- MANUAL TRIGGER FUNCTIONS
-- =====================================================
-- Function for manual score calculation trigger

CREATE OR REPLACE FUNCTION trigger_manual_score_calculation(
    p_user_id UUID DEFAULT NULL,
    p_target_date DATE DEFAULT CURRENT_DATE
) RETURNS UUID AS $$
DECLARE
    job_id UUID;
    job_type_val TEXT;
BEGIN
    -- Determine job type
    job_type_val := CASE 
        WHEN p_user_id IS NOT NULL THEN 'manual_trigger'
        ELSE 'manual_batch'
    END;
    
    -- Create job record
    INSERT INTO score_calculation_jobs (
        job_date,
        job_type,
        triggered_by
    ) VALUES (
        p_target_date,
        job_type_val,
        'manual_trigger'
    ) RETURNING id INTO job_id;
    
    -- Call the score calculation Edge Function
    PERFORM net.http_post(
        url := current_setting('app.supabase_url') || '/functions/v1/momentum-score-calculator',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.supabase_service_key')
        ),
        body := jsonb_build_object(
            'user_id', p_user_id,
            'target_date', p_target_date::text,
            'calculate_all_users', (p_user_id IS NULL)
        )
    );
    
    RETURN job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function for backfilling historical scores
CREATE OR REPLACE FUNCTION backfill_momentum_scores(
    p_start_date DATE,
    p_end_date DATE DEFAULT CURRENT_DATE
) RETURNS UUID[] AS $$
DECLARE
    job_ids UUID[] := '{}';
    iter_date DATE;
    job_id UUID;
BEGIN
    iter_date := p_start_date;
    
    WHILE iter_date <= p_end_date LOOP
        -- Create backfill job
        INSERT INTO score_calculation_jobs (
            job_date,
            job_type,
            triggered_by
        ) VALUES (
            iter_date,
            'backfill',
            'backfill_operation'
        ) RETURNING id INTO job_id;
        
        job_ids := array_append(job_ids, job_id);
        
        -- Trigger calculation for this date
        PERFORM net.http_post(
            url := current_setting('app.supabase_url') || '/functions/v1/momentum-score-calculator',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || current_setting('app.supabase_service_key')
            ),
            body := jsonb_build_object(
                'calculate_all_users', true,
                'target_date', iter_date::text
            )
        );
        
        iter_date := iter_date + INTERVAL '1 day';
    END LOOP;
    
    RETURN job_ids;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PERMISSIONS AND SECURITY
-- =====================================================
-- Set up RLS policies

ALTER TABLE score_calculation_jobs ENABLE ROW LEVEL SECURITY;

-- Only service role can manage calculation jobs
CREATE POLICY "Service role can manage calculation jobs" ON score_calculation_jobs
    FOR ALL USING (auth.role() = 'service_role');

-- Authenticated users can view job status
CREATE POLICY "Authenticated users can view job status" ON score_calculation_jobs
    FOR SELECT USING (auth.role() = 'authenticated');

-- Grant permissions
GRANT SELECT ON score_calculation_monitoring TO authenticated;
GRANT SELECT ON score_calculation_jobs TO authenticated;
GRANT ALL ON score_calculation_jobs TO service_role;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION trigger_daily_score_calculation TO service_role;
GRANT EXECUTE ON FUNCTION update_score_calculation_job TO service_role;
GRANT EXECUTE ON FUNCTION get_calculation_job_status TO authenticated;
GRANT EXECUTE ON FUNCTION check_score_calculation_health TO service_role;
GRANT EXECUTE ON FUNCTION trigger_manual_score_calculation TO service_role;
GRANT EXECUTE ON FUNCTION backfill_momentum_scores TO service_role;

-- Add trigger for updated_at
CREATE TRIGGER update_score_calculation_jobs_updated_at 
    BEFORE UPDATE ON score_calculation_jobs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- CONFIGURATION SETTINGS
-- =====================================================
-- Add score calculation configuration

INSERT INTO intervention_config (config_key, config_value, description) VALUES
('score_calculation', '{
    "enabled": true,
    "daily_schedule": "0 1 * * *",
    "batch_size": 100,
    "timeout_minutes": 30,
    "retry_attempts": 3,
    "alert_on_failure": true
}', 'Configuration for automated score calculation jobs')

ON CONFLICT (config_key) DO NOTHING; 