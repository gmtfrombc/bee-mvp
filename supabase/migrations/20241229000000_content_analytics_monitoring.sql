-- Migration: Content Analytics and Monitoring System
-- Epic 1.3: Today Feed (AI Daily Brief) - Task T1.3.1.10
-- Created: 2024-12-29

-- Enable RLS
ALTER DATABASE postgres SET row_security = on;

-- Create content_monitoring_alerts table
CREATE TABLE IF NOT EXISTS public.content_monitoring_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type TEXT NOT NULL CHECK (alert_type IN ('low_engagement', 'quality_issue', 'load_time_violation', 'user_feedback')),
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    content_id INTEGER REFERENCES public.daily_feed_content(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    details JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Create indexes for monitoring alerts
CREATE INDEX IF NOT EXISTS idx_content_monitoring_alerts_type ON public.content_monitoring_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_content_monitoring_alerts_severity ON public.content_monitoring_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_content_monitoring_alerts_resolved ON public.content_monitoring_alerts(resolved);
CREATE INDEX IF NOT EXISTS idx_content_monitoring_alerts_created ON public.content_monitoring_alerts(created_at DESC);

-- Create content_performance_metrics table for detailed tracking
CREATE TABLE IF NOT EXISTS public.content_performance_metrics (
    id SERIAL PRIMARY KEY,
    content_id INTEGER NOT NULL REFERENCES public.daily_feed_content(id) ON DELETE CASCADE,
    metric_date DATE NOT NULL DEFAULT CURRENT_DATE,
    performance_score NUMERIC(3,2) DEFAULT 0 CHECK (performance_score >= 0.0 AND performance_score <= 1.0),
    quality_rating NUMERIC(2,1) DEFAULT 0 CHECK (quality_rating >= 0.0 AND quality_rating <= 5.0),
    user_preference_score NUMERIC(3,2) DEFAULT 0 CHECK (user_preference_score >= 0.0 AND user_preference_score <= 1.0),
    momentum_points_awarded INTEGER DEFAULT 0,
    load_time_avg NUMERIC(4,2) DEFAULT 0, -- in seconds
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(content_id, metric_date)
);

-- Create indexes for performance metrics
CREATE INDEX IF NOT EXISTS idx_content_performance_metrics_content ON public.content_performance_metrics(content_id);
CREATE INDEX IF NOT EXISTS idx_content_performance_metrics_date ON public.content_performance_metrics(metric_date DESC);
CREATE INDEX IF NOT EXISTS idx_content_performance_metrics_score ON public.content_performance_metrics(performance_score DESC);

-- Create daily_analytics_summary table for aggregated daily metrics
CREATE TABLE IF NOT EXISTS public.daily_analytics_summary (
    id SERIAL PRIMARY KEY,
    summary_date DATE NOT NULL UNIQUE DEFAULT CURRENT_DATE,
    total_content_published INTEGER DEFAULT 0,
    total_user_interactions INTEGER DEFAULT 0,
    unique_users_engaged INTEGER DEFAULT 0,
    overall_engagement_rate NUMERIC(3,2) DEFAULT 0 CHECK (overall_engagement_rate >= 0.0 AND overall_engagement_rate <= 1.0),
    average_session_duration NUMERIC(5,2) DEFAULT 0,
    momentum_points_awarded INTEGER DEFAULT 0,
    content_quality_avg NUMERIC(3,2) DEFAULT 0,
    load_time_avg NUMERIC(4,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for daily analytics
CREATE INDEX IF NOT EXISTS idx_daily_analytics_summary_date ON public.daily_analytics_summary(summary_date DESC);

-- Create user_engagement_summary table for user-level analytics
CREATE TABLE IF NOT EXISTS public.user_engagement_summary (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    summary_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_interactions INTEGER DEFAULT 0,
    consecutive_days_engaged INTEGER DEFAULT 0,
    favorite_topics TEXT[] DEFAULT '{}',
    average_session_duration NUMERIC(5,2) DEFAULT 0,
    momentum_points_earned INTEGER DEFAULT 0,
    engagement_level TEXT DEFAULT 'low' CHECK (engagement_level IN ('low', 'medium', 'high')),
    last_interaction TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, summary_date)
);

-- Create indexes for user engagement
CREATE INDEX IF NOT EXISTS idx_user_engagement_summary_user ON public.user_engagement_summary(user_id);
CREATE INDEX IF NOT EXISTS idx_user_engagement_summary_date ON public.user_engagement_summary(summary_date DESC);
CREATE INDEX IF NOT EXISTS idx_user_engagement_summary_level ON public.user_engagement_summary(engagement_level);

-- Enable Row Level Security (RLS)
ALTER TABLE public.content_monitoring_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_analytics_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_engagement_summary ENABLE ROW LEVEL SECURITY;

-- RLS Policies for content_monitoring_alerts (admin access only)
CREATE POLICY "Admins can manage monitoring alerts" ON public.content_monitoring_alerts
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- RLS Policies for content_performance_metrics (publicly readable)
CREATE POLICY "Performance metrics are publicly readable" ON public.content_performance_metrics
    FOR SELECT USING (true);

-- RLS Policies for daily_analytics_summary (publicly readable)
CREATE POLICY "Analytics summary is publicly readable" ON public.daily_analytics_summary
    FOR SELECT USING (true);

-- RLS Policies for user_engagement_summary (users can see their own)
CREATE POLICY "Users can view own engagement summary" ON public.user_engagement_summary
    FOR ALL USING (auth.uid() = user_id);

-- Function to update daily analytics summary
CREATE OR REPLACE FUNCTION update_daily_analytics_summary()
RETURNS TRIGGER AS $$
BEGIN
    -- Update or insert daily analytics summary
    INSERT INTO public.daily_analytics_summary (
        summary_date,
        total_content_published,
        total_user_interactions,
        unique_users_engaged,
        overall_engagement_rate,
        average_session_duration,
        content_quality_avg,
        updated_at
    )
    SELECT 
        CURRENT_DATE,
        COUNT(DISTINCT dc.id) as total_content_published,
        COUNT(uci.id) as total_user_interactions,
        COUNT(DISTINCT uci.user_id) as unique_users_engaged,
        COALESCE(AVG(ca.engagement_rate), 0) as overall_engagement_rate,
        COALESCE(AVG(ca.avg_session_duration), 0) as average_session_duration,
        COALESCE(AVG(dc.ai_confidence_score), 0) as content_quality_avg,
        NOW()
    FROM public.daily_feed_content dc
    LEFT JOIN public.content_analytics ca ON dc.id = ca.content_id
    LEFT JOIN public.user_content_interactions uci ON dc.id = uci.content_id
    WHERE dc.content_date = CURRENT_DATE
    ON CONFLICT (summary_date) 
    DO UPDATE SET
        total_content_published = EXCLUDED.total_content_published,
        total_user_interactions = EXCLUDED.total_user_interactions,
        unique_users_engaged = EXCLUDED.unique_users_engaged,
        overall_engagement_rate = EXCLUDED.overall_engagement_rate,
        average_session_duration = EXCLUDED.average_session_duration,
        content_quality_avg = EXCLUDED.content_quality_avg,
        updated_at = EXCLUDED.updated_at;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update user engagement summary
CREATE OR REPLACE FUNCTION update_user_engagement_summary()
RETURNS TRIGGER AS $$
BEGIN
    -- Update or insert user engagement summary for today
    INSERT INTO public.user_engagement_summary (
        user_id,
        summary_date,
        total_interactions,
        average_session_duration,
        last_interaction,
        updated_at
    )
    SELECT 
        NEW.user_id,
        CURRENT_DATE,
        COUNT(*) as total_interactions,
        COALESCE(AVG(session_duration), 0) as average_session_duration,
        MAX(interaction_timestamp) as last_interaction,
        NOW()
    FROM public.user_content_interactions 
    WHERE user_id = NEW.user_id 
    AND DATE(interaction_timestamp) = CURRENT_DATE
    GROUP BY user_id
    ON CONFLICT (user_id, summary_date) 
    DO UPDATE SET
        total_interactions = EXCLUDED.total_interactions,
        average_session_duration = EXCLUDED.average_session_duration,
        last_interaction = EXCLUDED.last_interaction,
        updated_at = EXCLUDED.updated_at;

    -- Update engagement level based on total interactions
    UPDATE public.user_engagement_summary 
    SET engagement_level = CASE 
        WHEN total_interactions >= 20 THEN 'high'
        WHEN total_interactions >= 10 THEN 'medium'
        ELSE 'low'
    END
    WHERE user_id = NEW.user_id AND summary_date = CURRENT_DATE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to create monitoring alerts based on performance thresholds
CREATE OR REPLACE FUNCTION check_content_performance_alerts()
RETURNS TRIGGER AS $$
BEGIN
    -- Check for low engagement alert
    IF (NEW.engagement_rate < 0.3) THEN
        INSERT INTO public.content_monitoring_alerts (
            alert_type,
            severity,
            content_id,
            message,
            details
        ) VALUES (
            'low_engagement',
            CASE 
                WHEN NEW.engagement_rate < 0.1 THEN 'high'
                WHEN NEW.engagement_rate < 0.2 THEN 'medium'
                ELSE 'low'
            END,
            NEW.content_id,
            'Content engagement rate is below threshold',
            jsonb_build_object(
                'engagement_rate', NEW.engagement_rate,
                'threshold', 0.3,
                'content_date', (SELECT content_date FROM public.daily_feed_content WHERE id = NEW.content_id)
            )
        );
    END IF;

    -- Check for quality issues
    IF EXISTS (
        SELECT 1 FROM public.daily_feed_content 
        WHERE id = NEW.content_id AND ai_confidence_score < 0.7
    ) THEN
        INSERT INTO public.content_monitoring_alerts (
            alert_type,
            severity,
            content_id,
            message,
            details
        ) VALUES (
            'quality_issue',
            'medium',
            NEW.content_id,
            'Content AI confidence score is below quality threshold',
            jsonb_build_object(
                'ai_confidence_score', (SELECT ai_confidence_score FROM public.daily_feed_content WHERE id = NEW.content_id),
                'threshold', 0.7
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to update analytics summaries
CREATE TRIGGER trigger_update_daily_analytics_summary
    AFTER INSERT OR UPDATE ON public.content_analytics
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_analytics_summary();

CREATE TRIGGER trigger_update_user_engagement_summary
    AFTER INSERT OR UPDATE ON public.user_content_interactions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_engagement_summary();

CREATE TRIGGER trigger_check_content_performance_alerts
    AFTER INSERT OR UPDATE ON public.content_analytics
    FOR EACH ROW
    EXECUTE FUNCTION check_content_performance_alerts();

-- Create enhanced analytics views

-- View for comprehensive content analytics
CREATE OR REPLACE VIEW public.content_analytics_dashboard AS
SELECT 
    dc.id,
    dc.content_date,
    dc.title,
    dc.topic_category,
    dc.ai_confidence_score,
    COALESCE(ca.total_views, 0) as total_views,
    COALESCE(ca.total_clicks, 0) as total_clicks,
    COALESCE(ca.total_shares, 0) as total_shares,
    COALESCE(ca.total_bookmarks, 0) as total_bookmarks,
    COALESCE(ca.unique_viewers, 0) as unique_viewers,
    COALESCE(ca.engagement_rate, 0) as engagement_rate,
    COALESCE(ca.avg_session_duration, 0) as avg_session_duration,
    COALESCE(cpm.performance_score, 0) as performance_score,
    COALESCE(cpm.quality_rating, 0) as quality_rating,
    COALESCE(cpm.momentum_points_awarded, 0) as momentum_points_awarded,
    COALESCE(cpm.load_time_avg, 0) as load_time_avg,
    dc.created_at,
    ca.updated_at as analytics_updated_at
FROM public.daily_feed_content dc
LEFT JOIN public.content_analytics ca ON dc.id = ca.content_id
LEFT JOIN public.content_performance_metrics cpm ON dc.id = cpm.content_id AND cpm.metric_date = dc.content_date
ORDER BY dc.content_date DESC;

-- View for topic performance analysis
CREATE OR REPLACE VIEW public.topic_performance_analysis AS
SELECT 
    topic_category,
    COUNT(*) as total_content_pieces,
    SUM(COALESCE(ca.total_views, 0)) as total_views,
    SUM(COALESCE(ca.total_clicks, 0) + COALESCE(ca.total_shares, 0) + COALESCE(ca.total_bookmarks, 0)) as total_interactions,
    AVG(COALESCE(ca.engagement_rate, 0)) as average_engagement_rate,
    AVG(COALESCE(ca.avg_session_duration, 0)) as average_session_duration,
    AVG(COALESCE(dc.ai_confidence_score, 0)) as content_quality_average,
    SUM(COALESCE(cpm.momentum_points_awarded, 0)) as momentum_points_generated
FROM public.daily_feed_content dc
LEFT JOIN public.content_analytics ca ON dc.id = ca.content_id
LEFT JOIN public.content_performance_metrics cpm ON dc.id = cpm.content_id
WHERE dc.content_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY topic_category
ORDER BY average_engagement_rate DESC;

-- View for engagement trends
CREATE OR REPLACE VIEW public.engagement_trends AS
SELECT 
    dc.content_date as date,
    SUM(COALESCE(ca.total_views, 0)) as total_views,
    SUM(COALESCE(ca.total_clicks, 0)) as total_clicks,
    SUM(COALESCE(ca.total_shares, 0)) as total_shares,
    SUM(COALESCE(ca.total_bookmarks, 0)) as total_bookmarks,
    SUM(COALESCE(ca.unique_viewers, 0)) as unique_users,
    AVG(COALESCE(ca.engagement_rate, 0)) as engagement_rate,
    SUM(COALESCE(cpm.momentum_points_awarded, 0)) as momentum_points_awarded
FROM public.daily_feed_content dc
LEFT JOIN public.content_analytics ca ON dc.id = ca.content_id
LEFT JOIN public.content_performance_metrics cpm ON dc.id = cpm.content_id AND cpm.metric_date = dc.content_date
WHERE dc.content_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY dc.content_date
ORDER BY dc.content_date DESC;

-- Grant necessary permissions
GRANT SELECT ON public.content_monitoring_alerts TO authenticated;
GRANT SELECT ON public.content_performance_metrics TO authenticated;
GRANT SELECT ON public.daily_analytics_summary TO authenticated;
GRANT SELECT ON public.user_engagement_summary TO authenticated;
GRANT SELECT ON public.content_analytics_dashboard TO authenticated;
GRANT SELECT ON public.topic_performance_analysis TO authenticated;
GRANT SELECT ON public.engagement_trends TO authenticated;

-- Grant permissions for service role (for the Cloud Run service)
GRANT ALL ON public.content_monitoring_alerts TO service_role;
GRANT ALL ON public.content_performance_metrics TO service_role;
GRANT ALL ON public.daily_analytics_summary TO service_role;
GRANT ALL ON public.user_engagement_summary TO service_role;
GRANT ALL ON public.content_analytics_dashboard TO service_role;
GRANT ALL ON public.topic_performance_analysis TO service_role;
GRANT ALL ON public.engagement_trends TO service_role;

-- Grant sequence permissions
GRANT USAGE, SELECT ON SEQUENCE public.content_performance_metrics_id_seq TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE public.daily_analytics_summary_id_seq TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE public.user_engagement_summary_id_seq TO authenticated, service_role;

-- Comments for documentation
COMMENT ON TABLE public.content_monitoring_alerts IS 'Automated alerts for content performance and quality monitoring';
COMMENT ON TABLE public.content_performance_metrics IS 'Detailed performance metrics for individual content pieces';
COMMENT ON TABLE public.daily_analytics_summary IS 'Daily aggregated analytics summary for overall performance tracking';
COMMENT ON TABLE public.user_engagement_summary IS 'User-level engagement metrics and patterns';

COMMENT ON VIEW public.content_analytics_dashboard IS 'Comprehensive view combining content, analytics, and performance data';
COMMENT ON VIEW public.topic_performance_analysis IS 'Topic-level performance analysis for content optimization';
COMMENT ON VIEW public.engagement_trends IS 'Daily engagement trends for monitoring and forecasting';

-- Insert initial sample data for testing
INSERT INTO public.content_performance_metrics (content_id, metric_date, performance_score, quality_rating, momentum_points_awarded, load_time_avg)
SELECT 
    id,
    content_date,
    0.75 + (RANDOM() * 0.25), -- Random performance score between 0.75-1.0
    3.5 + (RANDOM() * 1.5), -- Random quality rating between 3.5-5.0
    FLOOR(RANDOM() * 10) + 1, -- Random momentum points 1-10
    1.2 + (RANDOM() * 0.8) -- Random load time between 1.2-2.0 seconds
FROM public.daily_feed_content
WHERE content_date >= CURRENT_DATE - INTERVAL '7 days'
ON CONFLICT (content_id, metric_date) DO NOTHING; 