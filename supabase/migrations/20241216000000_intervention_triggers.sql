-- Migration: Intervention Engine Triggers
-- Purpose: Automatically trigger intervention checks when momentum scores are updated
-- Epic: 1.1 · Momentum Meter
-- Task: T1.1.2.5 · Implement intervention rule engine for notifications
-- 
-- Dependencies:
--   - Requires momentum_meter.sql migration (20241215000000)
--   - Requires momentum-intervention-engine Edge Function
--
-- Created: 2024-12-16
-- Author: BEE Development Team

-- =====================================================
-- INTERVENTION TRIGGER FUNCTION
-- =====================================================
-- Function to call the intervention engine Edge Function
-- when momentum scores are updated

CREATE OR REPLACE FUNCTION trigger_intervention_check()
RETURNS TRIGGER AS $$
DECLARE
    intervention_payload JSONB;
BEGIN
    -- Only trigger for new records or significant state changes
    IF TG_OP = 'INSERT' OR 
       (TG_OP = 'UPDATE' AND OLD.momentum_state != NEW.momentum_state) THEN
        
        -- Prepare payload for Edge Function
        intervention_payload := jsonb_build_object(
            'user_id', NEW.user_id,
            'trigger_type', CASE 
                WHEN TG_OP = 'INSERT' THEN 'new_score'
                ELSE 'state_change'
            END,
            'old_state', CASE WHEN TG_OP = 'UPDATE' THEN OLD.momentum_state ELSE NULL END,
            'new_state', NEW.momentum_state,
            'score', NEW.final_score,
            'date', NEW.score_date
        );

        -- Call intervention engine asynchronously using pg_net
        -- Note: This requires pg_net extension and proper configuration
        PERFORM net.http_post(
            url := current_setting('app.supabase_url') || '/functions/v1/momentum-intervention-engine',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || current_setting('app.supabase_service_key')
            ),
            body := intervention_payload
        );
        
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGER SETUP
-- =====================================================
-- Create trigger on daily_engagement_scores table

DROP TRIGGER IF EXISTS momentum_intervention_trigger ON daily_engagement_scores;

CREATE TRIGGER momentum_intervention_trigger
    AFTER INSERT OR UPDATE OF momentum_state, final_score
    ON daily_engagement_scores
    FOR EACH ROW
    EXECUTE FUNCTION trigger_intervention_check();

-- =====================================================
-- INTERVENTION RATE LIMITING
-- =====================================================
-- Prevent spam notifications by tracking recent interventions

CREATE TABLE IF NOT EXISTS intervention_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    intervention_type TEXT NOT NULL,
    last_triggered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    trigger_count INTEGER NOT NULL DEFAULT 1
);

-- Index for efficient rate limit checks
CREATE INDEX idx_rate_limits_user_type_date 
ON intervention_rate_limits(user_id, intervention_type, last_triggered_at DESC);

-- =====================================================
-- RATE LIMITING FUNCTION
-- =====================================================
-- Function to check if intervention should be rate limited

CREATE OR REPLACE FUNCTION check_intervention_rate_limit(
    p_user_id UUID,
    p_intervention_type TEXT,
    p_max_per_day INTEGER DEFAULT 3,
    p_min_hours_between INTEGER DEFAULT 4
) RETURNS BOOLEAN AS $$
DECLARE
    recent_count INTEGER;
    last_trigger TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Check daily limit
    SELECT COUNT(*), MAX(last_triggered_at)
    INTO recent_count, last_trigger
    FROM intervention_rate_limits
    WHERE user_id = p_user_id
      AND intervention_type = p_intervention_type
      AND last_triggered_at >= CURRENT_DATE;
    
    -- Enforce daily limit
    IF recent_count >= p_max_per_day THEN
        RETURN FALSE;
    END IF;
    
    -- Enforce minimum time between interventions
    IF last_trigger IS NOT NULL AND 
       last_trigger > NOW() - INTERVAL '1 hour' * p_min_hours_between THEN
        RETURN FALSE;
    END IF;
    
    -- Record this intervention attempt
    INSERT INTO intervention_rate_limits (user_id, intervention_type)
    VALUES (p_user_id, p_intervention_type);
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- NOTIFICATION DELIVERY TRACKING
-- =====================================================
-- Enhanced functions for tracking notification delivery

