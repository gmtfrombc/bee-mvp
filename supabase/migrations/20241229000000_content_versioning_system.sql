-- Migration: Content Versioning and Storage System
-- Epic 1.3: Today Feed (AI Daily Brief)
-- Task: T1.3.1.7 - Implement content storage and versioning system
-- Created: 2024-12-29

-- Create content_versions table for version history
CREATE TABLE IF NOT EXISTS public.content_versions (
    id SERIAL PRIMARY KEY,
    content_id INTEGER NOT NULL REFERENCES public.daily_feed_content(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    title TEXT NOT NULL CHECK (length(title) <= 60),
    summary TEXT NOT NULL CHECK (length(summary) <= 200),
    content_url TEXT,
    external_link TEXT,
    topic_category TEXT NOT NULL CHECK (topic_category IN ('nutrition', 'exercise', 'sleep', 'stress', 'prevention', 'lifestyle')),
    ai_confidence_score NUMERIC(3,2) CHECK (ai_confidence_score >= 0.0 AND ai_confidence_score <= 1.0),
    change_type TEXT NOT NULL CHECK (change_type IN ('initial', 'update', 'rollback', 'regeneration')),
    change_reason TEXT, -- Why this version was created
    changed_by TEXT, -- User/system that made the change
    is_active BOOLEAN DEFAULT false, -- Only one version should be active per content
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(content_id, version_number)
);

-- Create indexes for content versions
CREATE INDEX IF NOT EXISTS idx_content_versions_content_id ON public.content_versions(content_id);
CREATE INDEX IF NOT EXISTS idx_content_versions_version ON public.content_versions(content_id, version_number DESC);
CREATE INDEX IF NOT EXISTS idx_content_versions_active ON public.content_versions(content_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_content_versions_created ON public.content_versions(created_at DESC);

-- Create content_change_log table for audit trail
CREATE TABLE IF NOT EXISTS public.content_change_log (
    id SERIAL PRIMARY KEY,
    content_id INTEGER NOT NULL REFERENCES public.daily_feed_content(id) ON DELETE CASCADE,
    from_version INTEGER,
    to_version INTEGER NOT NULL,
    action_type TEXT NOT NULL CHECK (action_type IN ('create', 'update', 'rollback', 'publish', 'unpublish')),
    changed_by TEXT NOT NULL,
    change_notes TEXT,
    old_values JSONB, -- Store old field values for rollback
    new_values JSONB, -- Store new field values
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for change log
CREATE INDEX IF NOT EXISTS idx_content_change_log_content_id ON public.content_change_log(content_id);
CREATE INDEX IF NOT EXISTS idx_content_change_log_created ON public.content_change_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_change_log_action ON public.content_change_log(action_type);

-- Create content_delivery_optimization table for CDN and caching
CREATE TABLE IF NOT EXISTS public.content_delivery_optimization (
    id SERIAL PRIMARY KEY,
    content_id INTEGER NOT NULL REFERENCES public.daily_feed_content(id) ON DELETE CASCADE UNIQUE,
    etag TEXT NOT NULL, -- For HTTP caching
    last_modified TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cache_control TEXT DEFAULT 'public, max-age=86400', -- 24 hours cache
    compression_type TEXT CHECK (compression_type IN ('gzip', 'br', 'none')) DEFAULT 'gzip',
    content_size INTEGER, -- Size in bytes
    cdn_url TEXT, -- CDN URL if using external CDN
    cache_hits INTEGER DEFAULT 0,
    cache_misses INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for delivery optimization
CREATE INDEX IF NOT EXISTS idx_content_delivery_optimization_content ON public.content_delivery_optimization(content_id);
CREATE INDEX IF NOT EXISTS idx_content_delivery_optimization_etag ON public.content_delivery_optimization(etag);

-- Enable RLS for new tables
ALTER TABLE public.content_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_change_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_delivery_optimization ENABLE ROW LEVEL SECURITY;

-- RLS Policies for content_versions (publicly readable)
CREATE POLICY "Content versions are publicly readable" ON public.content_versions
    FOR SELECT USING (true);

-- RLS Policies for content_change_log (publicly readable for transparency)
CREATE POLICY "Content change log is publicly readable" ON public.content_change_log
    FOR SELECT USING (true);

-- RLS Policies for content_delivery_optimization (publicly readable)
CREATE POLICY "Content delivery optimization is publicly readable" ON public.content_delivery_optimization
    FOR SELECT USING (true);

-- Function to create new content version
CREATE OR REPLACE FUNCTION create_content_version(
    p_content_id INTEGER,
    p_change_type TEXT,
    p_change_reason TEXT DEFAULT NULL,
    p_changed_by TEXT DEFAULT 'system'
) RETURNS INTEGER AS $$
DECLARE
    v_version_number INTEGER;
    v_content_record RECORD;
    v_version_id INTEGER;
BEGIN
    -- Get current content
    SELECT * INTO v_content_record FROM public.daily_feed_content WHERE id = p_content_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Content with id % not found', p_content_id;
    END IF;
    
    -- Get next version number
    SELECT COALESCE(MAX(version_number), 0) + 1 
    INTO v_version_number 
    FROM public.content_versions 
    WHERE content_id = p_content_id;
    
    -- Deactivate all previous versions
    UPDATE public.content_versions 
    SET is_active = false 
    WHERE content_id = p_content_id;
    
    -- Create new version
    INSERT INTO public.content_versions (
        content_id, version_number, title, summary, content_url, external_link,
        topic_category, ai_confidence_score, change_type, change_reason, 
        changed_by, is_active
    ) VALUES (
        p_content_id, v_version_number, v_content_record.title, v_content_record.summary,
        v_content_record.content_url, v_content_record.external_link, v_content_record.topic_category,
        v_content_record.ai_confidence_score, p_change_type, p_change_reason, p_changed_by, true
    ) RETURNING id INTO v_version_id;
    
    -- Log the change
    INSERT INTO public.content_change_log (
        content_id, to_version, action_type, changed_by, change_notes, new_values
    ) VALUES (
        p_content_id, v_version_number, p_change_type, p_changed_by, p_change_reason,
        jsonb_build_object(
            'title', v_content_record.title,
            'summary', v_content_record.summary,
            'topic_category', v_content_record.topic_category,
            'ai_confidence_score', v_content_record.ai_confidence_score
        )
    );
    
    RETURN v_version_id;
END;
$$ LANGUAGE plpgsql;

-- Function to rollback to previous version
CREATE OR REPLACE FUNCTION rollback_content_version(
    p_content_id INTEGER,
    p_target_version INTEGER,
    p_changed_by TEXT DEFAULT 'system',
    p_rollback_reason TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_target_version RECORD;
    v_current_version INTEGER;
    v_new_version_number INTEGER;
BEGIN
    -- Get target version data
    SELECT * INTO v_target_version 
    FROM public.content_versions 
    WHERE content_id = p_content_id AND version_number = p_target_version;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Version % not found for content %', p_target_version, p_content_id;
    END IF;
    
    -- Get current active version
    SELECT version_number INTO v_current_version
    FROM public.content_versions 
    WHERE content_id = p_content_id AND is_active = true;
    
    -- Update the main content table
    UPDATE public.daily_feed_content SET
        title = v_target_version.title,
        summary = v_target_version.summary,
        content_url = v_target_version.content_url,
        external_link = v_target_version.external_link,
        topic_category = v_target_version.topic_category,
        ai_confidence_score = v_target_version.ai_confidence_score,
        updated_at = NOW()
    WHERE id = p_content_id;
    
    -- Create new version entry for the rollback
    SELECT create_content_version(
        p_content_id, 
        'rollback', 
        COALESCE(p_rollback_reason, 'Rolled back to version ' || p_target_version), 
        p_changed_by
    ) INTO v_new_version_number;
    
    -- Log the rollback in change log
    INSERT INTO public.content_change_log (
        content_id, from_version, to_version, action_type, 
        changed_by, change_notes, old_values, new_values
    ) VALUES (
        p_content_id, v_current_version, v_new_version_number, 'rollback',
        p_changed_by, p_rollback_reason,
        (SELECT new_values FROM public.content_change_log 
         WHERE content_id = p_content_id AND to_version = v_current_version 
         ORDER BY created_at DESC LIMIT 1),
        jsonb_build_object(
            'title', v_target_version.title,
            'summary', v_target_version.summary,
            'topic_category', v_target_version.topic_category,
            'ai_confidence_score', v_target_version.ai_confidence_score,
            'rollback_to_version', p_target_version
        )
    );
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to generate ETag for content caching
CREATE OR REPLACE FUNCTION generate_content_etag(p_content_id INTEGER) 
RETURNS TEXT AS $$
DECLARE
    v_content_hash TEXT;
    v_version INTEGER;
BEGIN
    -- Get current active version
    SELECT version_number INTO v_version
    FROM public.content_versions 
    WHERE content_id = p_content_id AND is_active = true;
    
    -- Generate hash based on content and version
    SELECT encode(digest(
        CONCAT(title, summary, topic_category, ai_confidence_score::text, v_version::text), 
        'sha256'
    ), 'hex') INTO v_content_hash
    FROM public.daily_feed_content 
    WHERE id = p_content_id;
    
    RETURN SUBSTRING(v_content_hash, 1, 32); -- Return first 32 chars
END;
$$ LANGUAGE plpgsql;

-- Function to update content delivery optimization
CREATE OR REPLACE FUNCTION update_content_delivery_optimization(p_content_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_etag TEXT;
    v_content_size INTEGER;
BEGIN
    -- Generate new ETag
    v_etag := generate_content_etag(p_content_id);
    
    -- Calculate content size (rough estimate)
    SELECT length(title) + length(summary) + 100 INTO v_content_size
    FROM public.daily_feed_content 
    WHERE id = p_content_id;
    
    -- Upsert delivery optimization record
    INSERT INTO public.content_delivery_optimization (
        content_id, etag, last_modified, content_size, updated_at
    ) VALUES (
        p_content_id, v_etag, NOW(), v_content_size, NOW()
    )
    ON CONFLICT (content_id) DO UPDATE SET
        etag = EXCLUDED.etag,
        last_modified = EXCLUDED.last_modified,
        content_size = EXCLUDED.content_size,
        updated_at = EXCLUDED.updated_at;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create initial version when content is created
CREATE OR REPLACE FUNCTION trigger_create_initial_version()
RETURNS TRIGGER AS $$
BEGIN
    -- Create initial version
    PERFORM create_content_version(NEW.id, 'initial', 'Initial content creation', 'system');
    
    -- Update delivery optimization
    PERFORM update_content_delivery_optimization(NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create version when content is updated
CREATE OR REPLACE FUNCTION trigger_create_update_version()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create version if content actually changed
    IF OLD.title != NEW.title OR OLD.summary != NEW.summary OR 
       OLD.topic_category != NEW.topic_category OR OLD.ai_confidence_score != NEW.ai_confidence_score OR
       COALESCE(OLD.content_url, '') != COALESCE(NEW.content_url, '') OR
       COALESCE(OLD.external_link, '') != COALESCE(NEW.external_link, '') THEN
        
        -- Log the old values in change log
        INSERT INTO public.content_change_log (
            content_id, from_version, action_type, changed_by, 
            change_notes, old_values, new_values
        ) VALUES (
            NEW.id, 
            (SELECT version_number FROM public.content_versions 
             WHERE content_id = NEW.id AND is_active = true),
            'update', 'system', 'Content updated',
            jsonb_build_object(
                'title', OLD.title,
                'summary', OLD.summary,
                'topic_category', OLD.topic_category,
                'ai_confidence_score', OLD.ai_confidence_score,
                'content_url', OLD.content_url,
                'external_link', OLD.external_link
            ),
            jsonb_build_object(
                'title', NEW.title,
                'summary', NEW.summary,
                'topic_category', NEW.topic_category,
                'ai_confidence_score', NEW.ai_confidence_score,
                'content_url', NEW.content_url,
                'external_link', NEW.external_link
            )
        );
        
        -- Create new version
        PERFORM create_content_version(NEW.id, 'update', 'Content updated', 'system');
        
        -- Update delivery optimization
        PERFORM update_content_delivery_optimization(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER trigger_daily_feed_content_create_version
    AFTER INSERT ON public.daily_feed_content
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_initial_version();

CREATE TRIGGER trigger_daily_feed_content_update_version
    AFTER UPDATE ON public.daily_feed_content
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_update_version();

-- Create view for content with version info
CREATE OR REPLACE VIEW public.content_with_versions AS
SELECT 
    dfc.*,
    cv.version_number as current_version,
    cv.change_type as last_change_type,
    cv.change_reason as last_change_reason,
    cv.changed_by as last_changed_by,
    cdo.etag,
    cdo.cache_control,
    cdo.last_modified,
    cdo.content_size,
    cdo.cdn_url,
    (SELECT COUNT(*) FROM public.content_versions WHERE content_id = dfc.id) as total_versions
FROM public.daily_feed_content dfc
LEFT JOIN public.content_versions cv ON dfc.id = cv.content_id AND cv.is_active = true
LEFT JOIN public.content_delivery_optimization cdo ON dfc.id = cdo.content_id
ORDER BY dfc.content_date DESC;

-- Grant permissions
GRANT SELECT ON public.content_versions TO authenticated;
GRANT SELECT ON public.content_change_log TO authenticated;
GRANT SELECT ON public.content_delivery_optimization TO authenticated;
GRANT SELECT ON public.content_with_versions TO authenticated;

GRANT ALL ON public.content_versions TO service_role;
GRANT ALL ON public.content_change_log TO service_role;
GRANT ALL ON public.content_delivery_optimization TO service_role;
GRANT ALL ON public.content_with_versions TO service_role;

-- Grant sequence permissions
GRANT USAGE, SELECT ON SEQUENCE public.content_versions_id_seq TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE public.content_change_log_id_seq TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE public.content_delivery_optimization_id_seq TO authenticated, service_role;

-- Comments for documentation
COMMENT ON TABLE public.content_versions IS 'Version history for daily feed content with rollback capability';
COMMENT ON TABLE public.content_change_log IS 'Audit trail for all content changes and operations';
COMMENT ON TABLE public.content_delivery_optimization IS 'Optimization metadata for content delivery and CDN';

COMMENT ON FUNCTION create_content_version IS 'Creates new version of content for tracking changes';
COMMENT ON FUNCTION rollback_content_version IS 'Rolls back content to previous version';
COMMENT ON FUNCTION generate_content_etag IS 'Generates ETag for HTTP caching based on content and version';
COMMENT ON FUNCTION update_content_delivery_optimization IS 'Updates delivery optimization metadata for CDN';

COMMENT ON VIEW public.content_with_versions IS 'Consolidated view of content with current version and delivery info'; 