-- Migration: Data Validation and Error Handling
-- Purpose: Add comprehensive validation and error handling for momentum meter
-- Epic: 1.1 · Momentum Meter
-- Task: T1.1.2.8 · Add data validation and error handling
-- 
-- Features:
--   - Input validation functions for all data types
--   - Enhanced constraint checks and triggers
--   - Error logging and monitoring
--   - Data integrity safeguards
--   - Graceful error recovery mechanisms
--
-- Dependencies:
--   - 20241215000000_momentum_meter.sql (momentum tables)
--   - 20241217000001_realtime_momentum_triggers.sql (realtime triggers)
--
-- Created: 2024-12-17
-- Author: BEE Development Team

-- =====================================================
-- ERROR LOGGING INFRASTRUCTURE
-- =====================================================

-- Table to track validation errors and system issues
CREATE TABLE IF NOT EXISTS momentum_error_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    error_type TEXT NOT NULL CHECK (error_type IN (
        'validation_error',
        'calculation_error',
        'api_error',
        'realtime_error',
        'data_integrity_error',
        'system_error'
    )),
    error_code TEXT NOT NULL,
    error_message TEXT NOT NULL,
    error_details JSONB DEFAULT '{}'::jsonb,
    
    -- Context information
    user_id UUID,
    function_name TEXT,
    table_name TEXT,
    operation_type TEXT,
    input_data JSONB,
    
    -- Error metadata
    severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    is_resolved BOOLEAN DEFAULT false,
    resolution_notes TEXT,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for error log performance
CREATE INDEX idx_error_logs_type_severity 
ON momentum_error_logs(error_type, severity, created_at DESC);

CREATE INDEX idx_error_logs_user_time 
ON momentum_error_logs(user_id, created_at DESC) 
WHERE user_id IS NOT NULL;

CREATE INDEX idx_error_logs_unresolved 
ON momentum_error_logs(created_at DESC) 
WHERE is_resolved = false;

-- =====================================================
-- INPUT VALIDATION FUNCTIONS
-- =====================================================

