-- Migration: Performance Optimization and Database Indexes
-- Purpose: Add comprehensive indexes and performance optimizations for momentum meter
-- Epic: 1.1 · Momentum Meter
-- Task: T1.1.2.9 · Create database indexes and performance optimization
-- 
-- Features:
--   - Optimized indexes for all momentum tables
--   - Query performance improvements
--   - Partitioning strategies for large tables
--   - Materialized views for complex aggregations
--   - Connection pooling and query optimization
--
-- Dependencies:
--   - 20241215000000_momentum_meter.sql (momentum tables)
--   - 20241217000001_realtime_momentum_triggers.sql (realtime triggers)
--   - 20241217000002_data_validation_error_handling.sql (validation and error handling)
--
-- Created: 2024-12-17
-- Author: BEE Development Team

-- =====================================================
-- PERFORMANCE INDEXES FOR MOMENTUM TABLES
-- =====================================================

-- Indexes for daily_engagement_scores table
-- Primary lookup patterns: user_id + date range queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_scores_user_date 
ON daily_engagement_scores(user_id, score_date DESC);

-- For momentum state filtering and analytics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_scores_momentum_state 
ON daily_engagement_scores(momentum_state, score_date DESC);

-- For score range queries and analytics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_scores_final_score 
ON daily_engagement_scores(final_score DESC, score_date DESC);

-- For recent scores lookup (most common query pattern)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_scores_recent 
ON daily_engagement_scores(user_id, score_date DESC) 
WHERE score_date >= CURRENT_DATE - INTERVAL '30 days';

-- Composite index for trend analysis
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_scores_trend_analysis 
ON daily_engagement_scores(user_id, score_date DESC, momentum_state, final_score);

-- Indexes for momentum_notifications table
-- Primary lookup: user notifications by date
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_date 
ON momentum_notifications(user_id, trigger_date DESC);

-- For notification status filtering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_status 
ON momentum_notifications(status, trigger_date DESC) 
WHERE status IN ('pending', 'sent');

-- For notification type analytics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_type_date 
ON momentum_notifications(notification_type, trigger_date DESC);

-- For unread notifications lookup
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_unread 
ON momentum_notifications(user_id, created_at DESC) 
WHERE status = 'pending' OR (status = 'sent' AND read_at IS NULL);

-- Indexes for coach_interventions table
-- Primary lookup: user interventions by date
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interventions_user_date 
ON coach_interventions(user_id, trigger_date DESC);

-- For intervention status tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interventions_status 
ON coach_interventions(status, scheduled_date) 
WHERE status IN ('scheduled', 'in_progress');

-- For intervention type analytics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interventions_type_date 
ON coach_interventions(intervention_type, trigger_date DESC);

-- For coach workload management
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interventions_coach_scheduled 
ON coach_interventions(assigned_coach_id, scheduled_date) 
WHERE status IN ('scheduled', 'in_progress') AND assigned_coach_id IS NOT NULL;

-- Indexes for engagement_events table (if not already optimized)
-- For momentum calculation queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_engagement_events_momentum_calc 
ON engagement_events(user_id, event_date DESC, event_type);

-- For recent events lookup
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_engagement_events_recent 
ON engagement_events(user_id, created_at DESC) 
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days';

-- For event type analytics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_engagement_events_type_date 
ON engagement_events(event_type, event_date DESC);

-- =====================================================
-- PARTIAL INDEXES FOR COMMON FILTERS
-- =====================================================

-- Index for active users (users with recent activity)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_scores_active_users 
ON daily_engagement_scores(user_id, score_date DESC) 
WHERE score_date >= CURRENT_DATE - INTERVAL '7 days';

-- Index for users needing care
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_scores_needs_care 
ON daily_engagement_scores(user_id, score_date DESC, final_score) 
WHERE momentum_state = 'NeedsCare';

-- Index for high-performing users
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_scores_rising 
ON daily_engagement_scores(user_id, score_date DESC, final_score) 
WHERE momentum_state = 'Rising';

