/**
 * Main Cloud Function Entry Point
 * Batch Events Import for BEE Core Engagement Module
 * 
 * Integrates all components from tasks 4.1-4.4:
 * - Service role authentication (4.1)
 * - Batch import endpoint (4.2) 
 * - UTC timestamp handling (4.3)
 * - JWT validation (4.4)
 */

const { initializeServiceRole } = require('./index');
const { handleBatchEvents } = require('./batch-endpoint');
const { processBatchTimestamps } = require('./timestamp-utils');
const { verifyPgjwtExtension, testJWTFlows } = require('./jwt-utils');

/**
 * Initialize Cloud Function
 * Performs startup validation and setup
 */
async function initializeFunction() {
    console.log('Initializing Batch Events Cloud Function...');

    try {
        // Initialize service role authentication
        await initializeServiceRole();

        // Verify pgjwt extension availability
        const pgjwtAvailable = await verifyPgjwtExtension();
        if (!pgjwtAvailable) {
            console.warn('pgjwt extension not available - JWT validation will use Node.js library');
        }

        // Test JWT flows
        const jwtTestResults = testJWTFlows();
        const failedTests = jwtTestResults.filter(test => !test.success);

        if (failedTests.length > 0) {
            console.warn('Some JWT tests failed:', failedTests);
        } else {
            console.log('All JWT validation tests passed');
        }

        console.log('Cloud Function initialization complete');
        return true;

    } catch (error) {
        console.error('Cloud Function initialization failed:', error);
        throw error;
    }
}

/**
 * Enhanced batch events handler with timestamp processing
 */
async function enhancedBatchEventsHandler(req, res) {
    try {
        // Add CORS headers for web clients
        res.set('Access-Control-Allow-Origin', '*');
        res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
        res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

        // Handle preflight requests
        if (req.method === 'OPTIONS') {
            return res.status(204).send('');
        }

        // Parse request body if it's a string
        if (typeof req.body === 'string') {
            try {
                req.body = JSON.parse(req.body);
            } catch (parseError) {
                return res.status(400).json({
                    error: 'Invalid JSON',
                    message: 'Request body must be valid JSON'
                });
            }
        }

        // Process timestamps before validation
        if (req.body && req.body.events) {
            const timestampResult = processBatchTimestamps(req.body.events);

            if (timestampResult.errors.length > 0) {
                return res.status(400).json({
                    error: 'Timestamp processing failed',
                    timestamp_errors: timestampResult.errors
                });
            }

            // Update request body with processed events
            req.body.events = timestampResult.processedEvents;
        }

        // Delegate to main batch events handler
        return await handleBatchEvents(req, res);

    } catch (error) {
        console.error('Enhanced batch events handler error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'An unexpected error occurred',
            timestamp: new Date().toISOString()
        });
    }
}

/**
 * Health check endpoint
 */
function healthCheck(req, res) {
    res.status(200).json({
        status: 'healthy',
        service: 'batch-events',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
}

/**
 * Main Cloud Function export
 * Entry point for Google Cloud Functions or similar platforms
 */
exports.batchEvents = async (req, res) => {
    // Initialize function on first request (cold start)
    if (!global.functionInitialized) {
        try {
            await initializeFunction();
            global.functionInitialized = true;
        } catch (error) {
            console.error('Function initialization failed:', error);
            return res.status(500).json({
                error: 'Service unavailable',
                message: 'Function initialization failed'
            });
        }
    }

    // Route requests based on path
    const path = req.path || req.url;

    switch (path) {
        case '/health':
            return healthCheck(req, res);

        case '/batch-events':
        case '/':
            return enhancedBatchEventsHandler(req, res);

        default:
            return res.status(404).json({
                error: 'Not found',
                message: `Path ${path} not found`
            });
    }
};

/**
 * Express.js compatible export for local development
 */
exports.app = require('express')()
    .use(require('express').json({ limit: '10mb' }))
    .post('/batch-events', enhancedBatchEventsHandler)
    .get('/health', healthCheck)
    .all('*', (req, res) => {
        res.status(404).json({
            error: 'Not found',
            message: `Path ${req.path} not found`
        });
    });

// Initialize function if running directly
if (require.main === module) {
    initializeFunction()
        .then(() => {
            console.log('Function ready for testing');

            // Start Express server for local development
            const port = process.env.PORT || 8080;
            exports.app.listen(port, () => {
                console.log(`Batch Events service listening on port ${port}`);
                console.log(`Health check: http://localhost:${port}/health`);
                console.log(`Batch events: http://localhost:${port}/batch-events`);
            });
        })
        .catch(error => {
            console.error('Failed to initialize function:', error);
            process.exit(1);
        });
} 