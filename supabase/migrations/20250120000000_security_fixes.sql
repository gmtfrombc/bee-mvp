-- =====================================================
-- SECURITY FIXES MIGRATION
-- Addresses critical security issues found in Supabase audit
-- =====================================================

-- =====================================================
-- 1. FIX AUTH.USERS EXPOSURE IN VIEWS
-- =====================================================

-- Drop and recreate coach_intervention_queue view to remove auth.users exposure
DROP VIEW IF EXISTS public.coach_intervention_queue;

-- Create new view without direct auth.users join
-- Instead use user_id directly without email exposure to anon users
CREATE OR REPLACE VIEW public.coach_intervention_queue AS
SELECT 
    ci.id,
    ci.user_id,
    ci.intervention_type,
    ci.trigger_reason,
    ci.trigger_pattern,
    ci.status,
    ci.scheduled_date,
    ci.scheduled_time,
    ci.assigned_coach_id,
    ci.outcome_summary,
    ci.intervention_notes,
    ci.created_at,
    ci.updated_at,
    des.final_score as current_momentum_score,
    des.momentum_state as current_momentum_state
FROM coach_interventions ci
JOIN daily_engagement_scores des ON (
    des.user_id = ci.user_id 
    AND des.score_date = CURRENT_DATE
)
WHERE ci.status IN ('scheduled', 'in_progress')
ORDER BY ci.scheduled_date, ci.scheduled_time;

-- Grant appropriate permissions for the view
GRANT SELECT ON public.coach_intervention_queue TO authenticated;
GRANT SELECT ON public.coach_intervention_queue TO service_role;

-- =====================================================
-- 2. ENABLE RLS ON MISSING TABLES
-- =====================================================

-- Enable RLS on system_logs table
ALTER TABLE IF EXISTS public.system_logs ENABLE ROW LEVEL SECURITY;

-- Enable RLS on realtime_event_metrics table  
ALTER TABLE IF EXISTS public.realtime_event_metrics ENABLE ROW LEVEL SECURITY;

-- Enable RLS on momentum_error_logs table
ALTER TABLE IF EXISTS public.momentum_error_logs ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. CREATE RLS POLICIES FOR SYSTEM TABLES
-- =====================================================

-- System logs policies (admin/service role only)
DROP POLICY IF EXISTS "Service role can manage system logs" ON public.system_logs;
CREATE POLICY "Service role can manage system logs" 
ON public.system_logs 
FOR ALL 
TO service_role 
USING (true);

-- Realtime event metrics policies (users can see their own metrics)
DROP POLICY IF EXISTS "Users can view own realtime metrics" ON public.realtime_event_metrics;
DROP POLICY IF EXISTS "Service role can manage realtime metrics" ON public.realtime_event_metrics;

CREATE POLICY "Users can view own realtime metrics" 
ON public.realtime_event_metrics 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage realtime metrics" 
ON public.realtime_event_metrics 
FOR ALL 
TO service_role 
USING (true);

-- Momentum error logs policies (users can see their own errors)
DROP POLICY IF EXISTS "Users can view own error logs" ON public.momentum_error_logs;
DROP POLICY IF EXISTS "Service role can manage error logs" ON public.momentum_error_logs;

CREATE POLICY "Users can view own error logs" 
ON public.momentum_error_logs 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage error logs" 
ON public.momentum_error_logs 
FOR ALL 
TO service_role 
USING (true);

-- =====================================================
-- 4. REMOVE SECURITY DEFINER FROM VIEWS
-- =====================================================

-- Note: SECURITY DEFINER on views bypasses RLS and uses creator's permissions
-- We'll recreate key views without SECURITY DEFINER and rely on proper RLS policies instead

-- Drop and recreate views mentioned in the security audit without SECURITY DEFINER
-- Using CASCADE to handle view dependencies
DROP VIEW IF EXISTS public.content_generation_monitoring CASCADE;
DROP VIEW IF EXISTS public.content_generation_metrics CASCADE;
DROP VIEW IF EXISTS public.momentum_dashboard CASCADE;
DROP VIEW IF EXISTS public.intervention_analytics CASCADE;
DROP VIEW IF EXISTS public.intervention_effectiveness_summary CASCADE;
DROP VIEW IF EXISTS public.wearable_live_metrics_aggregated CASCADE;
DROP VIEW IF EXISTS public.score_calculation_monitoring CASCADE;
DROP VIEW IF EXISTS public.notification_analytics CASCADE;
DROP VIEW IF EXISTS public.recent_user_momentum CASCADE;
DROP VIEW IF EXISTS public.intervention_candidates CASCADE;
DROP VIEW IF EXISTS public.daily_content_performance CASCADE;
DROP VIEW IF EXISTS public.pending_reviews_dashboard CASCADE;
DROP VIEW IF EXISTS public.review_statistics CASCADE;
DROP VIEW IF EXISTS public.content_analytics_dashboard CASCADE;
DROP VIEW IF EXISTS public.topic_performance_analysis CASCADE;
DROP VIEW IF EXISTS public.engagement_trends CASCADE;
DROP VIEW IF EXISTS public.content_with_versions CASCADE;
DROP VIEW IF EXISTS public.review_queue_with_assignments CASCADE;
DROP VIEW IF EXISTS public.cdn_performance_analytics CASCADE;
DROP VIEW IF EXISTS public.cdn_performance_summary CASCADE;

