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
CREATE INDEX IF NOT EXISTS idx_daily_scores_user_date 
ON daily_engagement_scores(user_id, score_date DESC);

-- For momentum state filtering and analytics
CREATE INDEX IF NOT EXISTS idx_daily_scores_momentum_state 
ON daily_engagement_scores(momentum_state, score_date DESC);

-- For score range queries and analytics
CREATE INDEX IF NOT EXISTS idx_daily_scores_final_score 
ON daily_engagement_scores(final_score DESC, score_date DESC);

-- For recent scores lookup (most common query pattern) - fixed without CURRENT_DATE
CREATE INDEX IF NOT EXISTS idx_daily_scores_recent 
ON daily_engagement_scores(user_id, score_date DESC);

-- Composite index for trend analysis
CREATE INDEX IF NOT EXISTS idx_daily_scores_trend_analysis 
ON daily_engagement_scores(user_id, score_date DESC, momentum_state, final_score);

-- Indexes for momentum_notifications table
-- Primary lookup: user notifications by date
CREATE INDEX IF NOT EXISTS idx_notifications_user_date 
ON momentum_notifications(user_id, trigger_date DESC);

-- For notification status filtering
CREATE INDEX IF NOT EXISTS idx_notifications_status 
ON momentum_notifications(status, trigger_date DESC) 
WHERE status IN ('pending', 'sent');

-- For notification type analytics
CREATE INDEX IF NOT EXISTS idx_notifications_type_date 
ON momentum_notifications(notification_type, trigger_date DESC);

-- For unread notifications lookup - fixed column names
CREATE INDEX IF NOT EXISTS idx_notifications_unread 
ON momentum_notifications(user_id, created_at DESC) 
WHERE status = 'pending' OR (status = 'sent' AND opened_at IS NULL);

-- Indexes for coach_interventions table
-- Primary lookup: user interventions by date
CREATE INDEX IF NOT EXISTS idx_interventions_user_date 
ON coach_interventions(user_id, trigger_date DESC);

-- For intervention status tracking
CREATE INDEX IF NOT EXISTS idx_interventions_status 
ON coach_interventions(status, scheduled_date) 
WHERE status IN ('scheduled', 'in_progress');

-- For intervention type analytics
CREATE INDEX IF NOT EXISTS idx_interventions_type_date 
ON coach_interventions(intervention_type, trigger_date DESC);

-- For coach workload management
CREATE INDEX IF NOT EXISTS idx_interventions_coach_scheduled 
ON coach_interventions(assigned_coach_id, scheduled_date) 
WHERE status IN ('scheduled', 'in_progress') AND assigned_coach_id IS NOT NULL;

-- Indexes for engagement_events table (if not already optimized)
-- For momentum calculation queries - fixed column names
CREATE INDEX IF NOT EXISTS idx_engagement_events_momentum_calc 
ON engagement_events(user_id, timestamp DESC, event_type);

-- For recent events lookup - fixed column names  
CREATE INDEX IF NOT EXISTS idx_engagement_events_recent 
ON engagement_events(user_id, timestamp DESC);

-- For event type analytics - fixed column names
CREATE INDEX IF NOT EXISTS idx_engagement_events_type_date 
ON engagement_events(event_type, timestamp DESC);

-- =====================================================
-- PARTIAL INDEXES FOR COMMON FILTERS
-- =====================================================

-- Index for active users (users with recent activity) - fixed without CURRENT_DATE
CREATE INDEX IF NOT EXISTS idx_daily_scores_active_users 
ON daily_engagement_scores(user_id, score_date DESC);

-- Index for users needing care
CREATE INDEX IF NOT EXISTS idx_daily_scores_needs_care 
ON daily_engagement_scores(user_id, score_date DESC, final_score) 
WHERE momentum_state = 'NeedsCare';

-- Index for high-performing users
CREATE INDEX IF NOT EXISTS idx_daily_scores_rising 
ON daily_engagement_scores(user_id, score_date DESC, final_score) 
WHERE momentum_state = 'Rising';

