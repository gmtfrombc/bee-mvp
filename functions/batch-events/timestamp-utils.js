/**
 * UTC Timestamp Handling Utilities
 * 
 * Implements timestamp conversion logic to ensure all incoming timestamps
 * are converted to UTC before database insertion as required by prompt 4.3
 */

const moment = require('moment-timezone');

/**
 * List of supported timezone formats
 */
const SUPPORTED_TIMEZONE_FORMATS = [
    'YYYY-MM-DDTHH:mm:ss.SSSZ',     // ISO 8601 with timezone
    'YYYY-MM-DDTHH:mm:ssZ',         // ISO 8601 without milliseconds
    'YYYY-MM-DD HH:mm:ss Z',        // Space-separated with timezone
    'YYYY-MM-DD HH:mm:ss',          // Local time (assumes UTC)
    'YYYY-MM-DDTHH:mm:ss',          // ISO without timezone (assumes UTC)
];

/**
 * Validate timezone data and reject invalid formats
 */
function validateTimezoneData(timestamp, timezone = null) {
    const errors = [];

    if (!timestamp) {
        return { isValid: true, errors: [] }; // Optional field
    }

    // Check if timestamp is a string
    if (typeof timestamp !== 'string') {
        errors.push('Timestamp must be a string');
        return { isValid: false, errors };
    }

    // Try to parse the timestamp
    let momentObj;

    if (timezone) {
        // If timezone is provided, validate it exists
        if (!moment.tz.zone(timezone)) {
            errors.push(`Invalid timezone: ${timezone}`);
            return { isValid: false, errors };
        }

        // Parse with specific timezone
        momentObj = moment.tz(timestamp, timezone);
    } else {
        // Try parsing with supported formats
        momentObj = moment(timestamp, SUPPORTED_TIMEZONE_FORMATS, true);
    }

    // Check if parsing was successful
    if (!momentObj.isValid()) {
        errors.push(`Invalid timestamp format: ${timestamp}`);
        return { isValid: false, errors };
    }

    // Check if timestamp is not too far in the past (1 year)
    const oneYearAgo = moment().subtract(1, 'year');
    if (momentObj.isBefore(oneYearAgo)) {
        errors.push('Timestamp cannot be more than 1 year in the past');
    }

    // Check if timestamp is not too far in the future (1 hour tolerance for clock skew)
    const oneHourFromNow = moment().add(1, 'hour');
    if (momentObj.isAfter(oneHourFromNow)) {
        errors.push('Timestamp cannot be more than 1 hour in the future');
    }

    return {
        isValid: errors.length === 0,
        errors,
        parsedTimestamp: momentObj
    };
}

/**
 * Convert timestamp to UTC format
 * Ensures consistent UTC storage as required by technical considerations
 */
function convertToUTC(timestamp, timezone = null) {
    try {
        // Validate the timestamp first
        const validation = validateTimezoneData(timestamp, timezone);
        if (!validation.isValid) {
            throw new Error(`Timestamp validation failed: ${validation.errors.join(', ')}`);
        }

        let momentObj;

        if (timezone) {
            // Parse with specific timezone and convert to UTC
            momentObj = moment.tz(timestamp, timezone).utc();
        } else {
            // Parse and ensure it's in UTC
            momentObj = moment(timestamp, SUPPORTED_TIMEZONE_FORMATS, true).utc();
        }

        // Return ISO 8601 UTC format
        return momentObj.toISOString();

    } catch (error) {
        throw new Error(`UTC conversion failed: ${error.message}`);
    }
}

/**
 * Process batch events and convert all timestamps to UTC
 */
function processBatchTimestamps(events) {
    const processedEvents = [];
    const errors = [];

    events.forEach((event, index) => {
        try {
            const processedEvent = { ...event };

            // Convert timestamp if provided
            if (event.timestamp) {
                processedEvent.timestamp = convertToUTC(
                    event.timestamp,
                    event.timezone // Optional timezone field
                );

                // Remove timezone field after processing
                delete processedEvent.timezone;
            } else {
                // Use current UTC time if no timestamp provided
                processedEvent.timestamp = moment().utc().toISOString();
            }

            processedEvents.push(processedEvent);

        } catch (error) {
            errors.push({
                index,
                field: 'timestamp',
                message: error.message,
                originalValue: event.timestamp
            });
        }
    });

    return {
        processedEvents,
        errors
    };
}

/**
 * Test timestamp conversion with various timezone inputs
 * Used for validation and testing
 */
function testTimezoneConversion() {
    const testCases = [
        {
            input: '2024-12-01T10:30:00-05:00',
            timezone: null,
            description: 'ISO 8601 with timezone offset'
        },
        {
            input: '2024-12-01 10:30:00',
            timezone: 'America/New_York',
            description: 'Local time with timezone'
        },
        {
            input: '2024-12-01T10:30:00Z',
            timezone: null,
            description: 'UTC timestamp'
        },
        {
            input: '2024-12-01T10:30:00',
            timezone: 'Europe/London',
            description: 'Local time with London timezone'
        },
        {
            input: '2024-12-01T10:30:00.123Z',
            timezone: null,
            description: 'UTC with milliseconds'
        }
    ];

    const results = [];

    testCases.forEach((testCase, index) => {
        try {
            const utcTimestamp = convertToUTC(testCase.input, testCase.timezone);
            results.push({
                index,
                description: testCase.description,
                input: testCase.input,
                timezone: testCase.timezone,
                output: utcTimestamp,
                success: true
            });
        } catch (error) {
            results.push({
                index,
                description: testCase.description,
                input: testCase.input,
                timezone: testCase.timezone,
                error: error.message,
                success: false
            });
        }
    });

    return results;
}

/**
 * Get current UTC timestamp in ISO format
 */
function getCurrentUTC() {
    return moment().utc().toISOString();
}

/**
 * Parse and validate a single timestamp
 */
function parseTimestamp(timestamp, timezone = null) {
    const validation = validateTimezoneData(timestamp, timezone);

    if (!validation.isValid) {
        return {
            isValid: false,
            errors: validation.errors,
            utcTimestamp: null
        };
    }

    try {
        const utcTimestamp = convertToUTC(timestamp, timezone);
        return {
            isValid: true,
            errors: [],
            utcTimestamp,
            originalTimestamp: timestamp,
            timezone
        };
    } catch (error) {
        return {
            isValid: false,
            errors: [error.message],
            utcTimestamp: null
        };
    }
}

module.exports = {
    validateTimezoneData,
    convertToUTC,
    processBatchTimestamps,
    testTimezoneConversion,
    getCurrentUTC,
    parseTimestamp,
    SUPPORTED_TIMEZONE_FORMATS
}; 