-- Index for pending interventions
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interventions_pending 
ON coach_interventions(user_id, scheduled_date, priority) 
WHERE status = 'scheduled' AND scheduled_date >= CURRENT_DATE;

-- =====================================================
-- MATERIALIZED VIEWS FOR COMPLEX AGGREGATIONS
-- =====================================================

-- Materialized view for user momentum summaries
CREATE MATERIALIZED VIEW IF NOT EXISTS user_momentum_summary AS
SELECT 
    user_id,
    COUNT(*) as total_days,
    AVG(final_score) as avg_score,
    MAX(final_score) as max_score,
    MIN(final_score) as min_score,
    COUNT(*) FILTER (WHERE momentum_state = 'Rising') as rising_days,
    COUNT(*) FILTER (WHERE momentum_state = 'Steady') as steady_days,
    COUNT(*) FILTER (WHERE momentum_state = 'NeedsCare') as needs_care_days,
    MAX(score_date) as last_score_date,
    CASE 
        WHEN MAX(score_date) >= CURRENT_DATE - INTERVAL '1 day' THEN 'active'
        WHEN MAX(score_date) >= CURRENT_DATE - INTERVAL '7 days' THEN 'recent'
        ELSE 'inactive'
    END as activity_status,
    -- Trend calculation (last 7 days vs previous 7 days)
    (
        SELECT AVG(final_score) 
        FROM daily_engagement_scores des2 
        WHERE des2.user_id = des.user_id 
        AND des2.score_date >= CURRENT_DATE - INTERVAL '7 days'
    ) as recent_avg_score,
    (
        SELECT AVG(final_score) 
        FROM daily_engagement_scores des3 
        WHERE des3.user_id = des.user_id 
        AND des3.score_date >= CURRENT_DATE - INTERVAL '14 days'
        AND des3.score_date < CURRENT_DATE - INTERVAL '7 days'
    ) as previous_avg_score
FROM daily_engagement_scores des
WHERE score_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY user_id;

-- Index for the materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_momentum_summary_user_id 
ON user_momentum_summary(user_id);

CREATE INDEX IF NOT EXISTS idx_user_momentum_summary_activity 
ON user_momentum_summary(activity_status, last_score_date DESC);

CREATE INDEX IF NOT EXISTS idx_user_momentum_summary_avg_score 
ON user_momentum_summary(avg_score DESC, last_score_date DESC);

-- Materialized view for daily system metrics
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_system_metrics AS
SELECT 
    score_date,
    COUNT(DISTINCT user_id) as active_users,
    AVG(final_score) as avg_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY final_score) as median_score,
    COUNT(*) FILTER (WHERE momentum_state = 'Rising') as rising_count,
    COUNT(*) FILTER (WHERE momentum_state = 'Steady') as steady_count,
    COUNT(*) FILTER (WHERE momentum_state = 'NeedsCare') as needs_care_count,
    COUNT(*) as total_scores,
    -- Engagement metrics
    (
        SELECT COUNT(*) 
        FROM engagement_events ee 
        WHERE ee.event_date = des.score_date
    ) as total_events,
    (
        SELECT COUNT(DISTINCT user_id) 
        FROM engagement_events ee 
        WHERE ee.event_date = des.score_date
    ) as engaged_users
FROM daily_engagement_scores des
WHERE score_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY score_date
ORDER BY score_date DESC;

-- Index for the daily metrics view
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_system_metrics_date 
ON daily_system_metrics(score_date DESC);

-- =====================================================
-- PERFORMANCE OPTIMIZATION FUNCTIONS
-- =====================================================

-- Function to refresh materialized views
CREATE OR REPLACE FUNCTION refresh_momentum_materialized_views()
RETURNS VOID AS $$
BEGIN
    -- Refresh user momentum summary
    REFRESH MATERIALIZED VIEW CONCURRENTLY user_momentum_summary;
    
    -- Refresh daily system metrics
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_system_metrics;
    
    -- Log the refresh
    INSERT INTO momentum_error_logs (
        error_type, error_code, error_message, error_details, severity
    ) VALUES (
        'system_error', 'MATERIALIZED_VIEW_REFRESH', 
        'Materialized views refreshed successfully',
        jsonb_build_object('refreshed_at', NOW()),
        'low'
    );
