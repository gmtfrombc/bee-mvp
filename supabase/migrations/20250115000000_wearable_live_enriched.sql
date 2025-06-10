-- Migration: Wearable Live Enriched Data Table
-- Description: Create table for storing enriched real-time wearable data with rolling averages and battery flags
-- Date: 2025-01-15
-- Task: T2.2.2.5 - Build Edge Function up-converter for enriched delta packets

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create wearable_live_enriched table
CREATE TABLE IF NOT EXISTS wearable_live_enriched (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Original delta packet data
    data_type VARCHAR(50) NOT NULL,
    raw_value DECIMAL(15,6) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    source VARCHAR(100) NOT NULL,
    
    -- Enrichment data
    rolling_avg_5min DECIMAL(15,6),
    rolling_avg_15min DECIMAL(15,6),
    rolling_avg_30min DECIMAL(15,6),
    value_trend VARCHAR(20) CHECK (value_trend IN ('rising', 'falling', 'stable')),
    battery_level_percent INTEGER CHECK (battery_level_percent >= 0 AND battery_level_percent <= 100),
    battery_status VARCHAR(20) CHECK (battery_status IN ('charging', 'not_charging', 'low', 'critical', 'unknown')),
    device_connected BOOLEAN DEFAULT true,
    
    -- Metadata
    enrichment_version VARCHAR(10) NOT NULL DEFAULT 'v1.0',
    processing_latency_ms INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_wearable_live_enriched_user_id ON wearable_live_enriched(user_id);
CREATE INDEX IF NOT EXISTS idx_wearable_live_enriched_timestamp ON wearable_live_enriched(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_wearable_live_enriched_data_type ON wearable_live_enriched(data_type);
CREATE INDEX IF NOT EXISTS idx_wearable_live_enriched_user_type_timestamp ON wearable_live_enriched(user_id, data_type, timestamp DESC);

-- Enable Row Level Security
ALTER TABLE wearable_live_enriched ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own enriched live data" ON wearable_live_enriched
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service can insert enriched live data" ON wearable_live_enriched
    FOR INSERT WITH CHECK (true);

-- Grant permissions
GRANT SELECT ON wearable_live_enriched TO authenticated;
GRANT INSERT ON wearable_live_enriched TO service_role;

-- Add helpful comments
COMMENT ON TABLE wearable_live_enriched IS 'Stores enriched real-time wearable data with rolling averages and battery information';
COMMENT ON COLUMN wearable_live_enriched.rolling_avg_5min IS '5-minute rolling average for the data type';
COMMENT ON COLUMN wearable_live_enriched.battery_level_percent IS 'Device battery level when sample was recorded';
COMMENT ON COLUMN wearable_live_enriched.value_trend IS 'Trend direction based on recent values (rising/falling/stable)'; 