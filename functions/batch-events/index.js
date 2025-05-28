/**
 * Cloud Function: Batch Events Import
 * 
 * Purpose: Bulk import engagement events using Supabase service role
 * Module: Core Engagement
 * Milestone: 1 · Data Backbone
 * 
 * Authentication: Uses Supabase service role to bypass RLS
 * Endpoint: POST /batch-events
 */

const { createClient } = require('@supabase/supabase-js');

// Environment variables validation
const requiredEnvVars = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingVars.length > 0) {
    throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
}

// Initialize Supabase client with service role credentials
// Service role bypasses RLS and can insert events for any user
const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    }
);

/**
 * Test the authentication connection from Cloud Function to Supabase
 * Verifies service role can access the database
 */
async function testServiceRoleConnection() {
    try {
        // Test connection by querying the engagement_events table
        const { data, error } = await supabase
            .from('engagement_events')
            .select('count(*)')
            .limit(1);

        if (error) {
            console.error('Service role connection test failed:', error);
            return false;
        }

        console.log('Service role connection test successful');
        return true;
    } catch (error) {
        console.error('Service role connection test error:', error);
        return false;
    }
}

/**
 * Validate service role permissions
 * Ensures the service role can perform required operations
 */
async function validateServiceRolePermissions() {
    try {
        // Test insert permission
        const testEvent = {
            user_id: '00000000-0000-0000-0000-000000000000', // Test UUID
            event_type: 'connection_test',
            value: { test: true, timestamp: new Date().toISOString() }
        };

        const { data: insertData, error: insertError } = await supabase
            .from('engagement_events')
            .insert(testEvent)
            .select()
            .single();

        if (insertError) {
            console.error('Service role insert test failed:', insertError);
            return false;
        }

        // Test select permission (should be able to read all events)
        const { data: selectData, error: selectError } = await supabase
            .from('engagement_events')
            .select('id')
            .eq('id', insertData.id)
            .single();

        if (selectError) {
            console.error('Service role select test failed:', selectError);
            return false;
        }

        // Clean up test event
        await supabase
            .from('engagement_events')
            .delete()
            .eq('id', insertData.id);

        console.log('Service role permissions validation successful');
        return true;
    } catch (error) {
        console.error('Service role permissions validation error:', error);
        return false;
    }
}

/**
 * Initialize and validate service role setup
 * Called during function startup
 */
async function initializeServiceRole() {
    console.log('Initializing service role authentication...');

    const connectionTest = await testServiceRoleConnection();
    if (!connectionTest) {
        throw new Error('Service role connection test failed');
    }

    const permissionsTest = await validateServiceRolePermissions();
    if (!permissionsTest) {
        throw new Error('Service role permissions validation failed');
    }

    console.log('Service role authentication setup complete');
}

// Export the configured Supabase client and utilities
module.exports = {
    supabase,
    testServiceRoleConnection,
    validateServiceRolePermissions,
    initializeServiceRole
}; 