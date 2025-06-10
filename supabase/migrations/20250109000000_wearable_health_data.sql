-- Migration: Wearable Health Data Tables
-- Description: Create tables for storing wearable device health data and batch processing logs
-- Date: 2025-01-09
-- Task: T2.2.1.10 - Push samples to Supabase Edge function via batched HTTPS

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create wearable_health_data table
CREATE TABLE IF NOT EXISTS wearable_health_data (
    id VARCHAR(255) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    batch_id VARCHAR(255) NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    value DECIMAL(15,6) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    end_timestamp TIMESTAMPTZ,
    source VARCHAR(100) NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create wearable_batch_logs table
CREATE TABLE IF NOT EXISTS wearable_batch_logs (
    batch_id VARCHAR(255) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    total_samples INTEGER NOT NULL DEFAULT 0,
    samples_processed INTEGER NOT NULL DEFAULT 0,
    samples_rejected INTEGER NOT NULL DEFAULT 0,
    data_types TEXT[] DEFAULT '{}',
    processing_errors TEXT[] DEFAULT '{}',
    batch_metadata JSONB DEFAULT '{}',
    processed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_wearable_health_data_user_id ON wearable_health_data(user_id);
CREATE INDEX IF NOT EXISTS idx_wearable_health_data_timestamp ON wearable_health_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_wearable_health_data_data_type ON wearable_health_data(data_type);
CREATE INDEX IF NOT EXISTS idx_wearable_health_data_batch_id ON wearable_health_data(batch_id);
CREATE INDEX IF NOT EXISTS idx_wearable_batch_logs_user_id ON wearable_batch_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_wearable_batch_logs_processed_at ON wearable_batch_logs(processed_at);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_wearable_health_data_user_type_timestamp ON wearable_health_data(user_id, data_type, timestamp);

-- Enable Row Level Security
ALTER TABLE wearable_health_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE wearable_batch_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for wearable_health_data
CREATE POLICY "Users can view their own health data" ON wearable_health_data
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own health data" ON wearable_health_data
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own health data" ON wearable_health_data
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own health data" ON wearable_health_data
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for wearable_batch_logs
CREATE POLICY "Users can view their own batch logs" ON wearable_batch_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own batch logs" ON wearable_batch_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create function to clean up old health data (optional retention policy)
CREATE OR REPLACE FUNCTION cleanup_old_wearable_data()
RETURNS void AS $$
BEGIN
    -- Delete health data older than 2 years
    DELETE FROM wearable_health_data 
    WHERE timestamp < NOW() - INTERVAL '2 years';
    
    -- Delete batch logs older than 1 year
    DELETE FROM wearable_batch_logs 
    WHERE processed_at < NOW() - INTERVAL '1 year';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON wearable_health_data TO authenticated;
GRANT SELECT, INSERT ON wearable_batch_logs TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_wearable_data() TO authenticated;

-- Add helpful comments
COMMENT ON TABLE wearable_health_data IS 'Stores individual health data samples from wearable devices';
COMMENT ON TABLE wearable_batch_logs IS 'Logs batch processing metadata for wearable health data uploads';
COMMENT ON COLUMN wearable_health_data.data_type IS 'Type of health data (steps, heartRate, sleepDuration, etc.)';
COMMENT ON COLUMN wearable_health_data.value IS 'Numeric value of the health measurement';
COMMENT ON COLUMN wearable_health_data.unit IS 'Unit of measurement (count, bpm, minutes, etc.)';
COMMENT ON COLUMN wearable_health_data.source IS 'Source of the data (HealthKit, Health Connect, etc.)';
COMMENT ON COLUMN wearable_batch_logs.processing_errors IS 'Array of error messages encountered during batch processing'; 