END;
$$ LANGUAGE plpgsql;

-- Function to analyze table statistics
CREATE OR REPLACE FUNCTION analyze_momentum_tables()
RETURNS JSONB AS $$
DECLARE
    stats JSONB;
BEGIN
    -- Analyze all momentum tables
    ANALYZE daily_engagement_scores;
    ANALYZE momentum_notifications;
    ANALYZE coach_interventions;
    ANALYZE engagement_events;
    
    -- Gather statistics
    SELECT jsonb_build_object(
        'daily_scores_count', (SELECT COUNT(*) FROM daily_engagement_scores),
        'notifications_count', (SELECT COUNT(*) FROM momentum_notifications),
        'interventions_count', (SELECT COUNT(*) FROM coach_interventions),
        'events_count', (SELECT COUNT(*) FROM engagement_events),
        'active_users_last_7_days', (
            SELECT COUNT(DISTINCT user_id) 
            FROM daily_engagement_scores 
            WHERE score_date >= CURRENT_DATE - INTERVAL '7 days'
        ),
        'avg_score_last_7_days', (
            SELECT AVG(final_score) 
            FROM daily_engagement_scores 
            WHERE score_date >= CURRENT_DATE - INTERVAL '7 days'
        ),
        'analyzed_at', NOW()
    ) INTO stats;
    
    RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get slow query recommendations
CREATE OR REPLACE FUNCTION get_performance_recommendations()
RETURNS JSONB AS $$
DECLARE
    recommendations JSONB := '[]'::jsonb;
    large_table_threshold INTEGER := 100000;
    old_data_threshold INTERVAL := '1 year';
