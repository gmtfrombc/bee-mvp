-- Migration: Content Review System for Medical Safety
-- Epic 1.3: Today Feed (AI Daily Brief) - Task T1.3.1.5
-- Created: 2024-12-28

-- Enable RLS
ALTER DATABASE postgres SET row_security = on;

-- Create content review queue table
CREATE TABLE IF NOT EXISTS public.content_review_queue (
    id SERIAL PRIMARY KEY,
    content_id INTEGER REFERENCES public.daily_feed_content(id) ON DELETE SET NULL,
    content_date DATE NOT NULL,
    title TEXT NOT NULL CHECK (length(title) <= 60),
    summary TEXT NOT NULL CHECK (length(summary) <= 200),
    topic_category TEXT NOT NULL CHECK (topic_category IN ('nutrition', 'exercise', 'sleep', 'stress', 'prevention', 'lifestyle')),
    ai_confidence_score NUMERIC(3,2) CHECK (ai_confidence_score >= 0.0 AND ai_confidence_score <= 1.0),
    safety_score NUMERIC(3,2) CHECK (safety_score >= 0.0 AND safety_score <= 1.0),
    flagged_issues JSONB NOT NULL DEFAULT '[]',
    review_status TEXT NOT NULL DEFAULT 'pending_review' CHECK (review_status IN ('pending_review', 'approved', 'rejected', 'escalated', 'auto_approved')),
    reviewer_id TEXT,
    reviewer_email TEXT,
    review_notes TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    escalated_at TIMESTAMP WITH TIME ZONE,
    escalation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create review actions audit table
CREATE TABLE IF NOT EXISTS public.content_review_actions (
    id SERIAL PRIMARY KEY,
    review_item_id INTEGER NOT NULL REFERENCES public.content_review_queue(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL CHECK (action_type IN ('approve', 'reject', 'escalate', 'auto_approve')),
    reviewer_id TEXT NOT NULL,
    reviewer_email TEXT NOT NULL,
    notes TEXT,
    escalation_reason TEXT,
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create review notifications table
CREATE TABLE IF NOT EXISTS public.content_review_notifications (
    id SERIAL PRIMARY KEY,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('new_content_flagged', 'content_approved', 'content_rejected', 'content_escalated')),
    review_item_id INTEGER NOT NULL REFERENCES public.content_review_queue(id) ON DELETE CASCADE,
    content_date DATE NOT NULL,
    title TEXT NOT NULL,
    recipient_email TEXT NOT NULL,
    reviewer_email TEXT,
    escalation_reason TEXT,
    sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_content_review_queue_status ON public.content_review_queue(review_status);
CREATE INDEX IF NOT EXISTS idx_content_review_queue_date ON public.content_review_queue(content_date DESC);
CREATE INDEX IF NOT EXISTS idx_content_review_queue_created ON public.content_review_queue(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_review_queue_reviewer ON public.content_review_queue(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_content_review_queue_safety_score ON public.content_review_queue(safety_score ASC);

CREATE INDEX IF NOT EXISTS idx_content_review_actions_item ON public.content_review_actions(review_item_id);
CREATE INDEX IF NOT EXISTS idx_content_review_actions_timestamp ON public.content_review_actions(action_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_content_review_actions_reviewer ON public.content_review_actions(reviewer_id);

CREATE INDEX IF NOT EXISTS idx_content_review_notifications_type ON public.content_review_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_content_review_notifications_sent ON public.content_review_notifications(sent);
CREATE INDEX IF NOT EXISTS idx_content_review_notifications_recipient ON public.content_review_notifications(recipient_email);

-- Enable Row Level Security (RLS)
ALTER TABLE public.content_review_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_review_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_review_notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for content review queue (restricted to reviewers and service role)
CREATE POLICY "Review queue is accessible to reviewers" ON public.content_review_queue
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'reviewer' OR 
        auth.jwt() ->> 'role' = 'admin' OR
        auth.role() = 'service_role'
    );

-- RLS Policies for review actions (reviewers can only see their own actions)
CREATE POLICY "Reviewers can view own actions" ON public.content_review_actions
    FOR SELECT USING (
        auth.jwt() ->> 'email' = reviewer_email OR
        auth.jwt() ->> 'role' = 'admin' OR
        auth.role() = 'service_role'
    );

CREATE POLICY "Reviewers can insert own actions" ON public.content_review_actions
    FOR INSERT WITH CHECK (
        auth.jwt() ->> 'email' = reviewer_email OR
        auth.role() = 'service_role'
    );

-- RLS Policies for notifications (recipients can see their own notifications)
CREATE POLICY "Recipients can view own notifications" ON public.content_review_notifications
    FOR SELECT USING (
        auth.jwt() ->> 'email' = recipient_email OR
        auth.jwt() ->> 'role' = 'admin' OR
        auth.role() = 'service_role'
    );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_review_queue_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on content_review_queue
CREATE TRIGGER trigger_update_content_review_queue_updated_at
    BEFORE UPDATE ON public.content_review_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_review_queue_updated_at();

-- Function to auto-create review action when review status changes
CREATE OR REPLACE FUNCTION create_review_action_on_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create action if review status changed and reviewer info is present
    IF OLD.review_status != NEW.review_status AND NEW.reviewer_id IS NOT NULL THEN
        INSERT INTO public.content_review_actions (
            review_item_id,
            action_type,
            reviewer_id,
            reviewer_email,
            notes,
            escalation_reason
        ) VALUES (
            NEW.id,
            CASE 
                WHEN NEW.review_status = 'approved' THEN 'approve'
                WHEN NEW.review_status = 'rejected' THEN 'reject'
                WHEN NEW.review_status = 'escalated' THEN 'escalate'
                WHEN NEW.review_status = 'auto_approved' THEN 'auto_approve'
                ELSE NEW.review_status
            END,
            NEW.reviewer_id,
            NEW.reviewer_email,
            NEW.review_notes,
            NEW.escalation_reason
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create review action when status changes
CREATE TRIGGER trigger_create_review_action_on_status_change
    AFTER UPDATE ON public.content_review_queue
    FOR EACH ROW
    EXECUTE FUNCTION create_review_action_on_status_change();

-- Function to create notification when content is flagged for review
CREATE OR REPLACE FUNCTION create_review_notification()
RETURNS TRIGGER AS $$
DECLARE
    review_team_emails TEXT[] := ARRAY['clinical-review@bee-health.com', 'content-safety@bee-health.com'];
    email_address TEXT;
BEGIN
    -- Create notifications for new flagged content
    IF TG_OP = 'INSERT' AND NEW.review_status = 'pending_review' THEN
        FOREACH email_address IN ARRAY review_team_emails LOOP
            INSERT INTO public.content_review_notifications (
                notification_type,
                review_item_id,
                content_date,
                title,
                recipient_email
            ) VALUES (
                'new_content_flagged',
                NEW.id,
                NEW.content_date,
                NEW.title,
                email_address
            );
        END LOOP;
    END IF;
    
    -- Create notifications for status changes
    IF TG_OP = 'UPDATE' AND OLD.review_status != NEW.review_status THEN
        -- Notify review team of approvals/rejections
        IF NEW.review_status IN ('approved', 'rejected') THEN
            FOREACH email_address IN ARRAY review_team_emails LOOP
                INSERT INTO public.content_review_notifications (
                    notification_type,
                    review_item_id,
                    content_date,
                    title,
                    recipient_email,
                    reviewer_email
                ) VALUES (
                    CONCAT('content_', NEW.review_status),
                    NEW.id,
                    NEW.content_date,
                    NEW.title,
                    email_address,
                    NEW.reviewer_email
                );
            END LOOP;
        END IF;
        
        -- Notify escalation team for escalated content
        IF NEW.review_status = 'escalated' THEN
            INSERT INTO public.content_review_notifications (
                notification_type,
                review_item_id,
                content_date,
                title,
                recipient_email,
                reviewer_email,
                escalation_reason
            ) VALUES (
                'content_escalated',
                NEW.id,
                NEW.content_date,
                NEW.title,
                'clinical-director@bee-health.com',
                NEW.reviewer_email,
                NEW.escalation_reason
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create notifications
CREATE TRIGGER trigger_create_review_notification
    AFTER INSERT OR UPDATE ON public.content_review_queue
    FOR EACH ROW
    EXECUTE FUNCTION create_review_notification();

-- Create view for pending reviews dashboard
CREATE OR REPLACE VIEW public.pending_reviews_dashboard AS
SELECT 
    crq.id,
    crq.content_date,
    crq.title,
    crq.summary,
    crq.topic_category,
    crq.ai_confidence_score,
    crq.safety_score,
    crq.flagged_issues,
    crq.review_status,
    crq.created_at,
    DATE_PART('hour', NOW() - crq.created_at) as hours_pending,
    CASE 
        WHEN DATE_PART('hour', NOW() - crq.created_at) > 24 THEN 'urgent'
        WHEN DATE_PART('hour', NOW() - crq.created_at) > 12 THEN 'high'
        WHEN DATE_PART('hour', NOW() - crq.created_at) > 6 THEN 'medium'
        ELSE 'low'
    END as priority_level
FROM public.content_review_queue crq
WHERE crq.review_status = 'pending_review'
ORDER BY crq.safety_score ASC, crq.created_at ASC;

-- Create view for review statistics
CREATE OR REPLACE VIEW public.review_statistics AS
SELECT 
    DATE_TRUNC('day', created_at) as review_date,
    COUNT(*) as total_reviews,
    COUNT(*) FILTER (WHERE review_status = 'approved') as approved_count,
    COUNT(*) FILTER (WHERE review_status = 'rejected') as rejected_count,
    COUNT(*) FILTER (WHERE review_status = 'escalated') as escalated_count,
    COUNT(*) FILTER (WHERE review_status = 'auto_approved') as auto_approved_count,
    COUNT(*) FILTER (WHERE review_status = 'pending_review') as pending_count,
    AVG(safety_score) as avg_safety_score,
    AVG(DATE_PART('hour', reviewed_at - created_at)) FILTER (WHERE reviewed_at IS NOT NULL) as avg_review_time_hours
FROM public.content_review_queue
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY review_date DESC;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.content_review_queue TO authenticated, service_role;
GRANT SELECT, INSERT ON public.content_review_actions TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE ON public.content_review_notifications TO authenticated, service_role;
GRANT SELECT ON public.pending_reviews_dashboard TO authenticated, service_role;
GRANT SELECT ON public.review_statistics TO authenticated, service_role;

-- Grant sequence permissions
GRANT USAGE, SELECT ON SEQUENCE public.content_review_queue_id_seq TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE public.content_review_actions_id_seq TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE public.content_review_notifications_id_seq TO authenticated, service_role;

-- Comments for documentation
COMMENT ON TABLE public.content_review_queue IS 'Queue for content requiring medical safety review by human reviewers';
COMMENT ON TABLE public.content_review_actions IS 'Audit trail of all review actions taken by reviewers';
COMMENT ON TABLE public.content_review_notifications IS 'Notification queue for review team communications';

COMMENT ON COLUMN public.content_review_queue.safety_score IS 'AI-computed safety score (0.0 to 1.0, lower scores need review)';
COMMENT ON COLUMN public.content_review_queue.flagged_issues IS 'JSON array of specific safety issues identified by AI validation';
COMMENT ON COLUMN public.content_review_queue.review_status IS 'Current status of the review process';
COMMENT ON COLUMN public.content_review_queue.escalation_reason IS 'Reason provided when content is escalated to clinical director';

COMMENT ON VIEW public.pending_reviews_dashboard IS 'Dashboard view showing pending reviews with priority levels';
COMMENT ON VIEW public.review_statistics IS 'Aggregated statistics for review team performance monitoring'; 