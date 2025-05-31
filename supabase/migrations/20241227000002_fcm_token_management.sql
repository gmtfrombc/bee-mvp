-- Migration: FCM Token Management
-- Description: Create tables and functions for managing FCM tokens
-- Epic: 1.1 - Momentum Meter
-- Task: T1.1.4.2 - FCM Token Management
-- Date: 2024-12-27

-- =====================================================
-- FCM Token Storage Tables
-- =====================================================

-- Create table for storing FCM tokens per user/device
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_platform TEXT NOT NULL CHECK (device_platform IN ('android', 'iOS', 'web', 'macos', 'windows', 'linux')),
    device_info JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Ensure one active token per user per platform
    UNIQUE(user_id, device_platform, fcm_token)
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active ON user_fcm_tokens(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_platform ON user_fcm_tokens(device_platform);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_updated_at ON user_fcm_tokens(updated_at);

-- =====================================================
-- RLS Policies for FCM Tokens
-- =====================================================

-- Enable RLS
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own tokens
CREATE POLICY "Users can manage their own FCM tokens" ON user_fcm_tokens
    FOR ALL USING (auth.uid() = user_id);

-- Policy: Service role can access all tokens (for admin/cleanup operations)
CREATE POLICY "Service role can access all FCM tokens" ON user_fcm_tokens
    FOR ALL USING (auth.role() = 'service_role');

-- =====================================================
-- FCM Token Management Functions
-- =====================================================

-- Function to upsert FCM token (handles device switching)
CREATE OR REPLACE FUNCTION upsert_fcm_token(
    p_user_id UUID,
    p_fcm_token TEXT,
    p_device_platform TEXT,
    p_device_info JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_token_id UUID;
BEGIN
    -- Deactivate any existing tokens for this user on this platform
    UPDATE user_fcm_tokens 
    SET is_active = false, updated_at = now()
    WHERE user_id = p_user_id 
      AND device_platform = p_device_platform
      AND fcm_token != p_fcm_token
      AND is_active = true;

    -- Insert or update the token
    INSERT INTO user_fcm_tokens (
        user_id, 
        fcm_token, 
        device_platform, 
        device_info,
        is_active,
        updated_at
    )
    VALUES (
        p_user_id,
        p_fcm_token,
        p_device_platform,
        p_device_info,
        true,
        now()
    )
    ON CONFLICT (user_id, device_platform, fcm_token)
    DO UPDATE SET
        is_active = true,
        device_info = p_device_info,
        updated_at = now()
    RETURNING id INTO v_token_id;

    RETURN v_token_id;
END;
$$;

-- Function to get active FCM tokens for a user
CREATE OR REPLACE FUNCTION get_user_fcm_tokens(p_user_id UUID)
RETURNS TABLE (
    token_id UUID,
    fcm_token TEXT,
    device_platform TEXT,
    device_info JSONB,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        id,
        user_fcm_tokens.fcm_token,
        user_fcm_tokens.device_platform,
        user_fcm_tokens.device_info,
        user_fcm_tokens.updated_at
    FROM user_fcm_tokens
    WHERE user_id = p_user_id
      AND is_active = true
    ORDER BY updated_at DESC;
END;
$$;

-- Function to cleanup expired FCM tokens
CREATE OR REPLACE FUNCTION cleanup_expired_fcm_tokens(
    p_expiry_days INTEGER DEFAULT 30
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    -- Delete tokens older than specified days
    DELETE FROM user_fcm_tokens
    WHERE updated_at < (now() - INTERVAL '1 day' * p_expiry_days);
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$;

-- Function to deactivate FCM token
CREATE OR REPLACE FUNCTION deactivate_fcm_token(
    p_user_id UUID,
    p_fcm_token TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE user_fcm_tokens 
    SET is_active = false, updated_at = now()
    WHERE user_id = p_user_id 
      AND fcm_token = p_fcm_token
      AND is_active = true;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN v_updated_count > 0;
END;
$$;

-- =====================================================
-- Notification Tracking Tables
-- =====================================================

-- Table for tracking notification delivery and engagement
CREATE TABLE IF NOT EXISTS notification_delivery_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token_id UUID REFERENCES user_fcm_tokens(id) ON DELETE SET NULL,
    notification_type TEXT NOT NULL CHECK (
        notification_type IN (
            'momentum_drop', 
            'momentum_celebration', 
            'coach_intervention', 
            'engagement_reminder',
            'daily_update'
        )
    ),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    delivery_status TEXT DEFAULT 'pending' CHECK (
        delivery_status IN ('pending', 'sent', 'delivered', 'failed', 'clicked')
    ),
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for notification tracking
CREATE INDEX IF NOT EXISTS idx_notification_delivery_user_id ON notification_delivery_log(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_delivery_type ON notification_delivery_log(notification_type);
CREATE INDEX IF NOT EXISTS idx_notification_delivery_status ON notification_delivery_log(delivery_status);
CREATE INDEX IF NOT EXISTS idx_notification_delivery_sent_at ON notification_delivery_log(sent_at);

-- Enable RLS for notification log
ALTER TABLE notification_delivery_log ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own notification logs
CREATE POLICY "Users can view their own notification logs" ON notification_delivery_log
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Service role can access all notification logs
CREATE POLICY "Service role can access all notification logs" ON notification_delivery_log
    FOR ALL USING (auth.role() = 'service_role');

-- =====================================================
-- Updated At Triggers
-- =====================================================

-- Function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user_fcm_tokens
CREATE TRIGGER trigger_user_fcm_tokens_updated_at
    BEFORE UPDATE ON user_fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Grant Permissions
-- =====================================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON user_fcm_tokens TO authenticated;
GRANT SELECT ON notification_delivery_log TO authenticated;

-- Grant permissions to service role for cleanup operations
GRANT ALL ON user_fcm_tokens TO service_role;
GRANT ALL ON notification_delivery_log TO service_role;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE user_fcm_tokens IS 'Stores FCM tokens for user devices to enable push notifications';
COMMENT ON TABLE notification_delivery_log IS 'Tracks notification delivery status and user engagement';

COMMENT ON FUNCTION upsert_fcm_token IS 'Safely upserts FCM tokens handling device switches';
COMMENT ON FUNCTION get_user_fcm_tokens IS 'Gets all active FCM tokens for a user';
COMMENT ON FUNCTION cleanup_expired_fcm_tokens IS 'Removes FCM tokens older than specified days';
COMMENT ON FUNCTION deactivate_fcm_token IS 'Marks an FCM token as inactive';

-- =====================================================
-- Migration Complete
-- =====================================================

-- Log completion
DO \$completion\$
BEGIN
    RAISE NOTICE 'FCM Token Management migration completed successfully';
    RAISE NOTICE 'Created tables: user_fcm_tokens, notification_delivery_log';
    RAISE NOTICE 'Created functions: upsert_fcm_token, get_user_fcm_tokens, cleanup_expired_fcm_tokens, deactivate_fcm_token';
END \$completion\$; 