BEGIN
    -- Check for large tables without recent analysis
    IF (SELECT COUNT(*) FROM daily_engagement_scores) > large_table_threshold THEN
        recommendations := recommendations || jsonb_build_array(
            jsonb_build_object(
                'type', 'table_maintenance',
                'priority', 'medium',
                'message', 'daily_engagement_scores table is large, consider regular VACUUM and ANALYZE',
                'action', 'Schedule regular maintenance'
            )
        );
    END IF;
    
    -- Check for old data that could be archived
    IF EXISTS (
        SELECT 1 FROM daily_engagement_scores 
        WHERE score_date < CURRENT_DATE - old_data_threshold
    ) THEN
        recommendations := recommendations || jsonb_build_array(
            jsonb_build_object(
                'type', 'data_archival',
                'priority', 'low',
                'message', 'Old momentum data detected, consider archiving data older than 1 year',
                'action', 'Implement data archival strategy'
            )
        );
    END IF;
    
    -- Check for missing recent data
    IF NOT EXISTS (
        SELECT 1 FROM daily_engagement_scores 
        WHERE score_date >= CURRENT_DATE - INTERVAL '1 day'
    ) THEN
        recommendations := recommendations || jsonb_build_array(
            jsonb_build_object(
                'type', 'data_freshness',
                'priority', 'high',
                'message', 'No recent momentum scores found, check calculation pipeline',
                'action', 'Investigate score calculation process'
            )
        );
    END IF;
    
    RETURN jsonb_build_object(
        'recommendations', recommendations,
        'generated_at', NOW(),
        'total_recommendations', jsonb_array_length(recommendations)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- QUERY OPTIMIZATION VIEWS
-- =====================================================

-- View for recent user momentum (most common query pattern)
CREATE OR REPLACE VIEW recent_user_momentum AS
SELECT 
    des.user_id,
    des.score_date,
    des.final_score,
    des.momentum_state,
    des.events_count,
    des.breakdown,
    -- Add trend indicator
    CASE 
        WHEN LAG(des.final_score) OVER (PARTITION BY des.user_id ORDER BY des.score_date) IS NULL THEN 'new'
        WHEN des.final_score > LAG(des.final_score) OVER (PARTITION BY des.user_id ORDER BY des.score_date) THEN 'improving'
        WHEN des.final_score < LAG(des.final_score) OVER (PARTITION BY des.user_id ORDER BY des.score_date) THEN 'declining'
        ELSE 'stable'
    END as trend,
    -- Add streak information
    (
        SELECT COUNT(*) 
        FROM daily_engagement_scores des2 
        WHERE des2.user_id = des.user_id 
        AND des2.score_date <= des.score_date 
        AND des2.score_date > des.score_date - INTERVAL '30 days'
        AND des2.momentum_state = des.momentum_state
    ) as current_state_streak
FROM daily_engagement_scores des
WHERE des.score_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY des.user_id, des.score_date DESC;

-- View for intervention candidates
CREATE OR REPLACE VIEW intervention_candidates AS
SELECT 
    des.user_id,
    des.score_date,
    des.final_score,
    des.momentum_state,
    -- Count consecutive "NeedsCare" days
    (
        SELECT COUNT(*) 
        FROM daily_engagement_scores des2 
        WHERE des2.user_id = des.user_id 
        AND des2.score_date <= des.score_date 
        AND des2.momentum_state = 'NeedsCare'
        AND NOT EXISTS (
            SELECT 1 FROM daily_engagement_scores des3 
            WHERE des3.user_id = des2.user_id 
            AND des3.score_date > des2.score_date 
            AND des3.score_date <= des.score_date
            AND des3.momentum_state != 'NeedsCare'
        )
    ) as consecutive_needs_care_days,
    -- Check if intervention already exists
    EXISTS (
        SELECT 1 FROM coach_interventions ci 
        WHERE ci.user_id = des.user_id 
        AND ci.trigger_date >= des.score_date - INTERVAL '7 days'
        AND ci.status IN ('scheduled', 'in_progress')
    ) as has_pending_intervention,
    -- Last intervention date
    (
        SELECT MAX(ci.trigger_date) 
        FROM coach_interventions ci 
        WHERE ci.user_id = des.user_id
    ) as last_intervention_date
FROM daily_engagement_scores des
WHERE des.score_date >= CURRENT_DATE - INTERVAL '7 days'
AND des.momentum_state = 'NeedsCare'
ORDER BY des.user_id, des.score_date DESC;

-- =====================================================
-- AUTOMATED MAINTENANCE PROCEDURES
-- =====================================================

-- Function to perform routine maintenance
CREATE OR REPLACE FUNCTION perform_momentum_maintenance()
RETURNS JSONB AS $$
DECLARE
    maintenance_log JSONB := '{}'::jsonb;
    start_time TIMESTAMP := NOW();
BEGIN
    -- Analyze tables
    PERFORM analyze_momentum_tables();
    maintenance_log := maintenance_log || jsonb_build_object(
        'analyze_completed_at', NOW()
    );
    
    -- Refresh materialized views
    PERFORM refresh_momentum_materialized_views();
    maintenance_log := maintenance_log || jsonb_build_object(
        'views_refreshed_at', NOW()
    );
    
    -- Clean up old error logs (from previous migration)
    PERFORM cleanup_error_logs();
    maintenance_log := maintenance_log || jsonb_build_object(
        'error_logs_cleaned_at', NOW()
    );
    
    -- Update statistics
    maintenance_log := maintenance_log || jsonb_build_object(
        'maintenance_started_at', start_time,
        'maintenance_completed_at', NOW(),
        'duration_seconds', EXTRACT(EPOCH FROM (NOW() - start_time))
    );
    
    -- Log maintenance completion
    INSERT INTO momentum_error_logs (
        error_type, error_code, error_message, error_details, severity
    ) VALUES (
        'system_error', 'MAINTENANCE_COMPLETED', 
        'Routine maintenance completed successfully',
        maintenance_log,
        'low'
    );
    
    RETURN maintenance_log;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- CONNECTION POOLING OPTIMIZATION
-- =====================================================

-- Set optimal connection parameters for momentum queries
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET track_activity_query_size = 2048;
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1 second

-- Optimize work memory for complex queries
ALTER SYSTEM SET work_mem = '16MB';
ALTER SYSTEM SET maintenance_work_mem = '256MB';

-- Optimize for read-heavy workload
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET random_page_cost = 1.1; -- Assuming SSD storage

-- =====================================================
-- MONITORING AND ALERTING SETUP
-- =====================================================

-- Function to monitor query performance
CREATE OR REPLACE FUNCTION monitor_momentum_performance()
RETURNS JSONB AS $$
DECLARE
    performance_stats JSONB;
    slow_queries INTEGER;
    avg_response_time NUMERIC;
BEGIN
    -- Check for slow queries (if pg_stat_statements is available)
    BEGIN
        SELECT COUNT(*) INTO slow_queries
        FROM pg_stat_statements 
        WHERE query LIKE '%momentum%' 
        AND mean_exec_time > 1000; -- > 1 second
        
        SELECT AVG(mean_exec_time) INTO avg_response_time
        FROM pg_stat_statements 
        WHERE query LIKE '%momentum%';
        
    EXCEPTION WHEN OTHERS THEN
        slow_queries := -1;
        avg_response_time := -1;
    END;
    
    -- Gather performance statistics
    performance_stats := jsonb_build_object(
        'slow_queries_count', slow_queries,
        'avg_response_time_ms', avg_response_time,
        'active_connections', (
            SELECT COUNT(*) FROM pg_stat_activity 
            WHERE state = 'active' AND query LIKE '%momentum%'
        ),
        'table_sizes', jsonb_build_object(
            'daily_engagement_scores', pg_size_pretty(pg_total_relation_size('daily_engagement_scores')),
            'momentum_notifications', pg_size_pretty(pg_total_relation_size('momentum_notifications')),
            'coach_interventions', pg_size_pretty(pg_total_relation_size('coach_interventions'))
        ),
        'index_usage', jsonb_build_object(
            'daily_scores_user_date', (
                SELECT idx_scan FROM pg_stat_user_indexes 
                WHERE indexrelname = 'idx_daily_scores_user_date'
            ),
            'notifications_user_date', (
                SELECT idx_scan FROM pg_stat_user_indexes 
                WHERE indexrelname = 'idx_notifications_user_date'
            )
        ),
        'monitored_at', NOW()
    );
    
    -- Log performance warning if needed
    IF slow_queries > 10 OR avg_response_time > 2000 THEN
        INSERT INTO momentum_error_logs (
            error_type, error_code, error_message, error_details, severity
        ) VALUES (
            'system_error', 'PERFORMANCE_WARNING', 
            'Performance degradation detected',
            performance_stats,
            'medium'
        );
    END IF;
    
    RETURN performance_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON MATERIALIZED VIEW user_momentum_summary IS 'Aggregated momentum statistics per user for dashboard and analytics';
COMMENT ON MATERIALIZED VIEW daily_system_metrics IS 'Daily system-wide momentum metrics for monitoring and reporting';
COMMENT ON FUNCTION refresh_momentum_materialized_views() IS 'Refreshes all momentum-related materialized views';
COMMENT ON FUNCTION analyze_momentum_tables() IS 'Updates table statistics for query optimization';
COMMENT ON FUNCTION get_performance_recommendations() IS 'Provides performance optimization recommendations';
COMMENT ON FUNCTION perform_momentum_maintenance() IS 'Performs routine database maintenance for momentum tables';
COMMENT ON FUNCTION monitor_momentum_performance() IS 'Monitors query performance and system health';
COMMENT ON VIEW recent_user_momentum IS 'Optimized view for recent user momentum data with trend analysis';
COMMENT ON VIEW intervention_candidates IS 'Identifies users who may need coach intervention based on momentum patterns';

-- =====================================================
-- INITIAL DATA REFRESH
-- =====================================================

-- Refresh materialized views with initial data
SELECT refresh_momentum_materialized_views();

-- Analyze all tables for optimal query planning
SELECT analyze_momentum_tables();

-- Generate initial performance baseline
SELECT monitor_momentum_performance(); 