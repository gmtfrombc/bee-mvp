-- Add cross-patient pattern aggregation for Epic 3.1 preparation
-- This supports the Personalization Engine (M1.3.2.8) cross-patient learning foundation

-- Anonymized pattern aggregation for cross-patient learning
CREATE TABLE coaching_pattern_aggregates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Pattern identification
    pattern_type TEXT NOT NULL CHECK (pattern_type IN (
        'engagement_peak', 
        'volatility_trend', 
        'persona_effectiveness',
        'intervention_timing',
        'response_frequency'
    )),
    
    -- Aggregated data (JSON format for flexibility)
    pattern_data JSONB NOT NULL,
    
    -- Anonymized metrics
    user_count INTEGER NOT NULL CHECK (user_count >= 5), -- Minimum 5 users for privacy
    effectiveness_score DECIMAL(3,2) CHECK (effectiveness_score >= 0 AND effectiveness_score <= 1),
    confidence_level DECIMAL(3,2) CHECK (confidence_level >= 0 AND confidence_level <= 1),
    
    -- Time-based aggregation
    created_week DATE NOT NULL, -- Week-based aggregation for privacy
    
    -- Context
    momentum_state TEXT CHECK (momentum_state IN ('Rising', 'Steady', 'NeedsCare')),
    user_segment TEXT, -- Optional segmentation (e.g., 'new_users', 'experienced')
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Weekly pattern learning insights
CREATE TABLE cross_patient_insights (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Insight identification
    insight_type TEXT NOT NULL CHECK (insight_type IN (
        'optimal_timing',
        'effective_personas',
        'intervention_patterns',
        'engagement_trends'
    )),
    
    -- Insight data
    insight_data JSONB NOT NULL,
    recommendation TEXT NOT NULL,
    
    -- Supporting evidence
    supporting_patterns UUID[], -- Array of pattern IDs referencing coaching_pattern_aggregates
    confidence_score DECIMAL(3,2) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    
    -- Time context
    applicable_week DATE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_coaching_pattern_aggregates_type ON coaching_pattern_aggregates(pattern_type);
CREATE INDEX idx_coaching_pattern_aggregates_week ON coaching_pattern_aggregates(created_week);
CREATE INDEX idx_coaching_pattern_aggregates_momentum ON coaching_pattern_aggregates(momentum_state);
CREATE INDEX idx_coaching_pattern_aggregates_effectiveness ON coaching_pattern_aggregates(effectiveness_score DESC);

CREATE INDEX idx_cross_patient_insights_type ON cross_patient_insights(insight_type);
CREATE INDEX idx_cross_patient_insights_week ON cross_patient_insights(applicable_week);
CREATE INDEX idx_cross_patient_insights_confidence ON cross_patient_insights(confidence_score DESC);

-- Composite index for common queries
CREATE INDEX idx_pattern_type_week_momentum ON coaching_pattern_aggregates(pattern_type, created_week, momentum_state);

-- Row Level Security (RLS) - Service role only for aggregated data
ALTER TABLE coaching_pattern_aggregates ENABLE ROW LEVEL SECURITY;
ALTER TABLE cross_patient_insights ENABLE ROW LEVEL SECURITY;

-- Only service role can access aggregated patterns (no user-level access for privacy)
CREATE POLICY "Service role only access to pattern aggregates" 
ON coaching_pattern_aggregates FOR ALL 
USING (auth.role() = 'service_role');

CREATE POLICY "Service role only access to insights" 
ON cross_patient_insights FOR ALL 
USING (auth.role() = 'service_role');

-- Update triggers
CREATE TRIGGER update_coaching_pattern_aggregates_updated_at 
    BEFORE UPDATE ON coaching_pattern_aggregates 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cross_patient_insights_updated_at 
    BEFORE UPDATE ON cross_patient_insights 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE coaching_pattern_aggregates IS 'Anonymized aggregated patterns for cross-patient learning, minimum 5 users per aggregate for privacy';
COMMENT ON COLUMN coaching_pattern_aggregates.pattern_data IS 'JSON structure containing anonymized pattern data for machine learning';
COMMENT ON COLUMN coaching_pattern_aggregates.user_count IS 'Number of users contributing to this pattern (minimum 5 for privacy)';
COMMENT ON COLUMN coaching_pattern_aggregates.effectiveness_score IS 'Effectiveness score from 0.0 to 1.0 based on aggregated user feedback';
COMMENT ON COLUMN coaching_pattern_aggregates.created_week IS 'Week of aggregation - ensures temporal privacy by not using exact timestamps';

COMMENT ON TABLE cross_patient_insights IS 'Weekly insights derived from pattern aggregates for coaching optimization';
COMMENT ON COLUMN cross_patient_insights.supporting_patterns IS 'Array of pattern aggregate IDs that support this insight';
COMMENT ON COLUMN cross_patient_insights.confidence_score IS 'Statistical confidence in the insight from 0.0 to 1.0'; 