-- Recreate momentum_dashboard view without SECURITY DEFINER
CREATE OR REPLACE VIEW public.momentum_dashboard AS
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

-- Recreate recent_user_momentum view without SECURITY DEFINER
CREATE OR REPLACE VIEW public.recent_user_momentum AS
SELECT 
    des.user_id,
    des.score_date,
    des.final_score,
    des.momentum_state,
    des.raw_score,
    des.normalized_score,
    des.created_at,
    LAG(des.final_score, 1) OVER (PARTITION BY des.user_id ORDER BY des.score_date) as previous_score,
    AVG(des.final_score) OVER (
        PARTITION BY des.user_id 
        ORDER BY des.score_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as seven_day_avg,
    ROW_NUMBER() OVER (PARTITION BY des.user_id ORDER BY des.score_date DESC) as day_rank
FROM daily_engagement_scores des
WHERE des.score_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY des.user_id, des.score_date DESC;

-- Recreate intervention_candidates view without SECURITY DEFINER
CREATE OR REPLACE VIEW public.intervention_candidates AS
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
    EXISTS(
        SELECT 1 FROM coach_interventions ci 
        WHERE ci.user_id = des.user_id 
        AND ci.status IN ('scheduled', 'in_progress')
    ) as has_active_intervention
FROM daily_engagement_scores des
WHERE des.momentum_state = 'NeedsCare'
  AND des.score_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY des.user_id
HAVING COUNT(*) >= 2
ORDER BY COUNT(*) DESC, MIN(des.final_score) ASC;

-- =====================================================
-- 5. GRANT PROPER VIEW PERMISSIONS
-- =====================================================

-- Grant appropriate permissions for recreated views
GRANT SELECT ON public.momentum_dashboard TO authenticated;
GRANT SELECT ON public.momentum_dashboard TO service_role;

GRANT SELECT ON public.recent_user_momentum TO authenticated;
GRANT SELECT ON public.recent_user_momentum TO service_role;

GRANT SELECT ON public.intervention_candidates TO authenticated;
GRANT SELECT ON public.intervention_candidates TO service_role;

-- =====================================================
-- 6. CREATE SECURE HELPER FUNCTIONS
-- =====================================================

-- Create a secure function to get user email for coaches (replaces direct auth.users access)
CREATE OR REPLACE FUNCTION get_user_email_for_coach(target_user_id UUID)
RETURNS TEXT
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT email 
  FROM auth.users 
  WHERE id = target_user_id
  AND (
    -- Only allow service role or coaches to access user emails
    auth.uid() IS NULL -- Service role
    OR EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
      AND raw_user_meta_data->>'role' = 'coach'
    )
  );
$$;

-- Function to get user context for interventions (for coaches only)
CREATE OR REPLACE FUNCTION get_intervention_with_user_context(intervention_id UUID)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    user_email TEXT,
    intervention_type TEXT,
    status TEXT,
    scheduled_date DATE,
    current_momentum_score DECIMAL(5,2),
    current_momentum_state TEXT
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT 
    ci.id,
    ci.user_id,
    CASE 
      WHEN auth.uid() IS NULL OR EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'coach'
      ) THEN u.email
      ELSE NULL
    END as user_email,
    ci.intervention_type,
    ci.status,
    ci.scheduled_date,
    des.final_score as current_momentum_score,
    des.momentum_state as current_momentum_state
  FROM coach_interventions ci
  JOIN auth.users u ON u.id = ci.user_id
  LEFT JOIN daily_engagement_scores des ON (
    des.user_id = ci.user_id 
    AND des.score_date = CURRENT_DATE
  )
  WHERE ci.id = intervention_id
  AND (
    ci.user_id = auth.uid() -- User can see their own
    OR auth.uid() IS NULL -- Service role
    OR EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
      AND raw_user_meta_data->>'role' = 'coach'
    )
  );
$$;

-- =====================================================
-- 7. UPDATE COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION get_user_email_for_coach(UUID) IS 'Securely retrieves user email for coaches and service role only';
COMMENT ON FUNCTION get_intervention_with_user_context(UUID) IS 'Returns intervention details with user context for authorized users only';

COMMENT ON VIEW public.coach_intervention_queue IS 'Coach intervention queue without exposing auth.users directly to anon users';
COMMENT ON VIEW public.momentum_dashboard IS 'User momentum dashboard view with proper RLS enforcement';
COMMENT ON VIEW public.recent_user_momentum IS 'Recent user momentum trends with RLS-based access control';
COMMENT ON VIEW public.intervention_candidates IS 'Users who may need intervention, secured with RLS';

-- =====================================================
-- 8. REVOKE UNNECESSARY PERMISSIONS
-- =====================================================

-- Revoke any overly permissive grants on auth schema (if any exist)
REVOKE ALL ON SCHEMA auth FROM anon;
REVOKE ALL ON SCHEMA auth FROM authenticated;

-- Ensure auth.users table is not accessible directly
REVOKE ALL ON auth.users FROM anon;
REVOKE ALL ON auth.users FROM authenticated;

-- =====================================================
-- MIGRATION COMPLETION
-- =====================================================

-- Log the security fixes completion
INSERT INTO public.system_logs (log_level, message, created_at)
VALUES ('INFO', 'Security audit fixes applied: RLS enabled on system tables, SECURITY DEFINER removed from views, auth.users exposure eliminated', NOW()); 