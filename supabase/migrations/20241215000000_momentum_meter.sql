-- Migration: Momentum Meter Database Schema
-- Purpose: Create tables for momentum scores, notifications, and coach interventions
-- Epic: 1.1 · Momentum Meter
-- Task: T1.1.2.2 · Create database schema for momentum scores and notifications
-- 
-- Dependencies:
--   - Requires auth.users table (provided by Supabase Auth)
--   - Requires engagement_events table (from Epic 2.1)
--   - Requires uuid-ossp extension for UUID generation
--
-- References:
--   - momentum-calculation-algorithm.md: Algorithm specifications
--   - prd-momentum-meter.md: Functional requirements
--   - tasks-momentum-meter.md: Task T1.1.2.2 requirements
--
-- Created: 2024-12-15
-- Author: BEE Development Team

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- DAILY ENGAGEMENT SCORES TABLE
-- =====================================================
-- Stores daily momentum scores for each user
-- Supports historical tracking and trend analysis

CREATE TABLE daily_engagement_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    score_date DATE NOT NULL,
    
    -- Algorithm Results
    raw_score DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    normalized_score DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    final_score DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    momentum_state TEXT NOT NULL CHECK (momentum_state IN ('Rising', 'Steady', 'NeedsCare')),
    
    -- Breakdown Analysis (JSONB for flexibility)
    breakdown JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Algorithm Metadata
    algorithm_version TEXT NOT NULL DEFAULT 'v1.0',
    events_count INTEGER NOT NULL DEFAULT 0,
    calculation_metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Audit Fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance indexes for daily_engagement_scores
CREATE UNIQUE INDEX idx_daily_scores_user_date 
ON daily_engagement_scores(user_id, score_date);

CREATE INDEX idx_daily_scores_date_state 
ON daily_engagement_scores(score_date, momentum_state);

CREATE INDEX idx_daily_scores_user_recent 
ON daily_engagement_scores(user_id, score_date DESC);

-- GIN index for breakdown JSONB queries
CREATE INDEX idx_daily_scores_breakdown 
ON daily_engagement_scores USING GIN(breakdown);

-- Add constraints for data validation
ALTER TABLE daily_engagement_scores 
ADD CONSTRAINT check_score_ranges 
CHECK (
    raw_score >= 0 AND 
    normalized_score >= 0 AND normalized_score <= 100 AND
    final_score >= 0 AND final_score <= 100
);

ALTER TABLE daily_engagement_scores 
ADD CONSTRAINT check_score_date_not_future 
CHECK (score_date <= CURRENT_DATE);

-- =====================================================
-- MOMENTUM NOTIFICATIONS TABLE
-- =====================================================
-- Stores momentum-based notifications and interventions
-- Supports automated coach outreach and user engagement

CREATE TABLE momentum_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Notification Details
    notification_type TEXT NOT NULL CHECK (notification_type IN (
        'momentum_drop',
        'needs_care_consecutive',
        'celebration',
        'consistency_reminder',
        'coach_intervention',
        'custom'
    )),
    
    -- Trigger Information
    trigger_date DATE NOT NULL,
    trigger_score DECIMAL(5,2),
    trigger_state TEXT CHECK (trigger_state IN ('Rising', 'Steady', 'NeedsCare')),
    trigger_metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Notification Content
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    action_type TEXT CHECK (action_type IN (
        'open_app',
        'complete_lesson',
        'schedule_call',
        'view_momentum',
        'journal_entry',
        'none'
    )),
    action_data JSONB DEFAULT '{}'::jsonb,
    
    -- Delivery Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',
        'sent',
        'delivered',
        'opened',
        'clicked',
        'failed'
    )),
    
    -- Delivery Tracking
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    clicked_at TIMESTAMP WITH TIME ZONE,
    
    -- Platform Information
    platform TEXT CHECK (platform IN ('ios', 'android', 'web')),
    fcm_token TEXT,
    fcm_message_id TEXT,
    
    -- Audit Fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance indexes for momentum_notifications
CREATE INDEX idx_notifications_user_date 
ON momentum_notifications(user_id, trigger_date DESC);

CREATE INDEX idx_notifications_status 
ON momentum_notifications(status, created_at);

CREATE INDEX idx_notifications_type_date 
ON momentum_notifications(notification_type, trigger_date);

CREATE INDEX idx_notifications_fcm_tracking 
ON momentum_notifications(fcm_message_id) WHERE fcm_message_id IS NOT NULL;

-- GIN indexes for JSONB fields
CREATE INDEX idx_notifications_trigger_metadata 
ON momentum_notifications USING GIN(trigger_metadata);

CREATE INDEX idx_notifications_action_data 
ON momentum_notifications USING GIN(action_data);

-- =====================================================
-- COACH INTERVENTIONS TABLE
-- =====================================================
-- Tracks automated and manual coach interventions
-- Supports intervention effectiveness analysis

