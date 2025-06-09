-- Fix trigger function to use 'create' instead of 'initial'
-- This aligns with the existing constraint that allows: 'create', 'update', 'rollback', 'publish', 'unpublish'

CREATE OR REPLACE FUNCTION trigger_create_initial_version()
RETURNS TRIGGER AS $$
BEGIN
    -- Create initial version using 'create' action type (not 'initial')
    PERFORM create_content_version(NEW.id, 'create', 'Initial content creation', 'system');
    
    -- Update delivery optimization
    PERFORM update_content_delivery_optimization(NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add comment for clarity
COMMENT ON FUNCTION trigger_create_initial_version IS 'Creates initial version when content is first created, using create action type'; 