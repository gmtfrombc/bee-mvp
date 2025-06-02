-- Migration: Real-time Momentum Triggers
-- Purpose: Enable real-time updates for momentum scores and interventions
-- Epic: 1.1 · Momentum Meter
-- Task: T1.1.2.7 · Implement real-time triggers for momentum updates
-- 
-- Features:
--   - Real-time subscriptions for momentum score updates
--   - WebSocket event publishing for client synchronization
--   - Real-time intervention notifications
--   - Client-side caching support with invalidation triggers
--
-- Dependencies:
--   - 20241215000000_momentum_meter.sql (momentum tables)
--   - Supabase Realtime extension
--
-- Created: 2024-12-17
-- Author: BEE Development Team

-- =====================================================
-- ENABLE REALTIME FOR MOMENTUM TABLES
-- =====================================================

-- Enable realtime for daily_engagement_scores table
ALTER TABLE daily_engagement_scores REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE daily_engagement_scores;

-- Enable realtime for momentum_notifications table
ALTER TABLE momentum_notifications REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE momentum_notifications;

-- Enable realtime for coach_interventions table
ALTER TABLE coach_interventions REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE coach_interventions;

-- =====================================================
-- REALTIME EVENT PUBLISHING FUNCTIONS
-- =====================================================

-- Function to publish momentum state changes to realtime channel
CREATE OR REPLACE FUNCTION publish_momentum_update()
RETURNS TRIGGER AS $$
DECLARE
    payload JSONB;
    channel_name TEXT;
BEGIN
    -- Determine the operation type
    IF TG_OP = 'INSERT' THEN
        payload := jsonb_build_object(
            'event_type', 'momentum_score_created',
            'user_id', NEW.user_id,
            'score_date', NEW.score_date,
            'momentum_state', NEW.momentum_state,
            'final_score', NEW.final_score,
            'previous_state', NULL,
            'timestamp', NOW()
        );
    ELSIF TG_OP = 'UPDATE' THEN
        payload := jsonb_build_object(
            'event_type', 'momentum_score_updated',
            'user_id', NEW.user_id,
            'score_date', NEW.score_date,
            'momentum_state', NEW.momentum_state,
            'final_score', NEW.final_score,
            'previous_state', OLD.momentum_state,
            'state_changed', (NEW.momentum_state != OLD.momentum_state),
            'timestamp', NOW()
        );
    END IF;

    -- Create user-specific channel name
    channel_name := 'momentum_updates:' || NEW.user_id::TEXT;

    -- Publish to realtime channel
    PERFORM pg_notify(channel_name, payload::TEXT);

    -- Also publish to general momentum channel for admin dashboards
    PERFORM pg_notify('momentum_updates:all', payload::TEXT);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Function to publish intervention notifications
CREATE OR REPLACE FUNCTION publish_intervention_notification()
RETURNS TRIGGER AS $$
DECLARE
    payload JSONB;
    channel_name TEXT;
BEGIN
    -- Build notification payload
    IF TG_OP = 'INSERT' THEN
        payload := jsonb_build_object(
            'event_type', 'intervention_created',
            'intervention_id', NEW.id,
            'user_id', NEW.user_id,
            'intervention_type', NEW.intervention_type,
            'trigger_reason', NEW.trigger_reason,
            'status', NEW.status,
            'scheduled_date', NEW.scheduled_date,
            'timestamp', NOW()
        );
    ELSIF TG_OP = 'UPDATE' THEN
        payload := jsonb_build_object(
            'event_type', 'intervention_updated',
            'intervention_id', NEW.id,
            'user_id', NEW.user_id,
            'intervention_type', NEW.intervention_type,
            'status', NEW.status,
            'previous_status', OLD.status,
            'status_changed', (NEW.status != OLD.status),
            'timestamp', NOW()
        );
    END IF;

    -- Create user-specific channel
    channel_name := 'interventions:' || NEW.user_id::TEXT;
    PERFORM pg_notify(channel_name, payload::TEXT);

    -- Publish to coach dashboard channel
    PERFORM pg_notify('interventions:coaches', payload::TEXT);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Function to publish push notification events
CREATE OR REPLACE FUNCTION publish_push_notification()
RETURNS TRIGGER AS $$
DECLARE
    payload JSONB;
    channel_name TEXT;