CREATE TABLE coach_interventions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Intervention Details
    intervention_type TEXT NOT NULL CHECK (intervention_type IN (
        'automated_call_schedule',
        'manual_outreach',
        'escalation',
        'check_in',
        'celebration_call',
        'crisis_intervention'
    )),
    
    -- Trigger Information
    trigger_date DATE NOT NULL,
    trigger_reason TEXT NOT NULL,
    trigger_momentum_state TEXT CHECK (trigger_momentum_state IN ('Rising', 'Steady', 'NeedsCare')),
    trigger_score DECIMAL(5,2),
    trigger_pattern JSONB DEFAULT '{}'::jsonb,
    
    -- Intervention Execution
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN (
        'scheduled',
        'in_progress',
        'completed',
        'cancelled',
        'no_response'
    )),
    
    -- Coach Assignment
    assigned_coach_id UUID REFERENCES auth.users(id),
    assigned_at TIMESTAMP WITH TIME ZONE,
    
    -- Scheduling Information
    scheduled_date DATE,
    scheduled_time TIME,
    actual_date DATE,
    actual_time TIME,
    duration_minutes INTEGER,
    
    -- Intervention Content
    intervention_notes TEXT,
    outcome_summary TEXT,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    
    -- Effectiveness Tracking
    pre_intervention_score DECIMAL(5,2),
    post_intervention_score DECIMAL(5,2),
    effectiveness_rating INTEGER CHECK (effectiveness_rating BETWEEN 1 AND 5),
    
    -- Audit Fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Performance indexes for coach_interventions
CREATE INDEX idx_interventions_user_date 
ON coach_interventions(user_id, trigger_date DESC);

CREATE INDEX idx_interventions_coach_status 
ON coach_interventions(assigned_coach_id, status);

CREATE INDEX idx_interventions_scheduled 
ON coach_interventions(scheduled_date, scheduled_time) 
WHERE status IN ('scheduled', 'in_progress');

CREATE INDEX idx_interventions_type_outcome 
ON coach_interventions(intervention_type, status, completed_at);

-- GIN index for trigger pattern analysis
CREATE INDEX idx_interventions_trigger_pattern 
ON coach_interventions USING GIN(trigger_pattern);

-- =====================================================
-- MOMENTUM CALCULATION JOBS TABLE
-- =====================================================
-- Tracks batch momentum calculation jobs
-- Supports monitoring and error handling

CREATE TABLE momentum_calculation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Job Details
    job_type TEXT NOT NULL CHECK (job_type IN (
        'daily_batch',
        'backfill',
        'user_specific',
        'algorithm_migration'
    )),
    
    -- Execution Information
    calculation_date DATE NOT NULL,
    algorithm_version TEXT NOT NULL DEFAULT 'v1.0',
    
    -- Scope
    user_ids UUID[] DEFAULT NULL, -- NULL means all users
    total_users INTEGER NOT NULL DEFAULT 0,
    processed_users INTEGER NOT NULL DEFAULT 0,
    failed_users INTEGER NOT NULL DEFAULT 0,
    
    -- Status Tracking
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',
        'running',
        'completed',
        'failed',
        'cancelled'
    )),
    
    -- Performance Metrics
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    average_calculation_time_ms DECIMAL(8,2),
    
    -- Error Handling
    error_message TEXT,
    error_details JSONB,
    retry_count INTEGER DEFAULT 0,
    
    -- Audit Fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance indexes for momentum_calculation_jobs
CREATE INDEX idx_calculation_jobs_date_status 
ON momentum_calculation_jobs(calculation_date, status);

CREATE INDEX idx_calculation_jobs_status_created 
ON momentum_calculation_jobs(status, created_at);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
-- Ensure HIPAA compliance and data isolation

-- Enable RLS on all tables
ALTER TABLE daily_engagement_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE momentum_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_interventions ENABLE ROW LEVEL SECURITY;
ALTER TABLE momentum_calculation_jobs ENABLE ROW LEVEL SECURITY;

-- Daily Engagement Scores Policies
CREATE POLICY "Users can view own scores" 
ON daily_engagement_scores 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all scores" 
ON daily_engagement_scores 
FOR ALL 
TO service_role 
USING (true);

-- Momentum Notifications Policies
CREATE POLICY "Users can view own notifications" 
ON momentum_notifications 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notification status" 
ON momentum_notifications 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role can manage all notifications" 
ON momentum_notifications 
FOR ALL 
TO service_role 
USING (true);

-- Coach Interventions Policies
CREATE POLICY "Users can view own interventions" 
ON coach_interventions 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Coaches can view assigned interventions" 
ON coach_interventions 
FOR SELECT 
USING (auth.uid() = assigned_coach_id);

CREATE POLICY "Coaches can update assigned interventions" 
ON coach_interventions 
FOR UPDATE 
USING (auth.uid() = assigned_coach_id)
WITH CHECK (auth.uid() = assigned_coach_id);

CREATE POLICY "Service role can manage all interventions" 
ON coach_interventions 
FOR ALL 
TO service_role 
USING (true);