CREATE OR REPLACE FUNCTION mark_notification_sent(
    p_notification_id UUID,
    p_fcm_message_id TEXT DEFAULT NULL,
    p_platform TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    UPDATE momentum_notifications
    SET 
        status = 'sent',
        sent_at = NOW(),
        fcm_message_id = COALESCE(p_fcm_message_id, fcm_message_id),
        platform = COALESCE(p_platform, platform),
        updated_at = NOW()
    WHERE id = p_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION mark_notification_delivered(
    p_fcm_message_id TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE momentum_notifications
    SET 
        status = 'delivered',
        delivered_at = NOW(),
        updated_at = NOW()
    WHERE fcm_message_id = p_fcm_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION mark_notification_opened(
    p_fcm_message_id TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE momentum_notifications
    SET 
        status = 'opened',
        opened_at = NOW(),
        updated_at = NOW()
    WHERE fcm_message_id = p_fcm_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION mark_notification_clicked(
    p_fcm_message_id TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE momentum_notifications
    SET 
        status = 'clicked',
        clicked_at = NOW(),
        updated_at = NOW()
    WHERE fcm_message_id = p_fcm_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- INTERVENTION ANALYTICS VIEWS
-- =====================================================
-- Views for analyzing intervention effectiveness

CREATE OR REPLACE VIEW intervention_analytics AS
SELECT 
    n.user_id,
    n.notification_type,
    n.trigger_date,
    n.status,
    n.sent_at,
    n.delivered_at,
    n.opened_at,
    n.clicked_at,
    
    -- Calculate delivery metrics
    CASE WHEN n.sent_at IS NOT NULL THEN 1 ELSE 0 END as sent_count,
    CASE WHEN n.delivered_at IS NOT NULL THEN 1 ELSE 0 END as delivered_count,
    CASE WHEN n.opened_at IS NOT NULL THEN 1 ELSE 0 END as opened_count,
    CASE WHEN n.clicked_at IS NOT NULL THEN 1 ELSE 0 END as clicked_count,
    
    -- Calculate time to engagement
    EXTRACT(EPOCH FROM (n.opened_at - n.sent_at))/3600 as hours_to_open,
    EXTRACT(EPOCH FROM (n.clicked_at - n.sent_at))/3600 as hours_to_click,
    
    -- Get momentum state after intervention (next day)
    next_day.momentum_state as momentum_state_after,
    next_day.final_score as score_after,
    
    -- Calculate score change
    current_day.final_score as score_before,
    next_day.final_score - current_day.final_score as score_change
    
FROM momentum_notifications n
LEFT JOIN daily_engagement_scores current_day 
    ON n.user_id = current_day.user_id 
    AND n.trigger_date = current_day.score_date
LEFT JOIN daily_engagement_scores next_day 
    ON n.user_id = next_day.user_id 
    AND n.trigger_date + INTERVAL '1 day' = next_day.score_date;

-- Summary view for intervention effectiveness
CREATE OR REPLACE VIEW intervention_effectiveness_summary AS
SELECT 
    notification_type,
    COUNT(*) as total_interventions,
    
    -- Delivery metrics
    SUM(sent_count) as total_sent,
    SUM(delivered_count) as total_delivered,
    SUM(opened_count) as total_opened,
    SUM(clicked_count) as total_clicked,
    
    -- Rates
    ROUND(100.0 * SUM(delivered_count) / NULLIF(SUM(sent_count), 0), 2) as delivery_rate,
    ROUND(100.0 * SUM(opened_count) / NULLIF(SUM(delivered_count), 0), 2) as open_rate,
    ROUND(100.0 * SUM(clicked_count) / NULLIF(SUM(opened_count), 0), 2) as click_rate,
    
    -- Engagement timing
    ROUND(AVG(hours_to_open), 2) as avg_hours_to_open,
    ROUND(AVG(hours_to_click), 2) as avg_hours_to_click,
    
    -- Momentum impact
    COUNT(CASE WHEN score_change > 0 THEN 1 END) as positive_impact_count,
    COUNT(CASE WHEN score_change < 0 THEN 1 END) as negative_impact_count,
    ROUND(AVG(score_change), 2) as avg_score_change,
    
    -- State transitions
    COUNT(CASE WHEN momentum_state_after = 'Rising' THEN 1 END) as resulted_in_rising,
    COUNT(CASE WHEN momentum_state_after = 'Steady' THEN 1 END) as resulted_in_steady,
    COUNT(CASE WHEN momentum_state_after = 'NeedsCare' THEN 1 END) as resulted_in_needs_care
    
FROM intervention_analytics
WHERE trigger_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY notification_type
ORDER BY total_interventions DESC;

-- =====================================================
-- CONFIGURATION SETTINGS
-- =====================================================
-- Store configuration for intervention engine

CREATE TABLE IF NOT EXISTS intervention_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key TEXT UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default configuration
INSERT INTO intervention_config (config_key, config_value, description) VALUES
('rate_limits', '{
    "consecutive_needs_care": {"max_per_day": 1, "min_hours_between": 24},
    "score_drop": {"max_per_day": 2, "min_hours_between": 8},
    "celebration": {"max_per_day": 1, "min_hours_between": 12},
    "consistency_reminder": {"max_per_day": 1, "min_hours_between": 24}
}', 'Rate limiting configuration for different intervention types'),

('thresholds', '{
    "score_drop_threshold": 15,
    "consecutive_needs_care_days": 2,
    "celebration_rising_days": 4,
    "consistency_transition_threshold": 4
}', 'Thresholds for triggering different types of interventions'),

('notification_templates', '{
    "enabled": true,
    "personalization": true,
    "include_emoji": true,
    "max_message_length": 160
}', 'Configuration for notification templates and personalization')

ON CONFLICT (config_key) DO NOTHING;

-- Add trigger for config updates
CREATE TRIGGER update_intervention_config_updated_at 
    BEFORE UPDATE ON intervention_config 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- PERMISSIONS AND SECURITY
-- =====================================================
-- Set up RLS policies for intervention tables

-- Enable RLS on new tables
ALTER TABLE intervention_rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE intervention_config ENABLE ROW LEVEL SECURITY;

-- Rate limits: Users can only see their own data
CREATE POLICY "Users can view own rate limits" ON intervention_rate_limits
    FOR SELECT USING (auth.uid() = user_id);

-- Config: Only service role can modify, authenticated users can read
CREATE POLICY "Authenticated users can read config" ON intervention_config
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Service role can manage config" ON intervention_config
    FOR ALL USING (auth.role() = 'service_role');

-- Grant necessary permissions
GRANT SELECT ON intervention_analytics TO authenticated;
GRANT SELECT ON intervention_effectiveness_summary TO authenticated;
GRANT SELECT ON intervention_rate_limits TO authenticated;
GRANT SELECT ON intervention_config TO authenticated;

-- Service role needs full access for intervention processing
GRANT ALL ON intervention_rate_limits TO service_role;
GRANT ALL ON intervention_config TO service_role; 