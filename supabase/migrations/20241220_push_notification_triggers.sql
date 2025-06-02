-- Migration: Push Notification Triggers
-- Description: Set up database triggers to automatically send push notifications when momentum scores change

-- Create function to trigger push notifications
CREATE OR REPLACE FUNCTION trigger_push_notifications()
RETURNS TRIGGER AS $$
DECLARE
    previous_state TEXT;
    current_state TEXT;
    score_change NUMERIC;
BEGIN
    -- Get the current state from the new record
    current_state := NEW.momentum_state;
    
    -- For updates, get the previous state
    IF TG_OP = 'UPDATE' THEN
        previous_state := OLD.momentum_state;
        score_change := NEW.final_score - OLD.final_score;
    ELSE
        previous_state := NULL;
        score_change := 0;
    END IF;

    -- Only trigger notifications for significant changes or new records
    IF TG_OP = 'INSERT' OR 
       (TG_OP = 'UPDATE' AND (
           previous_state != current_state OR 
           ABS(score_change) > 10
       )) THEN
        
        -- Call the push notification Edge Function asynchronously
        PERFORM
            net.http_post(
                url := 'https://your-project-ref.supabase.co/functions/v1/push-notification-triggers',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || current_setting('app.service_role_key', true)
                ),
                body := jsonb_build_object(
                    'user_id', NEW.user_id,
                    'trigger_type', 'momentum_change',
                    'momentum_data', jsonb_build_object(
                        'current_state', current_state,
                        'previous_state', previous_state,
                        'score', NEW.final_score,
                        'date', NEW.score_date
                    )
                )
            );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on daily_engagement_scores table
DROP TRIGGER IF EXISTS momentum_change_notification_trigger ON daily_engagement_scores;
CREATE TRIGGER momentum_change_notification_trigger
    AFTER INSERT OR UPDATE ON daily_engagement_scores
    FOR EACH ROW
    EXECUTE FUNCTION trigger_push_notifications();

-- Create function for daily batch processing
CREATE OR REPLACE FUNCTION schedule_daily_notifications()
RETURNS void AS $$
BEGIN
    -- Call the push notification Edge Function for batch processing
    PERFORM
        net.http_post(
            url := 'https://your-project-ref.supabase.co/functions/v1/push-notification-triggers',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || current_setting('app.service_role_key', true)
            ),
            body := jsonb_build_object(
                'trigger_type', 'batch_process'
            )
        );
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job for daily notifications (requires pg_cron extension)
-- This will run daily at 9 AM to send motivational notifications
-- Note: pg_cron needs to be enabled in your Supabase project
-- Temporarily commented out for local development
-- SELECT cron.schedule(
--     'daily-motivation-notifications',
--     '0 9 * * *', -- Every day at 9 AM
--     'SELECT schedule_daily_notifications();'
-- );

-- Create indexes for better performance on notification queries
CREATE INDEX IF NOT EXISTS idx_momentum_notifications_user_created 
ON momentum_notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_momentum_notifications_delivery_status 
ON momentum_notifications(status, created_at);

-- Index on user_fcm_tokens table - commented out since table is created in later migration
-- CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active 
-- ON user_fcm_tokens(user_id, is_active) WHERE is_active = true;

-- Add rate limiting table to prevent notification spam
CREATE TABLE IF NOT EXISTS notification_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL,
    rate_limit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    last_sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    count_today INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, notification_type, rate_limit_date)
);

-- Create function to check rate limits
CREATE OR REPLACE FUNCTION check_notification_rate_limit(
    p_user_id UUID,
    p_notification_type TEXT,
    p_max_per_day INTEGER DEFAULT 3
)
RETURNS BOOLEAN AS $$
DECLARE
    current_count INTEGER;
BEGIN
    -- Get today's count for this user and notification type
    SELECT COALESCE(count_today, 0)
    INTO current_count
    FROM notification_rate_limits
    WHERE user_id = p_user_id
    AND notification_type = p_notification_type
    AND rate_limit_date = CURRENT_DATE;
    
    -- Return true if under the limit
    RETURN COALESCE(current_count, 0) < p_max_per_day;
END;
$$ LANGUAGE plpgsql;

-- Create function to update rate limits
CREATE OR REPLACE FUNCTION update_notification_rate_limit(
    p_user_id UUID,
    p_notification_type TEXT
)
RETURNS void AS $$
BEGIN
    INSERT INTO notification_rate_limits (user_id, notification_type, rate_limit_date, last_sent_at, count_today)
    VALUES (p_user_id, p_notification_type, CURRENT_DATE, NOW(), 1)
    ON CONFLICT (user_id, notification_type, rate_limit_date)
    DO UPDATE SET
        count_today = notification_rate_limits.count_today + 1,
        last_sent_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Add RLS policies for notification rate limits
ALTER TABLE notification_rate_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own rate limits" ON notification_rate_limits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage rate limits" ON notification_rate_limits
    FOR ALL USING (auth.role() = 'service_role');

-- Create a view for notification analytics
CREATE OR REPLACE VIEW notification_analytics AS
SELECT 
    DATE(created_at) as notification_date,
    notification_type,
    status,
    COUNT(*) as count,
    COUNT(DISTINCT user_id) as unique_users
FROM momentum_notifications
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at), notification_type, status
ORDER BY notification_date DESC, notification_type;

-- Grant permissions
GRANT SELECT ON notification_analytics TO authenticated;
GRANT ALL ON notification_rate_limits TO service_role;

-- Add comments for documentation
COMMENT ON FUNCTION trigger_push_notifications() IS 'Automatically triggers push notifications when momentum scores change significantly';
COMMENT ON FUNCTION schedule_daily_notifications() IS 'Schedules daily batch processing of motivational notifications';
COMMENT ON FUNCTION check_notification_rate_limit(UUID, TEXT, INTEGER) IS 'Checks if a user has exceeded their daily notification limit for a specific type';
COMMENT ON FUNCTION update_notification_rate_limit(UUID, TEXT) IS 'Updates the notification rate limit counter for a user and notification type';
COMMENT ON VIEW notification_analytics IS 'Provides analytics on notification delivery and engagement over the last 30 days'; 