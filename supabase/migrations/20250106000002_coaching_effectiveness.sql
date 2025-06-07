-- Add coaching effectiveness tracking tables
-- This supports the Personalization Engine (M1.3.2) effectiveness measurement system

-- Coaching effectiveness tracking
CREATE TABLE coaching_effectiveness (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    conversation_log_id UUID REFERENCES conversation_logs(id) ON DELETE CASCADE,
    
    -- Feedback metrics
    feedback_type TEXT CHECK (feedback_type IN ('helpful', 'not_helpful', 'ignored')),
    user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
    response_time_seconds INTEGER,
    
    -- Coaching context
    persona_used TEXT CHECK (persona_used IN ('supportive', 'challenging', 'educational')),
    intervention_trigger TEXT,
    momentum_state TEXT CHECK (momentum_state IN ('Rising', 'Steady', 'NeedsCare')),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User coaching preferences for frequency optimization
CREATE TABLE user_coaching_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL UNIQUE,
    
    -- Frequency settings
    max_interventions_per_day INTEGER DEFAULT 3,
    preferred_hours INTEGER[] DEFAULT ARRAY[9, 14, 19], -- Array of preferred hours
    min_hours_between INTEGER DEFAULT 4,
    frequency_preference TEXT CHECK (frequency_preference IN ('high', 'medium', 'low')) DEFAULT 'medium',
    
    -- Auto-optimization
    auto_optimized BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_coaching_effectiveness_user_id ON coaching_effectiveness(user_id);
CREATE INDEX idx_coaching_effectiveness_created_at ON coaching_effectiveness(created_at);
CREATE INDEX idx_coaching_effectiveness_persona ON coaching_effectiveness(persona_used, feedback_type);

CREATE INDEX idx_user_coaching_preferences_user_id ON user_coaching_preferences(user_id);

-- Row Level Security (RLS)
ALTER TABLE coaching_effectiveness ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_coaching_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only access their own effectiveness data
CREATE POLICY "Users can access own effectiveness data" 
ON coaching_effectiveness FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Users can access own coaching preferences" 
ON user_coaching_preferences FOR ALL 
USING (auth.uid() = user_id);

-- Update triggers
CREATE TRIGGER update_coaching_effectiveness_updated_at 
    BEFORE UPDATE ON coaching_effectiveness 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_coaching_preferences_updated_at 
    BEFORE UPDATE ON user_coaching_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE coaching_effectiveness IS 'Tracks user feedback and effectiveness of AI coaching interactions';
COMMENT ON COLUMN coaching_effectiveness.feedback_type IS 'Type of user feedback: helpful, not_helpful, or ignored';
COMMENT ON COLUMN coaching_effectiveness.user_rating IS 'User rating from 1-5 scale';
COMMENT ON COLUMN coaching_effectiveness.response_time_seconds IS 'Time taken for user to respond to coaching';
COMMENT ON COLUMN coaching_effectiveness.persona_used IS 'AI coaching persona used for this interaction';
COMMENT ON COLUMN coaching_effectiveness.intervention_trigger IS 'What triggered this coaching intervention';

COMMENT ON TABLE user_coaching_preferences IS 'Stores personalized coaching frequency and timing preferences';
COMMENT ON COLUMN user_coaching_preferences.preferred_hours IS 'Array of preferred hours for coaching (24-hour format)';
COMMENT ON COLUMN user_coaching_preferences.auto_optimized IS 'Whether system should auto-optimize frequency based on user behavior'; 