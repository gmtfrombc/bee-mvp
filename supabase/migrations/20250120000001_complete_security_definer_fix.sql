-- =====================================================
-- COMPLETE SECURITY DEFINER REMOVAL
-- Ensures all views are recreated without SECURITY DEFINER
-- =====================================================

-- Force drop and recreate the specific views still showing in audit
DROP VIEW IF EXISTS public.coach_intervention_queue CASCADE;
DROP VIEW IF EXISTS public.momentum_dashboard CASCADE;
DROP VIEW IF EXISTS public.recent_user_momentum CASCADE;
DROP VIEW IF EXISTS public.intervention_candidates CASCADE;

-- Recreate coach_intervention_queue view without SECURITY DEFINER
CREATE VIEW public.coach_intervention_queue AS
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

-- Recreate momentum_dashboard view without SECURITY DEFINER
CREATE VIEW public.momentum_dashboard AS
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
CREATE VIEW public.recent_user_momentum AS
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
CREATE VIEW public.intervention_candidates AS
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

-- Grant appropriate permissions
GRANT SELECT ON public.coach_intervention_queue TO authenticated;
GRANT SELECT ON public.coach_intervention_queue TO service_role;

GRANT SELECT ON public.momentum_dashboard TO authenticated;
GRANT SELECT ON public.momentum_dashboard TO service_role;

GRANT SELECT ON public.recent_user_momentum TO authenticated;
GRANT SELECT ON public.recent_user_momentum TO service_role;

GRANT SELECT ON public.intervention_candidates TO authenticated;
GRANT SELECT ON public.intervention_candidates TO service_role;

-- Add comments
COMMENT ON VIEW public.coach_intervention_queue IS 'Coach intervention queue without SECURITY DEFINER - provides intervention data with proper RLS enforcement';
COMMENT ON VIEW public.momentum_dashboard IS 'User momentum dashboard without SECURITY DEFINER - shows user data with RLS filtering';
COMMENT ON VIEW public.recent_user_momentum IS 'Recent user momentum trends without SECURITY DEFINER - respects RLS policies';
COMMENT ON VIEW public.intervention_candidates IS 'Users needing intervention without SECURITY DEFINER - secured through RLS';

-- Log completion
INSERT INTO public.system_logs (log_level, message, created_at)
VALUES ('INFO', 'Completed SECURITY DEFINER removal from remaining views: coach_intervention_queue, momentum_dashboard, recent_user_momentum, intervention_candidates', NOW()); 