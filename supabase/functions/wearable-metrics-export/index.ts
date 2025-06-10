// Wearable Metrics Export Function for T2.2.2.10
// Exports live streaming metrics for Grafana dashboard consumption

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

interface WearableMetrics {
    timestamp: string;
    messages_per_minute: number;
    median_latency_ms: number;
    error_rate: number;
    total_messages: number;
    total_errors: number;
}

serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const supabaseClient = createClient(
            Deno.env.get("SUPABASE_URL") ?? "",
            Deno.env.get("SUPABASE_ANON_KEY") ?? "",
            {
                global: {
                    headers: {
                        Authorization: req.headers.get("Authorization")!,
                    },
                },
            },
        );

        if (req.method === "GET") {
            return handleMetricsQuery(supabaseClient, req);
        }

        if (req.method === "POST") {
            return handleMetricsIngest(supabaseClient, req);
        }

        return new Response("Method not allowed", {
            status: 405,
            headers: corsHeaders,
        });
    } catch (error) {
        console.error("Error in wearable-metrics-export:", error);
        return new Response(
            JSON.stringify({
                error: error instanceof Error ? error.message : "Unknown error",
            }),
            {
                status: 500,
                headers: {
                    ...corsHeaders,
                    "Content-Type": "application/json",
                },
            },
        );
    }
});

async function handleMetricsQuery(
    supabaseClient: any,
    req: Request,
): Promise<Response> {
    const url = new URL(req.url);
    const format = url.searchParams.get("format") || "json";
    const timeRange = url.searchParams.get("range") || "1h";

    try {
        // Calculate time range
        const now = new Date();
        const startTime = new Date(now.getTime() - parseTimeRange(timeRange));

        // Query recent wearable live metrics
        const { data: metrics, error } = await supabaseClient
            .from("wearable_live_metrics")
            .select("*")
            .gte("timestamp", startTime.toISOString())
            .order("timestamp", { ascending: true });

        if (error) {
            throw error;
        }

        // Format for Prometheus/Grafana
        if (format === "prometheus") {
            return formatPrometheusMetrics(metrics);
        }

        // Default JSON format
        const aggregatedMetrics = aggregateMetrics(metrics);

        return new Response(
            JSON.stringify({
                timestamp: now.toISOString(),
                time_range: timeRange,
                metrics: aggregatedMetrics,
                data_points: metrics.length,
            }),
            {
                status: 200,
                headers: {
                    ...corsHeaders,
                    "Content-Type": "application/json",
                },
            },
        );
    } catch (error) {
        console.error("Error querying metrics:", error);
        return new Response(
            JSON.stringify({ error: "Failed to query metrics" }),
            {
                status: 500,
                headers: {
                    ...corsHeaders,
                    "Content-Type": "application/json",
                },
            },
        );
    }
}

async function handleMetricsIngest(
    supabaseClient: any,
    req: Request,
): Promise<Response> {
    try {
        const body = await req.json();
        const { user_id, metrics } = body;

        if (!metrics) {
            return new Response(
                JSON.stringify({ error: "Metrics data required" }),
                {
                    status: 400,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        // Insert metrics into database
        const { error } = await supabaseClient
            .from("wearable_live_metrics")
            .insert({
                user_id,
                timestamp: new Date().toISOString(),
                messages_per_minute: metrics.messages_per_minute || 0,
                median_latency_ms: metrics.median_latency_ms || 0,
                error_rate: metrics.error_rate || 0,
                total_messages: metrics.total_messages || 0,
                total_errors: metrics.total_errors || 0,
                metadata: metrics.metadata || {},
            });

        if (error) {
            throw error;
        }

        return new Response(
            JSON.stringify({
                success: true,
                timestamp: new Date().toISOString(),
            }),
            {
                status: 201,
                headers: {
                    ...corsHeaders,
                    "Content-Type": "application/json",
                },
            },
        );
    } catch (error) {
        console.error("Error ingesting metrics:", error);
        return new Response(
            JSON.stringify({ error: "Failed to ingest metrics" }),
            {
                status: 500,
                headers: {
                    ...corsHeaders,
                    "Content-Type": "application/json",
                },
            },
        );
    }
}

function parseTimeRange(range: string): number {
    const unit = range.slice(-1);
    const value = parseInt(range.slice(0, -1));

    switch (unit) {
        case "m":
            return value * 60 * 1000; // minutes
        case "h":
            return value * 60 * 60 * 1000; // hours
        case "d":
            return value * 24 * 60 * 60 * 1000; // days
        default:
            return 60 * 60 * 1000; // default 1 hour
    }
}

function aggregateMetrics(metrics: any[]): WearableMetrics {
    if (metrics.length === 0) {
        return {
            timestamp: new Date().toISOString(),
            messages_per_minute: 0,
            median_latency_ms: 0,
            error_rate: 0,
            total_messages: 0,
            total_errors: 0,
        };
    }

    // Get most recent metrics
    const latest = metrics[metrics.length - 1];

    // Calculate averages over time window
    const avgMessagesPerMinute =
        metrics.reduce((sum, m) => sum + (m.messages_per_minute || 0), 0) /
        metrics.length;

    const latencies = metrics
        .filter((m) => m.median_latency_ms > 0)
        .map((m) => m.median_latency_ms);

    const medianLatency = calculateMedian(latencies);

    const avgErrorRate =
        metrics.reduce((sum, m) => sum + (m.error_rate || 0), 0) /
        metrics.length;

    return {
        timestamp: latest.timestamp,
        messages_per_minute: avgMessagesPerMinute,
        median_latency_ms: medianLatency,
        error_rate: avgErrorRate,
        total_messages: latest.total_messages || 0,
        total_errors: latest.total_errors || 0,
    };
}

function calculateMedian(values: number[]): number {
    if (values.length === 0) return 0;

    const sorted = [...values].sort((a, b) => a - b);
    const middle = Math.floor(sorted.length / 2);

    if (sorted.length % 2 === 0) {
        return (sorted[middle - 1] + sorted[middle]) / 2;
    }
    return sorted[middle];
}

function formatPrometheusMetrics(metrics: any[]): Response {
    if (metrics.length === 0) {
        return new Response("", {
            status: 200,
            headers: {
                ...corsHeaders,
                "Content-Type": "text/plain",
            },
        });
    }

    const latest = aggregateMetrics(metrics);
    const timestamp = Math.floor(Date.now() / 1000);

    const prometheusFormat = `
# HELP wearable_live_messages_per_minute Number of wearable messages processed per minute
# TYPE wearable_live_messages_per_minute gauge
wearable_live_messages_per_minute ${latest.messages_per_minute} ${timestamp}

# HELP wearable_live_median_latency_ms Median latency of wearable message processing in milliseconds
# TYPE wearable_live_median_latency_ms gauge
wearable_live_median_latency_ms ${latest.median_latency_ms} ${timestamp}

# HELP wearable_live_error_rate Rate of errors in wearable message processing
# TYPE wearable_live_error_rate gauge
wearable_live_error_rate ${latest.error_rate} ${timestamp}

# HELP wearable_live_total_messages Total number of wearable messages processed
# TYPE wearable_live_total_messages counter
wearable_live_total_messages ${latest.total_messages} ${timestamp}

# HELP wearable_live_total_errors Total number of wearable processing errors
# TYPE wearable_live_total_errors counter
wearable_live_total_errors ${latest.total_errors} ${timestamp}
`.trim();

    return new Response(prometheusFormat, {
        status: 200,
        headers: {
            ...corsHeaders,
            "Content-Type": "text/plain",
        },
    });
}
