-- Migration: Enhanced Content Moderation and Approval Workflow
-- Epic 1.3: Today Feed (AI Daily Brief) - Task T1.3.1.8
-- Created: 2024-12-30

-- Enable RLS
ALTER DATABASE postgres SET row_security = on;

-- ============================================================================
-- REVIEWER MANAGEMENT TABLES
-- ============================================================================

-- Create reviewers table
CREATE TABLE IF NOT EXISTS public.content_reviewers (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('medical_reviewer', 'content_reviewer', 'senior_reviewer', 'admin')),
    specializations TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT true,
    max_reviews_per_day INTEGER NOT NULL DEFAULT 10,
    current_reviews_assigned INTEGER NOT NULL DEFAULT 0,
    last_activity TIMESTAMP WITH TIME ZONE,
    performance_rating NUMERIC(3,2) CHECK (performance_rating >= 0.0 AND performance_rating <= 5.0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create review assignments table
CREATE TABLE IF NOT EXISTS public.content_review_assignments (
    id SERIAL PRIMARY KEY,
    review_item_id INTEGER NOT NULL REFERENCES public.content_review_queue(id) ON DELETE CASCADE,
    assigned_to TEXT NOT NULL REFERENCES public.content_reviewers(id) ON DELETE CASCADE,
    assigned_by TEXT NOT NULL REFERENCES public.content_reviewers(id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    due_date TIMESTAMP WITH TIME ZONE,
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned', 'accepted', 'declined', 'reassigned')),
    escalation_level INTEGER DEFAULT 0,
    accepted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- ============================================================================
-- BATCH OPERATIONS TABLES
-- ============================================================================

-- Create batch operations table
CREATE TABLE IF NOT EXISTS public.content_batch_operations (
    id TEXT PRIMARY KEY, -- UUID
    operation_type TEXT NOT NULL CHECK (operation_type IN ('approve', 'reject', 'escalate', 'assign')),
    initiated_by TEXT NOT NULL REFERENCES public.content_reviewers(id),
    total_items INTEGER NOT NULL,
    successful_operations INTEGER DEFAULT 0,
    failed_operations INTEGER DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    escalation_reason TEXT,
    assignee_id TEXT REFERENCES public.content_reviewers(id)
);

-- Create batch operation items table
CREATE TABLE IF NOT EXISTS public.content_batch_operation_items (
    id SERIAL PRIMARY KEY,
    batch_operation_id TEXT NOT NULL REFERENCES public.content_batch_operations(id) ON DELETE CASCADE,
    review_item_id INTEGER NOT NULL REFERENCES public.content_review_queue(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed')),
    error_message TEXT,
    error_code TEXT,
    processed_at TIMESTAMP WITH TIME ZONE
);

-- ============================================================================
-- WORKFLOW AUTOMATION TABLES
-- ============================================================================

-- Create auto approval rules table
CREATE TABLE IF NOT EXISTS public.content_auto_approval_rules (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    conditions JSONB NOT NULL, -- Array of AutoApprovalCondition
    actions JSONB NOT NULL, -- Array of AutoApprovalAction
    created_by TEXT NOT NULL REFERENCES public.content_reviewers(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_triggered TIMESTAMP WITH TIME ZONE,
    trigger_count INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create auto approval rule executions table (for audit)
CREATE TABLE IF NOT EXISTS public.content_auto_approval_executions (
    id SERIAL PRIMARY KEY,
    rule_id INTEGER NOT NULL REFERENCES public.content_auto_approval_rules(id) ON DELETE CASCADE,
    review_item_id INTEGER NOT NULL REFERENCES public.content_review_queue(id) ON DELETE CASCADE,
    execution_result TEXT NOT NULL CHECK (execution_result IN ('conditions_met', 'conditions_not_met', 'action_executed', 'action_failed')),
    conditions_evaluated JSONB NOT NULL,
    actions_taken JSONB,
    error_message TEXT,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- ENHANCED NOTIFICATIONS TABLES
-- ============================================================================

-- Create enhanced notifications table
CREATE TABLE IF NOT EXISTS public.content_enhanced_notifications (
    id SERIAL PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('assignment', 'reminder', 'escalation', 'sla_breach', 'batch_complete', 'workflow_alert')),
    review_item_id INTEGER REFERENCES public.content_review_queue(id) ON DELETE CASCADE,
    batch_operation_id TEXT REFERENCES public.content_batch_operations(id) ON DELETE CASCADE,
    recipient_id TEXT NOT NULL REFERENCES public.content_reviewers(id) ON DELETE CASCADE,
    recipient_email TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    action_required BOOLEAN DEFAULT false,
    action_url TEXT,
    scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent BOOLEAN DEFAULT false,
    sent_at TIMESTAMP WITH TIME ZONE,
    read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- ANALYTICS AND REPORTING TABLES
-- ============================================================================

-- Create review statistics summary table
CREATE TABLE IF NOT EXISTS public.content_review_analytics (
    id SERIAL PRIMARY KEY,
    analysis_date DATE NOT NULL,
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    total_content_generated INTEGER DEFAULT 0,
    total_reviews_required INTEGER DEFAULT 0,
    auto_approved_count INTEGER DEFAULT 0,
    manual_approved_count INTEGER DEFAULT 0,
    rejected_count INTEGER DEFAULT 0,
    escalated_count INTEGER DEFAULT 0,
    average_review_time_hours NUMERIC(10,2),
    sla_compliance_rate NUMERIC(5,2),
    automation_rate NUMERIC(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(analysis_date, period_start, period_end)
);

-- Create reviewer performance metrics table
CREATE TABLE IF NOT EXISTS public.reviewer_performance_metrics (
    id SERIAL PRIMARY KEY,
    reviewer_id TEXT NOT NULL REFERENCES public.content_reviewers(id) ON DELETE CASCADE,
    analysis_date DATE NOT NULL,
    reviews_completed INTEGER DEFAULT 0,
    average_review_time_hours NUMERIC(10,2),
    approval_rate NUMERIC(5,2),
    rejection_rate NUMERIC(5,2),
    escalation_rate NUMERIC(5,2),
    quality_score NUMERIC(3,2),
    workload_percentage NUMERIC(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reviewer_id, analysis_date)
);

-- Create admin alerts table
CREATE TABLE IF NOT EXISTS public.content_admin_alerts (
    id TEXT PRIMARY KEY, -- UUID
    type TEXT NOT NULL CHECK (type IN ('sla_breach', 'reviewer_overload', 'quality_decline', 'system_error')),
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    action_required BOOLEAN DEFAULT false,
    related_review_item_id INTEGER REFERENCES public.content_review_queue(id),
    related_reviewer_id TEXT REFERENCES public.content_reviewers(id),
    resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by TEXT REFERENCES public.content_reviewers(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Reviewer management indexes
CREATE INDEX IF NOT EXISTS idx_content_reviewers_active ON public.content_reviewers(is_active);
CREATE INDEX IF NOT EXISTS idx_content_reviewers_role ON public.content_reviewers(role);
CREATE INDEX IF NOT EXISTS idx_content_reviewers_workload ON public.content_reviewers(current_reviews_assigned, max_reviews_per_day);

-- Review assignments indexes
CREATE INDEX IF NOT EXISTS idx_content_review_assignments_assignee ON public.content_review_assignments(assigned_to);
CREATE INDEX IF NOT EXISTS idx_content_review_assignments_status ON public.content_review_assignments(status);
CREATE INDEX IF NOT EXISTS idx_content_review_assignments_due_date ON public.content_review_assignments(due_date);
CREATE INDEX IF NOT EXISTS idx_content_review_assignments_priority ON public.content_review_assignments(priority);

-- Batch operations indexes
CREATE INDEX IF NOT EXISTS idx_content_batch_operations_status ON public.content_batch_operations(status);
CREATE INDEX IF NOT EXISTS idx_content_batch_operations_initiated_by ON public.content_batch_operations(initiated_by);
CREATE INDEX IF NOT EXISTS idx_content_batch_operations_started_at ON public.content_batch_operations(started_at DESC);

-- Auto approval rules indexes
CREATE INDEX IF NOT EXISTS idx_content_auto_approval_rules_active ON public.content_auto_approval_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_content_auto_approval_rules_created_by ON public.content_auto_approval_rules(created_by);

-- Enhanced notifications indexes
CREATE INDEX IF NOT EXISTS idx_content_enhanced_notifications_recipient ON public.content_enhanced_notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_content_enhanced_notifications_type ON public.content_enhanced_notifications(type);
CREATE INDEX IF NOT EXISTS idx_content_enhanced_notifications_sent ON public.content_enhanced_notifications(sent);
CREATE INDEX IF NOT EXISTS idx_content_enhanced_notifications_read ON public.content_enhanced_notifications(read);
CREATE INDEX IF NOT EXISTS idx_content_enhanced_notifications_scheduled ON public.content_enhanced_notifications(scheduled_for);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_content_review_analytics_date ON public.content_review_analytics(analysis_date DESC);
CREATE INDEX IF NOT EXISTS idx_reviewer_performance_metrics_reviewer ON public.reviewer_performance_metrics(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviewer_performance_metrics_date ON public.reviewer_performance_metrics(analysis_date DESC);

-- Admin alerts indexes
CREATE INDEX IF NOT EXISTS idx_content_admin_alerts_severity ON public.content_admin_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_content_admin_alerts_resolved ON public.content_admin_alerts(resolved);
CREATE INDEX IF NOT EXISTS idx_content_admin_alerts_created ON public.content_admin_alerts(created_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on all new tables
ALTER TABLE public.content_reviewers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_review_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_batch_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_batch_operation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_auto_approval_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_auto_approval_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_enhanced_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_review_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviewer_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_admin_alerts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for reviewers (self and admin access)
CREATE POLICY "Reviewers can view own profile and admins can view all" ON public.content_reviewers
    FOR SELECT USING (
        auth.jwt() ->> 'email' = email OR 
        auth.jwt() ->> 'role' = 'admin' OR
        auth.role() = 'service_role'
    );

CREATE POLICY "Only admins can modify reviewers" ON public.content_reviewers
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'admin' OR
        auth.role() = 'service_role'
    );

-- RLS Policies for assignments (assignee and assigner access)
CREATE POLICY "Assignment visibility" ON public.content_review_assignments
    FOR SELECT USING (
        auth.jwt() ->> 'email' IN (
            SELECT email FROM public.content_reviewers WHERE id IN (assigned_to, assigned_by)
        ) OR
        auth.jwt() ->> 'role' = 'admin' OR
        auth.role() = 'service_role'
    );

-- RLS Policies for batch operations (initiator and admin access)
CREATE POLICY "Batch operations access" ON public.content_batch_operations
    FOR ALL USING (
        auth.jwt() ->> 'email' = (
            SELECT email FROM public.content_reviewers WHERE id = initiated_by
        ) OR
        auth.jwt() ->> 'role' = 'admin' OR
        auth.role() = 'service_role'
    );

-- RLS Policies for notifications (recipient access)
CREATE POLICY "Notification recipient access" ON public.content_enhanced_notifications
    FOR SELECT USING (
        auth.jwt() ->> 'email' = recipient_email OR
        auth.jwt() ->> 'role' = 'admin' OR
        auth.role() = 'service_role'
    );

-- RLS Policies for analytics (admin and senior reviewer access)
CREATE POLICY "Analytics access" ON public.content_review_analytics
    FOR SELECT USING (
        auth.jwt() ->> 'role' IN ('admin', 'senior_reviewer') OR
        auth.role() = 'service_role'
    );

-- ============================================================================
-- TRIGGERS AND FUNCTIONS
-- ============================================================================

-- Function to update reviewer updated_at timestamp
CREATE OR REPLACE FUNCTION update_reviewer_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for reviewer updates
CREATE TRIGGER trigger_update_content_reviewers_updated_at
    BEFORE UPDATE ON public.content_reviewers
    FOR EACH ROW
    EXECUTE FUNCTION update_reviewer_updated_at();

-- Function to update reviewer workload when assignments change
CREATE OR REPLACE FUNCTION update_reviewer_workload()
RETURNS TRIGGER AS $$
BEGIN
    -- Update current_reviews_assigned count
    IF TG_OP = 'INSERT' AND NEW.status = 'assigned' THEN
        UPDATE public.content_reviewers 
        SET current_reviews_assigned = current_reviews_assigned + 1,
            last_activity = NOW()
        WHERE id = NEW.assigned_to;
    ELSIF TG_OP = 'UPDATE' THEN
        -- If status changed from assigned to something else, decrease count
        IF OLD.status = 'assigned' AND NEW.status != 'assigned' THEN
            UPDATE public.content_reviewers 
            SET current_reviews_assigned = GREATEST(current_reviews_assigned - 1, 0),
                last_activity = NOW()
            WHERE id = OLD.assigned_to;
        -- If status changed to assigned, increase count
        ELSIF OLD.status != 'assigned' AND NEW.status = 'assigned' THEN
            UPDATE public.content_reviewers 
            SET current_reviews_assigned = current_reviews_assigned + 1,
                last_activity = NOW()
            WHERE id = NEW.assigned_to;
        END IF;
    ELSIF TG_OP = 'DELETE' AND OLD.status = 'assigned' THEN
        UPDATE public.content_reviewers 
        SET current_reviews_assigned = GREATEST(current_reviews_assigned - 1, 0)
        WHERE id = OLD.assigned_to;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger for assignment workload updates
CREATE TRIGGER trigger_update_reviewer_workload
    AFTER INSERT OR UPDATE OR DELETE ON public.content_review_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_reviewer_workload();

-- Function to auto-create admin alerts for SLA breaches
CREATE OR REPLACE FUNCTION check_sla_breaches()
RETURNS TRIGGER AS $$
DECLARE
    due_date_threshold TIMESTAMP WITH TIME ZONE;
    alert_id TEXT;
BEGIN
    -- Check if assignment is overdue (past due date)
    IF NEW.due_date IS NOT NULL AND NEW.due_date < NOW() AND NEW.status = 'assigned' THEN
        -- Generate UUID for alert
        alert_id := gen_random_uuid()::TEXT;
        
        INSERT INTO public.content_admin_alerts (
            id,
            type,
            severity,
            title,
            description,
            action_required,
            related_review_item_id,
            related_reviewer_id
        ) VALUES (
            alert_id,
            'sla_breach',
            'high',
            'Review SLA Breach',
            format('Review assignment for content "%s" is overdue. Due: %s, Assigned to: %s',
                (SELECT title FROM public.content_review_queue WHERE id = NEW.review_item_id),
                NEW.due_date,
                (SELECT email FROM public.content_reviewers WHERE id = NEW.assigned_to)
            ),
            true,
            NEW.review_item_id,
            NEW.assigned_to
        );
        
        -- Create notification for admin
        INSERT INTO public.content_enhanced_notifications (
            type,
            review_item_id,
            recipient_id,
            recipient_email,
            priority,
            title,
            message,
            action_required
        ) SELECT 
            'sla_breach',
            NEW.review_item_id,
            r.id,
            r.email,
            'urgent',
            'SLA Breach Alert',
            format('Review assignment is overdue: %s', 
                (SELECT title FROM public.content_review_queue WHERE id = NEW.review_item_id)
            ),
            true
        FROM public.content_reviewers r 
        WHERE r.role = 'admin' AND r.is_active = true;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for SLA breach detection
CREATE TRIGGER trigger_check_sla_breaches
    AFTER UPDATE ON public.content_review_assignments
    FOR EACH ROW
    EXECUTE FUNCTION check_sla_breaches();

-- Function to increment auto approval rule trigger count
CREATE OR REPLACE FUNCTION increment_rule_trigger_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.content_auto_approval_rules 
    SET trigger_count = trigger_count + 1,
        last_triggered = NOW()
    WHERE id = NEW.rule_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for rule execution tracking
CREATE TRIGGER trigger_increment_rule_trigger_count
    AFTER INSERT ON public.content_auto_approval_executions
    FOR EACH ROW
    EXECUTE FUNCTION increment_rule_trigger_count();

-- ============================================================================
-- INITIAL DATA SETUP
-- ============================================================================

-- Insert default admin reviewer (will be updated with real data)
INSERT INTO public.content_reviewers (
    id,
    email,
    name,
    role,
    specializations,
    max_reviews_per_day
) VALUES (
    'admin-default',
    'admin@bee-health.com',
    'System Administrator',
    'admin',
    ARRAY['general', 'medical', 'content'],
    50
) ON CONFLICT (id) DO NOTHING;

-- Insert default auto-approval rule for high-confidence content
INSERT INTO public.content_auto_approval_rules (
    name,
    description,
    conditions,
    actions,
    created_by
) VALUES (
    'High Confidence Auto-Approval',
    'Automatically approve content with high AI confidence and safety scores',
    '[{
        "field": "safety_score",
        "operator": "gte",
        "value": 0.95
    }, {
        "field": "ai_confidence_score", 
        "operator": "gte",
        "value": 0.9
    }, {
        "field": "flagged_issues_count",
        "operator": "eq",
        "value": 0
    }]'::jsonb,
    '[{
        "type": "auto_approve",
        "parameters": {
            "reviewer_id": "system",
            "notes": "Auto-approved based on high confidence and safety scores"
        }
    }]'::jsonb,
    'admin-default'
) ON CONFLICT DO NOTHING;

-- Create view for current review queue with assignment info
CREATE OR REPLACE VIEW public.review_queue_with_assignments AS
SELECT 
    rq.*,
    ra.assigned_to,
    ra.assigned_by,
    ra.assigned_at,
    ra.due_date,
    ra.priority,
    ra.status as assignment_status,
    r.name as assignee_name,
    r.email as assignee_email
FROM public.content_review_queue rq
LEFT JOIN public.content_review_assignments ra ON rq.id = ra.review_item_id 
    AND ra.status IN ('assigned', 'accepted')
LEFT JOIN public.content_reviewers r ON ra.assigned_to = r.id;

-- Grant permissions for the view
GRANT SELECT ON public.review_queue_with_assignments TO authenticated;
GRANT SELECT ON public.review_queue_with_assignments TO service_role; 