-- Calculation Jobs Policies (Service role only)
CREATE POLICY "Service role can manage calculation jobs" 
ON momentum_calculation_jobs 
FOR ALL 
TO service_role 
USING (true);

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get user's recent momentum trend
CREATE OR REPLACE FUNCTION get_momentum_trend(
    p_user_id UUID,
    p_days INTEGER DEFAULT 7
) RETURNS TABLE (
    score_date DATE,
    final_score DECIMAL(5,2),
    momentum_state TEXT
) 
LANGUAGE SQL
SECURITY DEFINER
AS $$
    SELECT 
        score_date,
        final_score,
        momentum_state
    FROM daily_engagement_scores
    WHERE user_id = p_user_id
        AND score_date >= CURRENT_DATE - INTERVAL '1 day' * p_days
    ORDER BY score_date DESC;
$$;

-- Function to check if user needs intervention
CREATE OR REPLACE FUNCTION check_intervention_needed(
    p_user_id UUID
) RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM daily_engagement_scores
        WHERE user_id = p_user_id
            AND score_date >= CURRENT_DATE - INTERVAL '2 days'
            AND momentum_state = 'NeedsCare'
        GROUP BY user_id
        HAVING COUNT(*) >= 2
    );
$$;

-- Function to get momentum breakdown for date range
CREATE OR REPLACE FUNCTION get_momentum_breakdown(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
) RETURNS TABLE (
    score_date DATE,
    app_engagement JSONB,
    learning_progress JSONB,
    daily_checkins JSONB,
    consistency JSONB
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
    SELECT 
        score_date,
        breakdown->'app_engagement' as app_engagement,
        breakdown->'learning_progress' as learning_progress,
        breakdown->'daily_checkins' as daily_checkins,
        breakdown->'consistency' as consistency
    FROM daily_engagement_scores
    WHERE user_id = p_user_id
        AND score_date BETWEEN p_start_date AND p_end_date
    ORDER BY score_date DESC;
$$;

-- =====================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to all tables
CREATE TRIGGER update_daily_scores_updated_at 
    BEFORE UPDATE ON daily_engagement_scores 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notifications_updated_at 
    BEFORE UPDATE ON momentum_notifications 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interventions_updated_at 
    BEFORE UPDATE ON coach_interventions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_calculation_jobs_updated_at 
    BEFORE UPDATE ON momentum_calculation_jobs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SAMPLE DATA VIEWS
-- =====================================================

-- View for momentum dashboard
CREATE VIEW momentum_dashboard AS
SELECT 
    des.user_id,
    des.score_date,
    des.final_score,
    des.momentum_state,
    des.breakdown,
    COUNT(mn.id) as pending_notifications,
    COUNT(ci.id) as active_interventions
FROM daily_engagement_scores des
LEFT JOIN momentum_notifications mn ON (
    mn.user_id = des.user_id 
    AND mn.status = 'pending'
)
LEFT JOIN coach_interventions ci ON (
    ci.user_id = des.user_id 
    AND ci.status IN ('scheduled', 'in_progress')
)
WHERE des.score_date = CURRENT_DATE
GROUP BY des.user_id, des.score_date, des.final_score, des.momentum_state, des.breakdown;

-- View for coach intervention queue
CREATE VIEW coach_intervention_queue AS
SELECT 
    ci.*,
    des.final_score as current_momentum_score,
    des.momentum_state as current_momentum_state,
    u.email as user_email
FROM coach_interventions ci
JOIN daily_engagement_scores des ON (
    des.user_id = ci.user_id 
    AND des.score_date = CURRENT_DATE
)
JOIN auth.users u ON u.id = ci.user_id
WHERE ci.status IN ('scheduled', 'in_progress')
ORDER BY ci.scheduled_date, ci.scheduled_time;

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON TABLE daily_engagement_scores IS 'Stores daily momentum scores calculated from engagement events using exponential decay algorithm';
COMMENT ON TABLE momentum_notifications IS 'Tracks momentum-based notifications and push message delivery status';
COMMENT ON TABLE coach_interventions IS 'Manages automated and manual coach interventions triggered by momentum patterns';
COMMENT ON TABLE momentum_calculation_jobs IS 'Monitors batch momentum calculation jobs and performance metrics';

COMMENT ON COLUMN daily_engagement_scores.breakdown IS 'JSONB containing app_engagement, learning_progress, daily_checkins, and consistency scores';
COMMENT ON COLUMN momentum_notifications.trigger_metadata IS 'JSONB containing details about what triggered this notification';
COMMENT ON COLUMN coach_interventions.trigger_pattern IS 'JSONB containing momentum pattern that triggered intervention';

-- =====================================================
-- MIGRATION COMPLETION
-- =====================================================

-- Insert migration record
INSERT INTO public.schema_migrations (version, applied_at) 
VALUES ('20241215000000_momentum_meter', NOW())
ON CONFLICT (version) DO NOTHING; 