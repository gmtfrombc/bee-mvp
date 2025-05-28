/**
 * Batch Events Import Endpoint
 * 
 * Handles bulk insertion of engagement events with validation and transactions
 * Follows prompt 4.2 requirements for JSON schema validation and error handling
 */

const { supabase } = require('./index');

/**
 * JSON Schema for batch event payload validation
 * Accepts arrays of engagement events with required fields
 */
const batchEventSchema = {
    type: 'object',
    required: ['events'],
    properties: {
        events: {
            type: 'array',
            minItems: 1,
            maxItems: 1000, // Limit batch size for performance
            items: {
                type: 'object',
                required: ['user_id', 'event_type'],
                properties: {
                    user_id: {
                        type: 'string',
                        pattern: '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                    },
                    event_type: {
                        type: 'string',
                        minLength: 1,
                        maxLength: 100,
                        pattern: '^[a-z][a-z0-9_]*$' // snake_case format
                    },
                    timestamp: {
                        type: 'string',
                        format: 'date-time'
                    },
                    value: {
                        type: 'object',
                        additionalProperties: true
                    },
                    is_deleted: {
                        type: 'boolean'
                    }
                },
                additionalProperties: false
            }
        },
        source: {
            type: 'string',
            enum: ['ehr_import', 'fitbit_sync', 'manual_import', 'system_generated']
        },
        batch_id: {
            type: 'string',
            maxLength: 100
        }
    },
    additionalProperties: false
};

/**
 * Validate JSON payload against schema
 */
function validateBatchPayload(payload) {
    const Ajv = require('ajv');
    const addFormats = require('ajv-formats');

    const ajv = new Ajv({ allErrors: true });
    addFormats(ajv);

    const validate = ajv.compile(batchEventSchema);
    const valid = validate(payload);

    if (!valid) {
        return {
            isValid: false,
            errors: validate.errors.map(err => ({
                field: err.instancePath || err.schemaPath,
                message: err.message,
                value: err.data
            }))
        };
    }

    return { isValid: true, errors: [] };
}

/**
 * Validate individual event data
 */
function validateEventData(events) {
    const errors = [];

    events.forEach((event, index) => {
        // Validate event_type format
        if (!/^[a-z][a-z0-9_]*$/.test(event.event_type)) {
            errors.push({
                index,
                field: 'event_type',
                message: 'Event type must be snake_case format starting with lowercase letter'
            });
        }

        // Validate timestamp if provided
        if (event.timestamp) {
            const timestamp = new Date(event.timestamp);
            if (isNaN(timestamp.getTime())) {
                errors.push({
                    index,
                    field: 'timestamp',
                    message: 'Invalid timestamp format'
                });
            }

            // Check if timestamp is not too far in the future (1 hour tolerance)
            const now = new Date();
            const maxFuture = new Date(now.getTime() + 60 * 60 * 1000);
            if (timestamp > maxFuture) {
                errors.push({
                    index,
                    field: 'timestamp',
                    message: 'Timestamp cannot be more than 1 hour in the future'
                });
            }
        }

        // Validate JSONB value size (PostgreSQL limit ~1GB, but practical limit much smaller)
        if (event.value && JSON.stringify(event.value).length > 100000) {
            errors.push({
                index,
                field: 'value',
                message: 'Event value payload too large (max 100KB)'
            });
        }
    });

    return errors;
}

/**
 * Perform bulk insert with database transaction
 * Ensures atomicity - all events inserted or none
 */
async function bulkInsertEvents(events, metadata = {}) {
    try {
        // Prepare events for insertion
        const preparedEvents = events.map(event => ({
            user_id: event.user_id,
            event_type: event.event_type,
            timestamp: event.timestamp || new Date().toISOString(),
            value: event.value || {},
            is_deleted: event.is_deleted || false
        }));

        // Perform bulk insert using Supabase (which handles transactions internally)
        const { data, error } = await supabase
            .from('engagement_events')
            .insert(preparedEvents)
            .select('id, user_id, event_type, timestamp');

        if (error) {
            console.error('Bulk insert failed:', error);
            throw new Error(`Database insert failed: ${error.message}`);
        }

        // Log successful batch import
        console.log(`Successfully inserted ${data.length} events`, {
            batch_id: metadata.batch_id,
            source: metadata.source,
            event_count: data.length,
            user_ids: [...new Set(data.map(e => e.user_id))].length
        });

        return {
            success: true,
            inserted_count: data.length,
            inserted_events: data,
            batch_id: metadata.batch_id
        };

    } catch (error) {
        console.error('Bulk insert transaction failed:', error);
        throw error;
    }
}

/**
 * Main batch events endpoint handler
 * POST /batch-events
 */
async function handleBatchEvents(req, res) {
    try {
        // Validate HTTP method
        if (req.method !== 'POST') {
            return res.status(405).json({
                error: 'Method not allowed',
                message: 'Only POST requests are supported'
            });
        }

        // Validate Content-Type
        if (!req.headers['content-type']?.includes('application/json')) {
            return res.status(400).json({
                error: 'Invalid content type',
                message: 'Content-Type must be application/json'
            });
        }

        // Parse and validate JSON payload
        let payload;
        try {
            payload = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
        } catch (parseError) {
            return res.status(400).json({
                error: 'Invalid JSON',
                message: 'Request body must be valid JSON'
            });
        }

        // Validate payload schema
        const schemaValidation = validateBatchPayload(payload);
        if (!schemaValidation.isValid) {
            return res.status(400).json({
                error: 'Schema validation failed',
                validation_errors: schemaValidation.errors
            });
        }

        // Validate event data
        const dataValidation = validateEventData(payload.events);
        if (dataValidation.length > 0) {
            return res.status(400).json({
                error: 'Event data validation failed',
                validation_errors: dataValidation
            });
        }

        // Perform bulk insert
        const result = await bulkInsertEvents(payload.events, {
            source: payload.source,
            batch_id: payload.batch_id || `batch_${Date.now()}`
        });

        // Return success response
        res.status(201).json({
            success: true,
            message: 'Batch events imported successfully',
            ...result
        });

    } catch (error) {
        console.error('Batch events endpoint error:', error);

        // Return appropriate error response
        const statusCode = error.message.includes('Database') ? 500 : 400;
        res.status(statusCode).json({
            error: 'Batch import failed',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
}

module.exports = {
    handleBatchEvents,
    validateBatchPayload,
    validateEventData,
    bulkInsertEvents,
    batchEventSchema
}; 