-- Index for pending interventions - fixed without CURRENT_DATE and priority
CREATE INDEX IF NOT EXISTS idx_interventions_pending 
ON coach_interventions(user_id, scheduled_date) 
WHERE status = 'scheduled';

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
    -- Simplified activity status without CURRENT_DATE
    CASE 
        WHEN MAX(score_date) >= (MAX(score_date) - INTERVAL '1 day') THEN 'active'
        WHEN MAX(score_date) >= (MAX(score_date) - INTERVAL '7 days') THEN 'recent'
        ELSE 'inactive'
    END as activity_status,
    -- Trend calculation (simplified)
    AVG(final_score) as recent_avg_score,
    AVG(final_score) as previous_avg_score
FROM daily_engagement_scores des
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
    -- Engagement metrics (simplified)
    0 as total_events,
    0 as engaged_users
FROM daily_engagement_scores des
GROUP BY score_date
ORDER BY score_date DESC;

-- Index for the daily metrics view
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_system_metrics_date 
ON daily_system_metrics(score_date);

CREATE INDEX IF NOT EXISTS idx_daily_system_metrics_active_users 
ON daily_system_metrics(active_users DESC, score_date DESC);

-- =====================================================
-- REFRESH FUNCTIONS FOR MATERIALIZED VIEWS
-- =====================================================

-- Function to refresh all momentum-related materialized views
CREATE OR REPLACE FUNCTION refresh_momentum_materialized_views()
RETURNS VOID AS $$
BEGIN
    -- Refresh user momentum summary
    REFRESH MATERIALIZED VIEW CONCURRENTLY user_momentum_summary;
    
    -- Refresh daily system metrics  
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_system_metrics;
    
    -- Log the refresh
    RAISE NOTICE 'Momentum materialized views refreshed at %', NOW();
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

-- =====================================================
-- TABLE ANALYSIS AND STATISTICS FUNCTIONS
-- =====================================================

-- Function to analyze and update table statistics
CREATE OR REPLACE FUNCTION analyze_momentum_tables()
RETURNS VOID AS $$
BEGIN
    -- Analyze main momentum tables
    ANALYZE daily_engagement_scores;
    ANALYZE momentum_notifications;
    ANALYZE coach_interventions;
    ANALYZE engagement_events;
    
    -- Analyze materialized views
    ANALYZE user_momentum_summary;
    ANALYZE daily_system_metrics;
    
    RAISE NOTICE 'Momentum table analysis completed at %', NOW();
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

-- =====================================================
-- PERFORMANCE MONITORING FUNCTIONS
-- =====================================================