BEGIN
    -- Only publish for user-facing notifications
    IF NEW.notification_type IN ('momentum_drop', 'needs_care_consecutive', 'celebration', 'consistency_reminder') THEN
        payload := jsonb_build_object(
            'event_type', 'push_notification',
            'notification_id', NEW.id,
            'user_id', NEW.user_id,
            'notification_type', NEW.notification_type,
            'title', NEW.title,
            'message', NEW.message,
            'action_type', NEW.action_type,
            'action_data', NEW.action_data,
            'status', NEW.status,
            'timestamp', NOW()
        );

        -- Create user-specific channel
        channel_name := 'notifications:' || NEW.user_id::TEXT;
        PERFORM pg_notify(channel_name, payload::TEXT);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- REALTIME TRIGGERS
-- =====================================================

-- Trigger for momentum score changes
CREATE TRIGGER momentum_score_realtime_trigger
    AFTER INSERT OR UPDATE ON daily_engagement_scores
    FOR EACH ROW
    EXECUTE FUNCTION publish_momentum_update();

-- Trigger for intervention notifications
CREATE TRIGGER intervention_realtime_trigger
    AFTER INSERT OR UPDATE ON coach_interventions
    FOR EACH ROW
    EXECUTE FUNCTION publish_intervention_notification();

-- Trigger for push notifications
CREATE TRIGGER notification_realtime_trigger
    AFTER INSERT OR UPDATE ON momentum_notifications
    FOR EACH ROW
    EXECUTE FUNCTION publish_push_notification();

-- =====================================================
-- CLIENT CACHE INVALIDATION FUNCTIONS
-- =====================================================

-- Function to handle cache invalidation for momentum data
CREATE OR REPLACE FUNCTION invalidate_momentum_cache()
RETURNS TRIGGER AS $$
DECLARE
    cache_keys TEXT[];
    key TEXT;
BEGIN
    -- Build cache invalidation keys
    cache_keys := ARRAY[
        'momentum:current:' || NEW.user_id::TEXT,
        'momentum:history:' || NEW.user_id::TEXT,
        'momentum:trend:' || NEW.user_id::TEXT,
        'momentum:breakdown:' || NEW.user_id::TEXT || ':' || NEW.score_date::TEXT
    ];

    -- Publish cache invalidation events
    FOREACH key IN ARRAY cache_keys
    LOOP
        PERFORM pg_notify('cache_invalidation', jsonb_build_object(
            'cache_key', key,
            'user_id', NEW.user_id,
            'timestamp', NOW()
        )::TEXT);
    END LOOP;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Cache invalidation trigger
CREATE TRIGGER momentum_cache_invalidation_trigger
    AFTER INSERT OR UPDATE OR DELETE ON daily_engagement_scores
    FOR EACH ROW
    EXECUTE FUNCTION invalidate_momentum_cache();

-- =====================================================
-- REALTIME SUBSCRIPTION HELPERS
-- =====================================================

