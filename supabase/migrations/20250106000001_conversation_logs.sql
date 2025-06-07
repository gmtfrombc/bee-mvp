-- Add conversation_logs table for AI coaching
-- This table stores conversation history for the AI coaching engine

CREATE TABLE conversation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Conversation details
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    persona TEXT, -- coaching persona used for assistant responses
    
    -- Timestamps
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_conversation_logs_user_time 
ON conversation_logs(user_id, timestamp DESC);

CREATE INDEX idx_conversation_logs_role 
ON conversation_logs(user_id, role, timestamp DESC);

-- Row Level Security (RLS)
ALTER TABLE conversation_logs ENABLE ROW LEVEL SECURITY;

-- Users can only access their own conversation logs
CREATE POLICY "Users can access own conversation logs" 
ON conversation_logs FOR ALL 
USING (auth.uid() = user_id);

-- Update trigger
CREATE TRIGGER update_conversation_logs_updated_at 
    BEFORE UPDATE ON conversation_logs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE conversation_logs IS 'Stores AI coaching conversation history for context and continuity';
COMMENT ON COLUMN conversation_logs.role IS 'Role in conversation: user, assistant, or system';
COMMENT ON COLUMN conversation_logs.content IS 'Message content or system event description';
COMMENT ON COLUMN conversation_logs.persona IS 'AI coaching persona used (supportive, challenging, etc.)'; 