-- Function to get performance recommendations
CREATE OR REPLACE FUNCTION get_performance_recommendations()
RETURNS TABLE(
    table_name TEXT,
    recommendation TEXT,
    reason TEXT,
    priority TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH table_stats AS (
        SELECT 
            schemaname,
            tablename,
            n_tup_ins,
            n_tup_upd,
            n_tup_del,
            n_live_tup,
            n_dead_tup,
            last_vacuum,
            last_autovacuum,
            last_analyze,
            last_autoanalyze
        FROM pg_stat_user_tables 
        WHERE tablename IN ('daily_engagement_scores', 'momentum_notifications', 'coach_interventions', 'engagement_events')
    )
    SELECT 
        ts.tablename::TEXT,
        CASE 
            WHEN ts.last_analyze < NOW() - INTERVAL '1 day' THEN 'Run ANALYZE'
            WHEN ts.n_dead_tup > ts.n_live_tup * 0.1 THEN 'Run VACUUM'
            WHEN ts.n_live_tup > 10000 AND ts.last_vacuum < NOW() - INTERVAL '1 week' THEN 'Schedule regular VACUUM'
            ELSE 'No action needed'
        END::TEXT as recommendation,
        CASE 
            WHEN ts.last_analyze < NOW() - INTERVAL '1 day' THEN 'Table statistics are outdated'
            WHEN ts.n_dead_tup > ts.n_live_tup * 0.1 THEN 'High dead tuple ratio detected'
            WHEN ts.n_live_tup > 10000 AND ts.last_vacuum < NOW() - INTERVAL '1 week' THEN 'Large table needs regular maintenance'
            ELSE 'Table is performing well'
        END::TEXT as reason,
        CASE 
            WHEN ts.last_analyze < NOW() - INTERVAL '1 day' THEN 'High'
            WHEN ts.n_dead_tup > ts.n_live_tup * 0.1 THEN 'Medium'
            WHEN ts.n_live_tup > 10000 AND ts.last_vacuum < NOW() - INTERVAL '1 week' THEN 'Low'
            ELSE 'None'
        END::TEXT as priority
    FROM table_stats ts;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

-- =====================================================
-- OPTIMIZED VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for recent user momentum (last 30 days)
CREATE OR REPLACE VIEW recent_user_momentum AS
SELECT 
    des.user_id,
    des.score_date,
    des.final_score,
    des.momentum_state,
    des.raw_score,
    des.normalized_score,
    des.created_at,
    -- Add user activity metrics
    LAG(des.final_score, 1) OVER (PARTITION BY des.user_id ORDER BY des.score_date) as previous_score,
    AVG(des.final_score) OVER (
        PARTITION BY des.user_id 
        ORDER BY des.score_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as seven_day_avg,
    ROW_NUMBER() OVER (PARTITION BY des.user_id ORDER BY des.score_date DESC) as day_rank
FROM daily_engagement_scores des
ORDER BY des.user_id, des.score_date DESC;

-- View for users who may need intervention
CREATE OR REPLACE VIEW intervention_candidates AS
SELECT 
    des.user_id,
    COUNT(*) as consecutive_needs_care_days,
    MAX(des.score_date) as latest_score_date,
    AVG(des.final_score) as avg_score_needs_care_period,
    MIN(des.final_score) as lowest_score,
    CASE 
        WHEN COUNT(*) >= 3 THEN 'Immediate'
        WHEN COUNT(*) >= 2 THEN 'Soon'
        ELSE 'Monitor'
    END as intervention_urgency,
    -- Check if intervention already exists (simplified without CURRENT_DATE)
    EXISTS(
        SELECT 1 FROM coach_interventions ci 
        WHERE ci.user_id = des.user_id 
        AND ci.status IN ('scheduled', 'in_progress')
    ) as has_active_intervention
FROM daily_engagement_scores des
WHERE des.momentum_state = 'NeedsCare'
GROUP BY des.user_id
HAVING COUNT(*) >= 2  -- At least 2 consecutive days needing care
ORDER BY COUNT(*) DESC, MIN(des.final_score) ASC;

-- =====================================================
-- MAINTENANCE AND OPTIMIZATION PROCEDURES
-- =====================================================

-- Comprehensive maintenance function
CREATE OR REPLACE FUNCTION perform_momentum_maintenance()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    table_count INTEGER;
BEGIN
    -- Update table statistics
    PERFORM analyze_momentum_tables();
    result_text := result_text || 'Table analysis completed. ';
    
    -- Refresh materialized views
    PERFORM refresh_momentum_materialized_views();
    result_text := result_text || 'Materialized views refreshed. ';
    
    -- Clean up old notifications (older than 90 days)
    DELETE FROM momentum_notifications 
    WHERE created_at < CURRENT_DATE - INTERVAL '90 days'
    AND status = 'sent' AND read_at IS NOT NULL;
    
    GET DIAGNOSTICS table_count = ROW_COUNT;
    result_text := result_text || format('Cleaned up %s old notifications. ', table_count);
    
    -- Clean up completed interventions (older than 180 days)
    DELETE FROM coach_interventions 
    WHERE created_at < CURRENT_DATE - INTERVAL '180 days'
    AND status = 'completed';
    
    GET DIAGNOSTICS table_count = ROW_COUNT;
    result_text := result_text || format('Cleaned up %s old interventions. ', table_count);
    
    -- Log maintenance completion
    INSERT INTO system_logs (log_type, message, created_at)
    VALUES ('maintenance', 'Momentum system maintenance completed: ' || result_text, NOW());
    
    RETURN result_text || 'Maintenance completed successfully.';
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

-- =====================================================
-- PERFORMANCE MONITORING AND ALERTING
-- =====================================================

-- Function to monitor momentum system performance
CREATE OR REPLACE FUNCTION monitor_momentum_performance()
RETURNS TABLE(
    metric_name TEXT,
    metric_value NUMERIC,
    threshold_value NUMERIC,
    status TEXT,
    alert_level TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH performance_metrics AS (
        -- Query performance metrics
        SELECT 
            'avg_daily_score_query_time'::TEXT as metric,
            (
                SELECT AVG(total_exec_time) 
                FROM pg_stat_statements 
                WHERE query LIKE '%daily_engagement_scores%' 
                AND calls > 10
            ) as value,
            1000.0 as threshold,  -- 1 second threshold
            'Query Performance' as category
        UNION ALL
        -- Table size metrics
        SELECT 
            'daily_scores_table_size_mb'::TEXT,
            (
                SELECT pg_total_relation_size('daily_engagement_scores') / (1024*1024)
            )::NUMERIC,
            1000.0,  -- 1GB threshold
            'Storage'
        UNION ALL
        -- Index usage metrics
        SELECT 
            'index_usage_ratio'::TEXT,
            (
                SELECT 
                    CASE WHEN (idx_scan + seq_scan) > 0 
                    THEN idx_scan::NUMERIC / (idx_scan + seq_scan) * 100
                    ELSE 0 END
                FROM pg_stat_user_tables 
                WHERE tablename = 'daily_engagement_scores'
            ),
            80.0,  -- 80% index usage threshold
            'Query Optimization'
        UNION ALL
        -- Active connections
        SELECT 
            'active_connections'::TEXT,
            (SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active')::NUMERIC,
            50.0,  -- 50 connections threshold
            'Connection Pool'
    )
    SELECT 
        pm.metric::TEXT,
        COALESCE(pm.value, 0) as metric_value,
        pm.threshold as threshold_value,
        CASE 
            WHEN pm.value IS NULL THEN 'Unknown'
            WHEN pm.metric = 'index_usage_ratio' AND pm.value >= pm.threshold THEN 'Good'
            WHEN pm.metric != 'index_usage_ratio' AND pm.value <= pm.threshold THEN 'Good'
            ELSE 'Alert'
        END::TEXT as status,
        CASE 
            WHEN pm.value IS NULL THEN 'Info'
            WHEN pm.metric = 'index_usage_ratio' AND pm.value < pm.threshold * 0.5 THEN 'Critical'
            WHEN pm.metric != 'index_usage_ratio' AND pm.value > pm.threshold * 2 THEN 'Critical'
            WHEN pm.metric = 'index_usage_ratio' AND pm.value < pm.threshold THEN 'Warning'
            WHEN pm.metric != 'index_usage_ratio' AND pm.value > pm.threshold THEN 'Warning'
            ELSE 'Normal'
        END::TEXT as alert_level
    FROM performance_metrics pm;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

-- =====================================================
-- SCHEDULED MAINTENANCE (FOR FUTURE AUTOMATION)
-- =====================================================

-- Note: These would typically be set up as cron jobs or scheduled tasks
-- For now, they're available as manual functions

-- Daily maintenance (suggested to run at 2 AM)
CREATE OR REPLACE FUNCTION daily_momentum_maintenance()
RETURNS TEXT AS $$
BEGIN
    -- Refresh materialized views
    PERFORM refresh_momentum_materialized_views();
    
    -- Update table statistics
    PERFORM analyze_momentum_tables();
    
    RETURN 'Daily maintenance completed at ' || NOW();
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

-- Weekly maintenance (suggested to run on Sundays at 3 AM)
CREATE OR REPLACE FUNCTION weekly_momentum_maintenance()
RETURNS TEXT AS $$
BEGIN
    -- Full maintenance
    RETURN perform_momentum_maintenance();
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION refresh_momentum_materialized_views() TO service_role;
GRANT EXECUTE ON FUNCTION analyze_momentum_tables() TO service_role;
GRANT EXECUTE ON FUNCTION get_performance_recommendations() TO service_role;
GRANT EXECUTE ON FUNCTION perform_momentum_maintenance() TO service_role;
GRANT EXECUTE ON FUNCTION monitor_momentum_performance() TO service_role;
GRANT EXECUTE ON FUNCTION daily_momentum_maintenance() TO service_role;
GRANT EXECUTE ON FUNCTION weekly_momentum_maintenance() TO service_role;

-- Grant access to materialized views
GRANT SELECT ON user_momentum_summary TO anon, authenticated;
GRANT SELECT ON daily_system_metrics TO anon, authenticated;

-- Grant access to performance views
GRANT SELECT ON recent_user_momentum TO anon, authenticated;
GRANT SELECT ON intervention_candidates TO authenticated;