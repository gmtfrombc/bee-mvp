-- Create momentum meter tables for BEE app

-- Daily engagement scores table
CREATE TABLE IF NOT EXISTS public.daily_engagement_scores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    score_date DATE NOT NULL,
    final_score DECIMAL(5,2) DEFAULT 0.0,
    momentum_state TEXT DEFAULT 'NeedsCare' CHECK (momentum_state IN ('Rising', 'Steady', 'NeedsCare')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, score_date)
);

-- NOTE: engagement_events table is already created in 20241201000000_engagement_events.sql
-- No need to recreate it here

-- Momentum notifications table
CREATE TABLE IF NOT EXISTS public.momentum_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'
);

-- Enable Row Level Security
ALTER TABLE public.daily_engagement_scores ENABLE ROW LEVEL SECURITY;
-- NOTE: RLS for engagement_events is already enabled in 20241201000000_engagement_events.sql
ALTER TABLE public.momentum_notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for daily_engagement_scores
CREATE POLICY "Users can view their own engagement scores" ON public.daily_engagement_scores
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own engagement scores" ON public.daily_engagement_scores
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own engagement scores" ON public.daily_engagement_scores
    FOR UPDATE USING (auth.uid() = user_id);

-- NOTE: RLS policies for engagement_events are already created in 20241201000000_engagement_events.sql
-- No need to duplicate them here

-- Create RLS policies for momentum_notifications
CREATE POLICY "Users can view their own notifications" ON public.momentum_notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON public.momentum_notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_daily_engagement_scores_user_date ON public.daily_engagement_scores(user_id, score_date);
-- NOTE: Indexes for engagement_events are already created in 20241201000000_engagement_events.sql
CREATE INDEX IF NOT EXISTS idx_momentum_notifications_user_sent ON public.momentum_notifications(user_id, sent_at);

-- Insert some sample data for testing (optional)
-- This will only work if there are authenticated users
-- INSERT INTO public.daily_engagement_scores (user_id, score_date, final_score, momentum_state)
-- VALUES 
--     (auth.uid(), CURRENT_DATE, 75.5, 'Rising'),
--     (auth.uid(), CURRENT_DATE - INTERVAL '1 day', 65.0, 'Steady'),
--     (auth.uid(), CURRENT_DATE - INTERVAL '2 days', 45.0, 'NeedsCare')
-- ON CONFLICT (user_id, score_date) DO NOTHING; 