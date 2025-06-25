-- Migration: Use app_settings table for content generator URL fallback
-- Date: 2025-06-24 00:05 UTC

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Ensure helper table exists
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_settings (
    key text PRIMARY KEY,
    value text NOT NULL,
    updated_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.app_settings
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- Insert / update the expected setting
INSERT INTO public.app_settings (key, value)
VALUES (
    'daily_content_generator_url',
    'https://okptsizouuanwnpqjfui.functions.supabase.co/daily-content-generator'
)
ON CONFLICT (key) DO UPDATE
SET value  = EXCLUDED.value,
    updated_at = now();

-- ---------------------------------------------------------------------------
-- 2. Patch trigger_daily_content_generation() to read from app_settings
-- ---------------------------------------------------------------------------
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
    -- Create job record (unchanged)
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

    -- ----------------------------------------------------------------------
    -- Resolve Edge Function URL priority:
    --   1. custom GUC (if superuser configured)
    --   2. app_settings table (added by this migration)
    --   3. localhost fallback (dev)
    -- ----------------------------------------------------------------------
    v_function_url := current_setting('app.daily_content_generator_url', true);

    IF v_function_url IS NULL OR v_function_url = '' THEN
        SELECT value INTO v_function_url
        FROM public.app_settings
        WHERE key = 'daily_content_generator_url';
    END IF;

    IF v_function_url IS NULL OR v_function_url = '' THEN
        v_function_url := 'http://localhost:54321/functions/v1/daily-content-generator';
    END IF;

    -- Service-role key
    v_service_key := current_setting('app.service_role_key', true);

    -- ----------------------------------------------------------------------
    -- Perform HTTP request via pg_net (existing logic preserved)
    -- ----------------------------------------------------------------------
    BEGIN
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

COMMIT; 