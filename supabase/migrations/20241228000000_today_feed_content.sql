-- Migration: Today Feed Content Tables
-- Epic 1.3: Today Feed (AI Daily Brief)
-- Created: 2024-12-28

-- Enable RLS
ALTER DATABASE postgres SET row_security = on;

-- Create daily_feed_content table
CREATE TABLE IF NOT EXISTS public.daily_feed_content (
    id SERIAL PRIMARY KEY,
    content_date DATE NOT NULL UNIQUE,
    title TEXT NOT NULL CHECK (length(title) <= 60),
    summary TEXT NOT NULL CHECK (length(summary) <= 200),
    content_url TEXT,
    external_link TEXT,
    topic_category TEXT NOT NULL CHECK (topic_category IN ('nutrition', 'exercise', 'sleep', 'stress', 'prevention', 'lifestyle')),
    ai_confidence_score NUMERIC(3,2) CHECK (ai_confidence_score >= 0.0 AND ai_confidence_score <= 1.0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_daily_feed_content_date ON public.daily_feed_content(content_date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_feed_content_topic ON public.daily_feed_content(topic_category);
CREATE INDEX IF NOT EXISTS idx_daily_feed_content_confidence ON public.daily_feed_content(ai_confidence_score DESC);

-- Create user_content_interactions table
CREATE TABLE IF NOT EXISTS public.user_content_interactions (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content_id INTEGER NOT NULL REFERENCES public.daily_feed_content(id) ON DELETE CASCADE,
    interaction_type TEXT NOT NULL CHECK (interaction_type IN ('view', 'click', 'share', 'bookmark')),
    interaction_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_duration INTEGER CHECK (session_duration >= 0), -- seconds spent reading
    UNIQUE(user_id, content_id, interaction_type)
);

-- Create indexes for user interactions
CREATE INDEX IF NOT EXISTS idx_user_content_interactions_user ON public.user_content_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_content_interactions_content ON public.user_content_interactions(content_id);
CREATE INDEX IF NOT EXISTS idx_user_content_interactions_type ON public.user_content_interactions(interaction_type);
CREATE INDEX IF NOT EXISTS idx_user_content_interactions_timestamp ON public.user_content_interactions(interaction_timestamp DESC);

-- Create content_analytics table (for aggregated metrics)
CREATE TABLE IF NOT EXISTS public.content_analytics (
    id SERIAL PRIMARY KEY,
    content_id INTEGER NOT NULL REFERENCES public.daily_feed_content(id) ON DELETE CASCADE UNIQUE,
    total_views INTEGER DEFAULT 0,
    total_clicks INTEGER DEFAULT 0,
    total_shares INTEGER DEFAULT 0,
    total_bookmarks INTEGER DEFAULT 0,
    unique_viewers INTEGER DEFAULT 0,
    avg_session_duration NUMERIC(5,2) DEFAULT 0,
    engagement_rate NUMERIC(3,2) DEFAULT 0 CHECK (engagement_rate >= 0.0 AND engagement_rate <= 1.0),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for analytics
CREATE INDEX IF NOT EXISTS idx_content_analytics_content ON public.content_analytics(content_id);
CREATE INDEX IF NOT EXISTS idx_content_analytics_engagement ON public.content_analytics(engagement_rate DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.daily_feed_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_content_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_analytics ENABLE ROW LEVEL SECURITY;

-- RLS Policies for daily_feed_content (publicly readable)
CREATE POLICY "Content is publicly readable" ON public.daily_feed_content
    FOR SELECT USING (true);

-- RLS Policies for user_content_interactions (users can only see their own)
CREATE POLICY "Users can view own content interactions" ON public.user_content_interactions
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for content_analytics (publicly readable for aggregated data)
CREATE POLICY "Analytics are publicly readable" ON public.content_analytics
    FOR SELECT USING (true);

-- Function to update content analytics when interactions change
CREATE OR REPLACE FUNCTION update_content_analytics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update analytics for the affected content
    INSERT INTO public.content_analytics (content_id, total_views, total_clicks, total_shares, total_bookmarks, unique_viewers, avg_session_duration, engagement_rate, updated_at)
    SELECT 
        NEW.content_id,
        COUNT(*) FILTER (WHERE interaction_type = 'view') as total_views,
        COUNT(*) FILTER (WHERE interaction_type = 'click') as total_clicks,
        COUNT(*) FILTER (WHERE interaction_type = 'share') as total_shares,
        COUNT(*) FILTER (WHERE interaction_type = 'bookmark') as total_bookmarks,
        COUNT(DISTINCT user_id) as unique_viewers,
        COALESCE(AVG(session_duration) FILTER (WHERE session_duration IS NOT NULL), 0) as avg_session_duration,
        LEAST(1.0, GREATEST(0.0, 
            COALESCE(COUNT(*) FILTER (WHERE interaction_type = 'click')::numeric / 
                    NULLIF(COUNT(*) FILTER (WHERE interaction_type = 'view'), 0), 0)
        )) as engagement_rate,
        NOW()
    FROM public.user_content_interactions 
    WHERE content_id = NEW.content_id
    GROUP BY content_id
    ON CONFLICT (content_id) 
    DO UPDATE SET
        total_views = EXCLUDED.total_views,
        total_clicks = EXCLUDED.total_clicks,
        total_shares = EXCLUDED.total_shares,
        total_bookmarks = EXCLUDED.total_bookmarks,
        unique_viewers = EXCLUDED.unique_viewers,
        avg_session_duration = EXCLUDED.avg_session_duration,
        engagement_rate = EXCLUDED.engagement_rate,
        updated_at = EXCLUDED.updated_at;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update analytics on interaction changes
CREATE TRIGGER trigger_update_content_analytics
    AFTER INSERT OR UPDATE ON public.user_content_interactions
    FOR EACH ROW
    EXECUTE FUNCTION update_content_analytics();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on daily_feed_content
CREATE TRIGGER trigger_update_daily_feed_content_updated_at
    BEFORE UPDATE ON public.daily_feed_content
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create a view for easy content performance monitoring
CREATE OR REPLACE VIEW public.daily_content_performance AS
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
    COALESCE(ca.avg_session_duration, 0) as avg_session_duration,
    COALESCE(ca.engagement_rate, 0) as engagement_rate,
    dc.created_at,
    dc.updated_at
FROM public.daily_feed_content dc
LEFT JOIN public.content_analytics ca ON dc.id = ca.content_id
ORDER BY dc.content_date DESC;

-- Grant necessary permissions for authenticated users
GRANT SELECT ON public.daily_feed_content TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_content_interactions TO authenticated;
GRANT SELECT ON public.content_analytics TO authenticated;
GRANT SELECT ON public.daily_content_performance TO authenticated;

-- Grant permissions for service role (for the Cloud Run service)
GRANT ALL ON public.daily_feed_content TO service_role;
GRANT ALL ON public.user_content_interactions TO service_role;
GRANT ALL ON public.content_analytics TO service_role;
GRANT ALL ON public.daily_content_performance TO service_role;

-- Grant sequence permissions
GRANT USAGE, SELECT ON SEQUENCE public.daily_feed_content_id_seq TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE public.user_content_interactions_id_seq TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE public.content_analytics_id_seq TO authenticated, service_role;

-- Comments for documentation
COMMENT ON TABLE public.daily_feed_content IS 'Daily AI-generated health content for the Today Feed feature';
COMMENT ON TABLE public.user_content_interactions IS 'User interactions with daily feed content (views, clicks, shares, bookmarks)';
COMMENT ON TABLE public.content_analytics IS 'Aggregated analytics and metrics for content performance';
COMMENT ON VIEW public.daily_content_performance IS 'Consolidated view of content performance metrics for monitoring and analysis';

COMMENT ON COLUMN public.daily_feed_content.content_date IS 'Date this content is published for (YYYY-MM-DD)';
COMMENT ON COLUMN public.daily_feed_content.title IS 'Engaging headline for the content (max 60 characters)';
COMMENT ON COLUMN public.daily_feed_content.summary IS 'Brief summary of the content (max 200 characters)';
COMMENT ON COLUMN public.daily_feed_content.ai_confidence_score IS 'AI model confidence score (0.0 to 1.0)';
COMMENT ON COLUMN public.daily_feed_content.topic_category IS 'Health topic category (nutrition, exercise, sleep, stress, prevention, lifestyle)';

COMMENT ON COLUMN public.user_content_interactions.interaction_type IS 'Type of interaction (view, click, share, bookmark)';
COMMENT ON COLUMN public.user_content_interactions.session_duration IS 'Time spent reading content in seconds';

COMMENT ON COLUMN public.content_analytics.engagement_rate IS 'Click-through rate (clicks/views)';
COMMENT ON COLUMN public.content_analytics.avg_session_duration IS 'Average time users spend reading the content';

-- Insert sample data for testing (will be replaced by actual AI-generated content)
INSERT INTO public.daily_feed_content (content_date, title, summary, topic_category, ai_confidence_score) VALUES
('2024-12-28', 'The Hidden Power of Colorful Eating', 'Different colored fruits and vegetables contain unique antioxidants that protect different parts of your body. Aim for a rainbow of colors on your plate each day.', 'nutrition', 0.85),
('2024-12-29', 'The 2-Minute Activity Break Miracle', 'Just 2 minutes of movement every hour can counteract the negative effects of prolonged sitting. Even simple stretches or walking in place counts.', 'exercise', 0.90),
('2024-12-30', 'The 90-Minute Sleep Cycle Secret', 'Your brain naturally cycles through sleep stages every 90 minutes. Timing your wake-up to align with these cycles helps you feel more refreshed.', 'sleep', 0.88)
ON CONFLICT (content_date) DO NOTHING; 