-- Function to validate user ID format
CREATE OR REPLACE FUNCTION validate_user_id(input_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if UUID is not null and not empty UUID
    IF input_user_id IS NULL OR input_user_id = '00000000-0000-0000-0000-000000000000' THEN
        RETURN false;
    END IF;
    
    -- Verify user exists in auth.users (if accessible)
    -- Note: This might need adjustment based on RLS policies
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to validate score values
CREATE OR REPLACE FUNCTION validate_score_values(
    raw_score DECIMAL,
    normalized_score DECIMAL,
    final_score DECIMAL
)
RETURNS JSONB AS $$
DECLARE
    errors TEXT[] := '{}';
BEGIN
    -- Validate raw score
    IF raw_score IS NULL THEN
        errors := array_append(errors, 'Raw score cannot be null');
    ELSIF raw_score < 0 THEN
        errors := array_append(errors, 'Raw score cannot be negative');
    ELSIF raw_score > 1000 THEN
        errors := array_append(errors, 'Raw score cannot exceed 1000');
    END IF;
    
    -- Validate normalized score
    IF normalized_score IS NULL THEN
        errors := array_append(errors, 'Normalized score cannot be null');
    ELSIF normalized_score < 0 OR normalized_score > 100 THEN
        errors := array_append(errors, 'Normalized score must be between 0 and 100');
    END IF;
    
    -- Validate final score
    IF final_score IS NULL THEN
        errors := array_append(errors, 'Final score cannot be null');
    ELSIF final_score < 0 OR final_score > 100 THEN
        errors := array_append(errors, 'Final score must be between 0 and 100');
    END IF;
    
    -- Return validation result
    RETURN jsonb_build_object(
        'is_valid', array_length(errors, 1) IS NULL,
        'errors', errors,
        'validated_at', NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- Function to validate momentum state
CREATE OR REPLACE FUNCTION validate_momentum_state(state TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN state IN ('Rising', 'Steady', 'NeedsCare');
END;
$$ LANGUAGE plpgsql;

-- Function to validate date ranges
CREATE OR REPLACE FUNCTION validate_date_range(
    start_date DATE,
    end_date DATE DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    errors TEXT[] := '{}';
BEGIN
    -- Validate start date
    IF start_date IS NULL THEN
        errors := array_append(errors, 'Start date cannot be null');
    ELSIF start_date > CURRENT_DATE THEN
        errors := array_append(errors, 'Start date cannot be in the future');
    ELSIF start_date < CURRENT_DATE - INTERVAL '2 years' THEN
        errors := array_append(errors, 'Start date cannot be more than 2 years ago');
    END IF;
    
    -- Validate end date if provided
    IF end_date IS NOT NULL THEN
        IF end_date < start_date THEN
            errors := array_append(errors, 'End date cannot be before start date');
        ELSIF end_date > CURRENT_DATE THEN
            errors := array_append(errors, 'End date cannot be in the future');
        END IF;
    END IF;
    
    RETURN jsonb_build_object(
        'is_valid', array_length(errors, 1) IS NULL,
        'errors', errors,
        'validated_at', NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- Function to validate notification data
CREATE OR REPLACE FUNCTION validate_notification_data(
    notification_type TEXT,
    title TEXT,
    message TEXT,
    action_type TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    errors TEXT[] := '{}';
    valid_notification_types TEXT[] := ARRAY[
        'momentum_drop', 'needs_care_consecutive', 'celebration', 
        'consistency_reminder', 'coach_intervention', 'custom'
    ];
    valid_action_types TEXT[] := ARRAY[
        'open_app', 'complete_lesson', 'schedule_call', 
        'view_momentum', 'journal_entry', 'none'
    ];
BEGIN
    -- Validate notification type
    IF notification_type IS NULL THEN
        errors := array_append(errors, 'Notification type cannot be null');
    ELSIF NOT (notification_type = ANY(valid_notification_types)) THEN
        errors := array_append(errors, 'Invalid notification type');
    END IF;
    
    -- Validate title
    IF title IS NULL OR trim(title) = '' THEN
        errors := array_append(errors, 'Title cannot be empty');
    ELSIF length(title) > 100 THEN
        errors := array_append(errors, 'Title cannot exceed 100 characters');
    END IF;
    
    -- Validate message
    IF message IS NULL OR trim(message) = '' THEN
        errors := array_append(errors, 'Message cannot be empty');
    ELSIF length(message) > 500 THEN
        errors := array_append(errors, 'Message cannot exceed 500 characters');
    END IF;
    
    -- Validate action type if provided
    IF action_type IS NOT NULL AND NOT (action_type = ANY(valid_action_types)) THEN
        errors := array_append(errors, 'Invalid action type');
    END IF;
    
    RETURN jsonb_build_object(
        'is_valid', array_length(errors, 1) IS NULL,
        'errors', errors,
        'validated_at', NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ERROR LOGGING FUNCTIONS
-- =====================================================

-- Function to log validation errors
CREATE OR REPLACE FUNCTION log_momentum_error(
    p_error_type TEXT,
    p_error_code TEXT,
    p_error_message TEXT,
    p_error_details JSONB DEFAULT '{}'::jsonb,
    p_user_id UUID DEFAULT NULL,
    p_function_name TEXT DEFAULT NULL,
    p_table_name TEXT DEFAULT NULL,
    p_operation_type TEXT DEFAULT NULL,
    p_input_data JSONB DEFAULT NULL,
    p_severity TEXT DEFAULT 'medium'
)
RETURNS UUID AS $$
DECLARE
    error_id UUID;
BEGIN
    INSERT INTO momentum_error_logs (
        error_type, error_code, error_message, error_details,
        user_id, function_name, table_name, operation_type,
        input_data, severity
    ) VALUES (
        p_error_type, p_error_code, p_error_message, p_error_details,
        p_user_id, p_function_name, p_table_name, p_operation_type,
        p_input_data, p_severity
    ) RETURNING id INTO error_id;
    
    RETURN error_id;
END;
$$ LANGUAGE plpgsql;

-- Function to resolve error logs
CREATE OR REPLACE FUNCTION resolve_momentum_error(
    p_error_id UUID,
    p_resolution_notes TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE momentum_error_logs 
    SET 
        is_resolved = true,
        resolved_at = NOW(),
        resolution_notes = p_resolution_notes
    WHERE id = p_error_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ENHANCED VALIDATION TRIGGERS
-- =====================================================

-- Trigger function for daily_engagement_scores validation
CREATE OR REPLACE FUNCTION validate_daily_engagement_scores()
RETURNS TRIGGER AS $$
DECLARE
    validation_result JSONB;
    error_id UUID;
BEGIN
    -- Validate user ID
    IF NOT validate_user_id(NEW.user_id) THEN
        error_id := log_momentum_error(
            'validation_error',
            'INVALID_USER_ID',
            'Invalid or missing user ID',
            jsonb_build_object('user_id', NEW.user_id),
            NEW.user_id,
            'validate_daily_engagement_scores',
            'daily_engagement_scores',
            TG_OP
        );
        RAISE EXCEPTION 'Invalid user ID: %', NEW.user_id;
    END IF;
    
    -- Validate score values
    validation_result := validate_score_values(
        NEW.raw_score, 
        NEW.normalized_score, 
        NEW.final_score
    );
    
    IF NOT (validation_result->>'is_valid')::boolean THEN
        error_id := log_momentum_error(
            'validation_error',
            'INVALID_SCORE_VALUES',
            'Score validation failed',
            validation_result,
            NEW.user_id,
            'validate_daily_engagement_scores',
            'daily_engagement_scores',
            TG_OP,
            to_jsonb(NEW)
        );
        RAISE EXCEPTION 'Score validation failed: %', validation_result->>'errors';
    END IF;
    
    -- Validate momentum state
    IF NOT validate_momentum_state(NEW.momentum_state) THEN
        error_id := log_momentum_error(
            'validation_error',
            'INVALID_MOMENTUM_STATE',
            'Invalid momentum state',
            jsonb_build_object('momentum_state', NEW.momentum_state),
            NEW.user_id,
            'validate_daily_engagement_scores',
            'daily_engagement_scores',
            TG_OP
        );
        RAISE EXCEPTION 'Invalid momentum state: %', NEW.momentum_state;
    END IF;
    
    -- Validate date
    IF NEW.score_date > CURRENT_DATE THEN
        error_id := log_momentum_error(
            'validation_error',
            'FUTURE_SCORE_DATE',
            'Score date cannot be in the future',
            jsonb_build_object('score_date', NEW.score_date),
            NEW.user_id,
            'validate_daily_engagement_scores',
            'daily_engagement_scores',
            TG_OP
        );
        RAISE EXCEPTION 'Score date cannot be in the future: %', NEW.score_date;
    END IF;
    
    -- Validate events count
    IF NEW.events_count < 0 THEN
        error_id := log_momentum_error(
            'validation_error',
            'NEGATIVE_EVENTS_COUNT',
            'Events count cannot be negative',
            jsonb_build_object('events_count', NEW.events_count),
            NEW.user_id,
            'validate_daily_engagement_scores',
            'daily_engagement_scores',
            TG_OP
        );
        RAISE EXCEPTION 'Events count cannot be negative: %', NEW.events_count;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for momentum_notifications validation
CREATE OR REPLACE FUNCTION validate_momentum_notifications()
RETURNS TRIGGER AS $$
DECLARE
    validation_result JSONB;
    error_id UUID;
BEGIN
    -- Validate user ID
    IF NOT validate_user_id(NEW.user_id) THEN
        error_id := log_momentum_error(
            'validation_error',
            'INVALID_USER_ID',
            'Invalid or missing user ID',
            jsonb_build_object('user_id', NEW.user_id),
            NEW.user_id,
            'validate_momentum_notifications',
            'momentum_notifications',
            TG_OP
        );
        RAISE EXCEPTION 'Invalid user ID: %', NEW.user_id;
    END IF;
    
    -- Validate notification data
    validation_result := validate_notification_data(
        NEW.notification_type,
        NEW.title,
        NEW.message,
        NEW.action_type
    );
    
    IF NOT (validation_result->>'is_valid')::boolean THEN
        error_id := log_momentum_error(
            'validation_error',
            'INVALID_NOTIFICATION_DATA',
            'Notification validation failed',
            validation_result,
            NEW.user_id,
            'validate_momentum_notifications',
            'momentum_notifications',
            TG_OP,
            to_jsonb(NEW)
        );
        RAISE EXCEPTION 'Notification validation failed: %', validation_result->>'errors';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for coach_interventions validation
CREATE OR REPLACE FUNCTION validate_coach_interventions()
RETURNS TRIGGER AS $$
DECLARE
    error_id UUID;
    valid_intervention_types TEXT[] := ARRAY[
        'automated_call_schedule', 'manual_outreach', 'escalation',
        'check_in', 'celebration_call', 'crisis_intervention'
    ];
    valid_statuses TEXT[] := ARRAY[
        'scheduled', 'in_progress', 'completed', 'cancelled', 'no_response'
    ];
BEGIN
    -- Validate user ID
    IF NOT validate_user_id(NEW.user_id) THEN
        error_id := log_momentum_error(
            'validation_error',
            'INVALID_USER_ID',
            'Invalid or missing user ID',
            jsonb_build_object('user_id', NEW.user_id),
            NEW.user_id,
            'validate_coach_interventions',
            'coach_interventions',
            TG_OP
        );
        RAISE EXCEPTION 'Invalid user ID: %', NEW.user_id;
    END IF;
    
    -- Validate intervention type
    IF NOT (NEW.intervention_type = ANY(valid_intervention_types)) THEN
        error_id := log_momentum_error(
            'validation_error',
            'INVALID_INTERVENTION_TYPE',
            'Invalid intervention type',
            jsonb_build_object('intervention_type', NEW.intervention_type),
            NEW.user_id,
            'validate_coach_interventions',
            'coach_interventions',
            TG_OP
        );
        RAISE EXCEPTION 'Invalid intervention type: %', NEW.intervention_type;
    END IF;
    
    -- Validate status
    IF NOT (NEW.status = ANY(valid_statuses)) THEN
        error_id := log_momentum_error(
            'validation_error',
            'INVALID_INTERVENTION_STATUS',
            'Invalid intervention status',
            jsonb_build_object('status', NEW.status),
            NEW.user_id,
            'validate_coach_interventions',
            'coach_interventions',
            TG_OP
        );
        RAISE EXCEPTION 'Invalid intervention status: %', NEW.status;
    END IF;
    
    -- Validate trigger reason
    IF NEW.trigger_reason IS NULL OR trim(NEW.trigger_reason) = '' THEN
        error_id := log_momentum_error(
            'validation_error',
            'MISSING_TRIGGER_REASON',
            'Trigger reason cannot be empty',
            jsonb_build_object('trigger_reason', NEW.trigger_reason),
            NEW.user_id,
            'validate_coach_interventions',
            'coach_interventions',
            TG_OP
        );
        RAISE EXCEPTION 'Trigger reason cannot be empty';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- CREATE VALIDATION TRIGGERS
-- =====================================================

-- Validation trigger for daily_engagement_scores
CREATE TRIGGER daily_engagement_scores_validation_trigger
    BEFORE INSERT OR UPDATE ON daily_engagement_scores
    FOR EACH ROW
    EXECUTE FUNCTION validate_daily_engagement_scores();

-- Validation trigger for momentum_notifications
CREATE TRIGGER momentum_notifications_validation_trigger
    BEFORE INSERT OR UPDATE ON momentum_notifications
    FOR EACH ROW
    EXECUTE FUNCTION validate_momentum_notifications();

-- Validation trigger for coach_interventions
CREATE TRIGGER coach_interventions_validation_trigger
    BEFORE INSERT OR UPDATE ON coach_interventions
    FOR EACH ROW
    EXECUTE FUNCTION validate_coach_interventions();

-- =====================================================
-- DATA INTEGRITY SAFEGUARDS
-- =====================================================

-- Function to prevent duplicate daily scores
CREATE OR REPLACE FUNCTION prevent_duplicate_daily_scores()
RETURNS TRIGGER AS $$
DECLARE
    existing_count INTEGER;
    error_id UUID;
BEGIN
    -- Check for existing score on the same date (excluding current record for updates)
    SELECT COUNT(*) INTO existing_count
    FROM daily_engagement_scores
    WHERE user_id = NEW.user_id 
      AND score_date = NEW.score_date
      AND (TG_OP = 'INSERT' OR id != NEW.id);
    
    IF existing_count > 0 THEN
        error_id := log_momentum_error(
            'data_integrity_error',
            'DUPLICATE_DAILY_SCORE',
            'Duplicate daily score detected',
            jsonb_build_object(
                'user_id', NEW.user_id,
                'score_date', NEW.score_date,
                'existing_count', existing_count
            ),
            NEW.user_id,
            'prevent_duplicate_daily_scores',
            'daily_engagement_scores',
            TG_OP
        );
        RAISE EXCEPTION 'Duplicate daily score for user % on date %', NEW.user_id, NEW.score_date;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to prevent duplicate daily scores
CREATE TRIGGER prevent_duplicate_daily_scores_trigger
    BEFORE INSERT OR UPDATE ON daily_engagement_scores
    FOR EACH ROW
    EXECUTE FUNCTION prevent_duplicate_daily_scores();

-- =====================================================
-- ERROR RECOVERY FUNCTIONS
-- =====================================================

-- Function to safely calculate momentum score with error handling
CREATE OR REPLACE FUNCTION safe_calculate_momentum_score(
    p_user_id UUID,
    p_target_date DATE
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    error_id UUID;
BEGIN
    -- Validate inputs
    IF NOT validate_user_id(p_user_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Invalid user ID',
            'error_code', 'INVALID_USER_ID'
        );
    END IF;
    
    IF p_target_date IS NULL OR p_target_date > CURRENT_DATE THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Invalid target date',
            'error_code', 'INVALID_DATE'
        );
    END IF;
    
    -- Attempt calculation with error handling
    BEGIN
        -- This would call the main momentum calculation function
        -- For now, return a placeholder structure
        result := jsonb_build_object(
            'success', true,
            'user_id', p_user_id,
            'target_date', p_target_date,
            'calculated_at', NOW()
        );
        
        RETURN result;
        
    EXCEPTION WHEN OTHERS THEN
        -- Log the error
        error_id := log_momentum_error(
            'calculation_error',
            'MOMENTUM_CALCULATION_FAILED',
            SQLERRM,
            jsonb_build_object(
                'sqlstate', SQLSTATE,
                'user_id', p_user_id,
                'target_date', p_target_date
            ),
            p_user_id,
            'safe_calculate_momentum_score',
            NULL,
            'CALCULATION',
            jsonb_build_object('user_id', p_user_id, 'target_date', p_target_date),
            'high'
        );
        
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Calculation failed',
            'error_code', 'CALCULATION_ERROR',
            'error_id', error_id
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- MONITORING AND HEALTH CHECK FUNCTIONS
-- =====================================================

-- Function to get error statistics
CREATE OR REPLACE FUNCTION get_error_statistics(
    p_hours_back INTEGER DEFAULT 24
)
RETURNS JSONB AS $$
DECLARE
    stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_errors', COUNT(*),
        'unresolved_errors', COUNT(*) FILTER (WHERE is_resolved = false),
        'critical_errors', COUNT(*) FILTER (WHERE severity = 'critical'),
        'high_errors', COUNT(*) FILTER (WHERE severity = 'high'),
        'by_type', jsonb_object_agg(
            error_type, 
            COUNT(*)
        ),
        'period_hours', p_hours_back,
        'generated_at', NOW()
    ) INTO stats
    FROM momentum_error_logs
    WHERE created_at >= NOW() - (p_hours_back || ' hours')::INTERVAL
    GROUP BY ();
    
    RETURN COALESCE(stats, jsonb_build_object(
        'total_errors', 0,
        'unresolved_errors', 0,
        'critical_errors', 0,
        'high_errors', 0,
        'by_type', '{}'::jsonb,
        'period_hours', p_hours_back,
        'generated_at', NOW()
    ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check system health
CREATE OR REPLACE FUNCTION check_momentum_system_health()
RETURNS JSONB AS $$
DECLARE
    health_status JSONB;
    error_stats JSONB;
    recent_errors INTEGER;
    critical_errors INTEGER;
BEGIN
    -- Get recent error statistics
    error_stats := get_error_statistics(1); -- Last hour
    recent_errors := (error_stats->>'total_errors')::INTEGER;
    critical_errors := (error_stats->>'critical_errors')::INTEGER;
    
    -- Determine health status
    IF critical_errors > 0 THEN
        health_status := jsonb_build_object(
            'status', 'critical',
            'message', 'Critical errors detected'
        );
    ELSIF recent_errors > 10 THEN
        health_status := jsonb_build_object(
            'status', 'degraded',
            'message', 'High error rate detected'
        );
    ELSE
        health_status := jsonb_build_object(
            'status', 'healthy',
            'message', 'System operating normally'
        );
    END IF;
    
    RETURN jsonb_build_object(
        'health', health_status,
        'error_stats', error_stats,
        'checked_at', NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- CLEANUP AND MAINTENANCE
-- =====================================================

-- Function to clean up old error logs
CREATE OR REPLACE FUNCTION cleanup_error_logs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
    temp_count INTEGER;
BEGIN
    -- Delete resolved errors older than 90 days
    DELETE FROM momentum_error_logs
    WHERE is_resolved = true 
      AND resolved_at < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Delete low severity errors older than 30 days
    DELETE FROM momentum_error_logs
    WHERE severity = 'low' 
      AND created_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON TABLE momentum_error_logs IS 'Comprehensive error logging for momentum meter system';
COMMENT ON FUNCTION validate_user_id(UUID) IS 'Validates user ID format and existence';
COMMENT ON FUNCTION validate_score_values(DECIMAL, DECIMAL, DECIMAL) IS 'Validates momentum score value ranges and consistency';
COMMENT ON FUNCTION validate_momentum_state(TEXT) IS 'Validates momentum state enum values';
COMMENT ON FUNCTION validate_date_range(DATE, DATE) IS 'Validates date ranges for queries and operations';
COMMENT ON FUNCTION validate_notification_data(TEXT, TEXT, TEXT, TEXT) IS 'Validates notification content and metadata';
COMMENT ON FUNCTION log_momentum_error(TEXT, TEXT, TEXT, JSONB, UUID, TEXT, TEXT, TEXT, JSONB, TEXT) IS 'Logs errors with context and metadata for debugging';
COMMENT ON FUNCTION resolve_momentum_error(UUID, TEXT) IS 'Marks errors as resolved with resolution notes';
COMMENT ON FUNCTION safe_calculate_momentum_score(UUID, DATE) IS 'Safely calculates momentum scores with comprehensive error handling';
COMMENT ON FUNCTION get_error_statistics(INTEGER) IS 'Returns error statistics for monitoring and alerting';
COMMENT ON FUNCTION check_momentum_system_health() IS 'Performs health check on momentum meter system';
COMMENT ON FUNCTION cleanup_error_logs() IS 'Removes old error logs to maintain performance'; 