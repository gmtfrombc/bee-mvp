import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type, x-batch-id, x-sample-count, x-user-id",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface HealthSample {
    id: string;
    type: string;
    value: number | string;
    unit: string;
    timestamp: string;
    endTime?: string;
    source: string;
    metadata?: Record<string, any>;
}

interface HealthDataBatch {
    batch_id: string;
    user_id: string;
    created_at: string;
    samples: HealthSample[];
    metadata?: Record<string, any>;
}

interface ProcessingResult {
    samples_processed: number;
    samples_rejected: number;
    message: string;
    diagnostics: Record<string, any>;
}

serve(async (req) => {
    // Handle CORS preflight requests
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    // Only allow POST requests
    if (req.method !== "POST") {
        return new Response(
            JSON.stringify({
                error: "Method not allowed",
                error_code: "METHOD_NOT_ALLOWED",
            }),
            {
                status: 405,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
        );
    }

    const startTime = Date.now();

    try {
        // Initialize Supabase client
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // Get authorization header
        const authHeader = req.headers.get("Authorization");
        if (!authHeader) {
            return new Response(
                JSON.stringify({
                    error: "Missing authorization header",
                    error_code: "UNAUTHORIZED",
                }),
                {
                    status: 401,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        // Verify JWT token
        const token = authHeader.replace("Bearer ", "");
        const { data: { user }, error: authError } = await supabase.auth
            .getUser(token);

        if (authError || !user) {
            console.error("Authentication failed:", authError);
            return new Response(
                JSON.stringify({
                    error: "Invalid authentication token",
                    error_code: "UNAUTHORIZED",
                }),
                {
                    status: 401,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        // Parse request body
        let batch: HealthDataBatch;
        try {
            batch = await req.json();
        } catch (error) {
            return new Response(
                JSON.stringify({
                    error: "Invalid JSON payload",
                    error_code: "INVALID_JSON",
                    details: error instanceof Error
                        ? error.message
                        : "Unknown JSON parsing error",
                }),
                {
                    status: 400,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        // Validate request headers
        const batchId = req.headers.get("X-Batch-ID");
        const sampleCount = req.headers.get("X-Sample-Count");
        const requestUserId = req.headers.get("X-User-ID");

        if (!batchId) {
            return new Response(
                JSON.stringify({
                    error: "Missing X-Batch-ID header",
                    error_code: "MISSING_BATCH_ID",
                }),
                {
                    status: 400,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        // Validate batch structure
        const validationResult = validateBatch(
            batch,
            user.id,
            batchId,
            sampleCount,
        );
        if (!validationResult.isValid) {
            return new Response(
                JSON.stringify({
                    error: "Batch validation failed",
                    error_code: "VALIDATION_FAILED",
                    details: validationResult.errors,
                }),
                {
                    status: 400,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        // Process the health data batch
        const processingResult = await processHealthDataBatch(
            supabase,
            batch,
            user.id,
        );

        // Prepare response
        const responseTime = Date.now() - startTime;
        const response = {
            success: true,
            ...processingResult,
            batch_id: batchId,
            processing_time_ms: responseTime,
            timestamp: new Date().toISOString(),
        };

        console.log(
            `✅ Health data batch processed: ${batchId} - ${processingResult.samples_processed} samples in ${responseTime}ms`,
        );

        return new Response(
            JSON.stringify(response),
            {
                status: 201,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
        );
    } catch (error) {
        console.error("❌ Health data ingestion error:", error);

        const responseTime = Date.now() - startTime;
        return new Response(
            JSON.stringify({
                error: "Internal server error",
                error_code: "INTERNAL_ERROR",
                processing_time_ms: responseTime,
                timestamp: new Date().toISOString(),
            }),
            {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
        );
    }
});

function validateBatch(
    batch: HealthDataBatch,
    userId: string,
    batchId: string,
    expectedSampleCount?: string | null,
): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    // Validate required fields
    if (!batch.batch_id) errors.push("Missing batch_id");
    if (!batch.user_id) errors.push("Missing user_id");
    if (!batch.samples || !Array.isArray(batch.samples)) {
        errors.push("Missing or invalid samples array");
    }

    // Validate batch ID consistency
    if (batch.batch_id !== batchId) {
        errors.push(
            `Batch ID mismatch: header=${batchId}, body=${batch.batch_id}`,
        );
    }

    // Validate user ID consistency
    if (batch.user_id !== userId) {
        errors.push(
            `User ID mismatch: authenticated=${userId}, batch=${batch.user_id}`,
        );
    }

    // Validate sample count if provided
    if (expectedSampleCount) {
        const expected = parseInt(expectedSampleCount, 10);
        if (batch.samples.length !== expected) {
            errors.push(
                `Sample count mismatch: header=${expected}, actual=${batch.samples.length}`,
            );
        }
    }

    // Validate individual samples
    if (batch.samples) {
        batch.samples.forEach((sample, index) => {
            if (!sample.id) errors.push(`Sample ${index}: missing id`);
            if (!sample.type) errors.push(`Sample ${index}: missing type`);
            if (sample.value === undefined || sample.value === null) {
                errors.push(`Sample ${index}: missing value`);
            }
            if (!sample.unit) errors.push(`Sample ${index}: missing unit`);
            if (!sample.timestamp) {
                errors.push(`Sample ${index}: missing timestamp`);
            }
            if (!sample.source) errors.push(`Sample ${index}: missing source`);

            // Validate timestamp format
            if (sample.timestamp) {
                try {
                    new Date(sample.timestamp);
                } catch {
                    errors.push(`Sample ${index}: invalid timestamp format`);
                }
            }
        });
    }

    return { isValid: errors.length === 0, errors };
}

async function processHealthDataBatch(
    supabase: any,
    batch: HealthDataBatch,
    userId: string,
): Promise<ProcessingResult> {
    let samplesProcessed = 0;
    let samplesRejected = 0;
    const processingErrors: string[] = [];
    const dataTypeStats: Record<string, number> = {};

    // Process each sample
    for (const sample of batch.samples) {
        try {
            // Count data types for diagnostics
            dataTypeStats[sample.type] = (dataTypeStats[sample.type] || 0) + 1;

            // Validate sample data
            if (!isValidHealthSample(sample)) {
                samplesRejected++;
                processingErrors.push(`Invalid sample: ${sample.id}`);
                continue;
            }

            // Insert sample into database
            const { error } = await supabase
                .from("wearable_health_data")
                .insert({
                    id: sample.id,
                    user_id: userId,
                    batch_id: batch.batch_id,
                    data_type: sample.type,
                    value: sample.value,
                    unit: sample.unit,
                    timestamp: sample.timestamp,
                    end_timestamp: sample.endTime || null,
                    source: sample.source,
                    metadata: sample.metadata || {},
                    created_at: new Date().toISOString(),
                });

            if (error) {
                // Handle duplicate key errors gracefully
                if (error.code === "23505") { // PostgreSQL unique constraint violation
                    console.log(`Duplicate sample ignored: ${sample.id}`);
                    samplesRejected++;
                } else {
                    console.error(
                        `Database error for sample ${sample.id}:`,
                        error,
                    );
                    samplesRejected++;
                    processingErrors.push(`Database error: ${sample.id}`);
                }
            } else {
                samplesProcessed++;
            }
        } catch (error) {
            console.error(`Processing error for sample ${sample.id}:`, error);
            samplesRejected++;
            processingErrors.push(`Processing error: ${sample.id}`);
        }
    }

    // Record batch metadata
    try {
        await supabase
            .from("wearable_batch_logs")
            .insert({
                batch_id: batch.batch_id,
                user_id: userId,
                total_samples: batch.samples.length,
                samples_processed: samplesProcessed,
                samples_rejected: samplesRejected,
                data_types: Object.keys(dataTypeStats),
                processing_errors: processingErrors,
                batch_metadata: batch.metadata || {},
                processed_at: new Date().toISOString(),
            });
    } catch (error) {
        console.error("Failed to log batch metadata:", error);
    }

    const message = samplesRejected > 0
        ? `Processed ${samplesProcessed} samples, rejected ${samplesRejected}`
        : `Successfully processed ${samplesProcessed} samples`;

    return {
        samples_processed: samplesProcessed,
        samples_rejected: samplesRejected,
        message,
        diagnostics: {
            data_type_breakdown: dataTypeStats,
            processing_errors: processingErrors.slice(0, 10), // Limit error details
            batch_size: batch.samples.length,
        },
    };
}

function isValidHealthSample(sample: HealthSample): boolean {
    // Basic validation
    if (
        !sample.id || !sample.type || !sample.unit || !sample.timestamp ||
        !sample.source
    ) {
        return false;
    }

    // Validate timestamp
    try {
        const timestamp = new Date(sample.timestamp);
        if (isNaN(timestamp.getTime())) return false;

        // Reject timestamps too far in the future or past
        const now = new Date();
        const oneDayFromNow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const oneYearAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);

        if (timestamp > oneDayFromNow || timestamp < oneYearAgo) {
            return false;
        }
    } catch {
        return false;
    }

    // Validate value based on type
    const numericValue = typeof sample.value === "string"
        ? parseFloat(sample.value)
        : sample.value;
    if (isNaN(numericValue)) return false;

    // Type-specific validation
    switch (sample.type) {
        case "steps":
            return numericValue >= 0 && numericValue <= 100000;
        case "heartRate":
            return numericValue >= 30 && numericValue <= 300;
        case "sleepDuration":
            return numericValue >= 0 && numericValue <= 24 * 60 * 60; // Max 24 hours in seconds
        case "activeEnergyBurned":
            return numericValue >= 0 && numericValue <= 10000; // Max 10000 kcal
        default:
            return numericValue >= 0; // Default: non-negative
    }
}
