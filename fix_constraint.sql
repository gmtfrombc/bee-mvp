-- Fix content_change_log constraint violation
-- Run this in the Supabase SQL Editor

-- Drop the existing constraint
ALTER TABLE public.content_change_log 
DROP CONSTRAINT IF EXISTS content_change_log_action_type_check;

-- Add the updated constraint that includes 'initial'
ALTER TABLE public.content_change_log 
ADD CONSTRAINT content_change_log_action_type_check 
CHECK (action_type IN ('create', 'update', 'rollback', 'publish', 'unpublish', 'initial'));

-- Verify the constraint was added
SELECT conname, consrc 
FROM pg_constraint 
WHERE conname = 'content_change_log_action_type_check'; 