-- Function to get user's current momentum state for real-time sync
CREATE OR REPLACE FUNCTION get_realtime_momentum_state(target_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    current_score daily_engagement_scores%ROWTYPE;
    result JSONB;
BEGIN
    -- Get the most recent momentum score
    SELECT * INTO current_score
    FROM daily_engagement_scores
    WHERE user_id = target_user_id
    ORDER BY score_date DESC
    LIMIT 1;

    IF current_score.id IS NULL THEN
        -- No momentum data available
        result := jsonb_build_object(
            'user_id', target_user_id,
            'has_data', false,
            'message', 'No momentum data available',
            'timestamp', NOW()
        );
    ELSE
        -- Build current state response
        result := jsonb_build_object(
            'user_id', target_user_id,
            'has_data', true,
            'score_date', current_score.score_date,
            'momentum_state', current_score.momentum_state,
            'final_score', current_score.final_score,
            'events_count', current_score.events_count,
            'breakdown', current_score.breakdown,
            'last_updated', current_score.updated_at,
            'timestamp', NOW()
        );
    END IF;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending interventions for real-time sync
CREATE OR REPLACE FUNCTION get_realtime_interventions(target_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    interventions JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'intervention_type', intervention_type,
            'status', status,
            'scheduled_date', scheduled_date,
            'trigger_reason', trigger_reason,
            'created_at', created_at
        )
    ) INTO interventions
    FROM coach_interventions
    WHERE user_id = target_user_id
      AND status IN ('scheduled', 'in_progress')
    ORDER BY scheduled_date ASC;

    RETURN jsonb_build_object(
        'user_id', target_user_id,
        'interventions', COALESCE(interventions, '[]'::jsonb),
        'timestamp', NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- REALTIME CHANNEL MANAGEMENT
-- =====================================================

-- Function to subscribe user to their momentum channels
CREATE OR REPLACE FUNCTION subscribe_to_momentum_channels(target_user_id UUID)
RETURNS JSONB AS $$
BEGIN
    RETURN jsonb_build_object(
        'channels', jsonb_build_array(
            'momentum_updates:' || target_user_id::TEXT,
            'interventions:' || target_user_id::TEXT,
            'notifications:' || target_user_id::TEXT,
            'cache_invalidation'
        ),
        'user_id', target_user_id,
        'timestamp', NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PERFORMANCE MONITORING
-- =====================================================

-- Table to track realtime event performance
CREATE TABLE IF NOT EXISTS realtime_event_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    channel_name TEXT NOT NULL,
    user_id UUID,
    payload_size INTEGER,
    processing_time_ms INTEGER,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for performance analysis
CREATE INDEX idx_realtime_metrics_type_time 
ON realtime_event_metrics(event_type, created_at DESC);

CREATE INDEX idx_realtime_metrics_user_time 
ON realtime_event_metrics(user_id, created_at DESC) 
WHERE user_id IS NOT NULL;

-- Function to log realtime event metrics
CREATE OR REPLACE FUNCTION log_realtime_event(
    p_event_type TEXT,
    p_channel_name TEXT,
    p_user_id UUID DEFAULT NULL,
    p_payload_size INTEGER DEFAULT NULL,
    p_processing_time_ms INTEGER DEFAULT NULL,
    p_success BOOLEAN DEFAULT true,
    p_error_message TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO realtime_event_metrics (
        event_type,
        channel_name,
        user_id,
        payload_size,
        processing_time_ms,
        success,
        error_message
    ) VALUES (
        p_event_type,
        p_channel_name,
        p_user_id,
        p_payload_size,
        p_processing_time_ms,
        p_success,
        p_error_message
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROW LEVEL SECURITY FOR REALTIME
-- =====================================================

-- Enable RLS for realtime tables
ALTER TABLE daily_engagement_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE momentum_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_interventions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view own momentum scores" ON daily_engagement_scores;
DROP POLICY IF EXISTS "Users can view own notifications" ON momentum_notifications;  
DROP POLICY IF EXISTS "Users can view own interventions" ON coach_interventions;
DROP POLICY IF EXISTS "Coaches can view all interventions" ON coach_interventions;

-- Policy for users to see their own momentum data
CREATE POLICY "Users can view own momentum scores" ON daily_engagement_scores
    FOR SELECT USING (auth.uid() = user_id);

-- Policy for users to see their own notifications
CREATE POLICY "Users can view own notifications" ON momentum_notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Policy for users to see their own interventions
CREATE POLICY "Users can view own interventions" ON coach_interventions
    FOR SELECT USING (auth.uid() = user_id);

-- Policy for coaches to see all interventions (assuming coach role)
CREATE POLICY "Coaches can view all interventions" ON coach_interventions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' = 'coach'
        )
    );

-- =====================================================
-- CLEANUP AND MAINTENANCE
-- =====================================================

-- Function to clean up old realtime metrics
CREATE OR REPLACE FUNCTION cleanup_realtime_metrics()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM realtime_event_metrics
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup job (requires pg_cron extension)
-- SELECT cron.schedule('cleanup-realtime-metrics', '0 2 * * *', 'SELECT cleanup_realtime_metrics();');

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION publish_momentum_update() IS 'Publishes momentum score changes to realtime channels for client synchronization';
COMMENT ON FUNCTION publish_intervention_notification() IS 'Publishes intervention updates to realtime channels for coaches and users';
COMMENT ON FUNCTION publish_push_notification() IS 'Publishes push notification events to user-specific realtime channels';
COMMENT ON FUNCTION invalidate_momentum_cache() IS 'Invalidates client-side cache when momentum data changes';
COMMENT ON FUNCTION get_realtime_momentum_state(UUID) IS 'Returns current momentum state for real-time synchronization';
COMMENT ON FUNCTION get_realtime_interventions(UUID) IS 'Returns pending interventions for real-time updates';
COMMENT ON FUNCTION subscribe_to_momentum_channels(UUID) IS 'Returns list of realtime channels for user subscription';
COMMENT ON FUNCTION log_realtime_event(TEXT, TEXT, UUID, INTEGER, INTEGER, BOOLEAN, TEXT) IS 'Logs realtime event metrics for performance monitoring';
COMMENT ON FUNCTION cleanup_realtime_metrics() IS 'Removes old realtime event metrics to maintain performance';

COMMENT ON TABLE realtime_event_metrics IS 'Tracks performance metrics for realtime events and notifications'; 