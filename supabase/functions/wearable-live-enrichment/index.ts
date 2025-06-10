import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface WearableLiveMessage {
    timestamp: string;
    type: string;
    value: number;
    source: string;
}

interface EnrichedWearableData {
    user_id: string;
    data_type: string;
    raw_value: number;
    unit: string;
    timestamp: string;
    source: string;
    rolling_avg_5min?: number;
    rolling_avg_15min?: number;
    rolling_avg_30min?: number;
    value_trend?: string;
    battery_level_percent?: number;
    battery_status?: string;
    device_connected: boolean;
    enrichment_version: string;
    processing_latency_ms: number;
}

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    if (req.method !== "POST") {
        return new Response(
            JSON.stringify({ error: "Method not allowed" }),
            {
                status: 405,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
        );
    }

    const startTime = Date.now();

    try {
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        const payload = await req.json();
        const { userId, deltaPacket } = payload as {
            userId: string;
            deltaPacket: WearableLiveMessage;
        };

        if (!userId || !deltaPacket) {
            return new Response(
                JSON.stringify({ error: "Missing userId or deltaPacket" }),
                {
                    status: 400,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        // Calculate rolling averages
        const rollingAverages = await calculateRollingAverages(
            supabase,
            userId,
            deltaPacket.type,
            deltaPacket.value,
            new Date(deltaPacket.timestamp),
        );

        // Extract battery information
        const batteryInfo = extractBatteryInfo(deltaPacket.source);

        // Determine value trend
        const valueTrend = await calculateValueTrend(
            supabase,
            userId,
            deltaPacket.type,
            deltaPacket.value,
            new Date(deltaPacket.timestamp),
        );

        // Create enriched data
        const enrichedData: EnrichedWearableData = {
            user_id: userId,
            data_type: deltaPacket.type,
            raw_value: deltaPacket.value,
            unit: getUnitForDataType(deltaPacket.type),
            timestamp: deltaPacket.timestamp,
            source: deltaPacket.source,
            rolling_avg_5min: rollingAverages.avg5min,
            rolling_avg_15min: rollingAverages.avg15min,
            rolling_avg_30min: rollingAverages.avg30min,
            value_trend: valueTrend,
            battery_level_percent: batteryInfo.level,
            battery_status: batteryInfo.status,
            device_connected: true,
            enrichment_version: "v1.0",
            processing_latency_ms: Date.now() - startTime,
        };

        // Store enriched data
        const { error: insertError } = await supabase
            .from("wearable_live_enriched")
            .insert(enrichedData);

        if (insertError) {
            console.error("Failed to insert enriched data:", insertError);
            return new Response(
                JSON.stringify({ error: "Database insertion failed" }),
                {
                    status: 500,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        // Publish to enriched channel
        const channelName = `wearable_live_enriched:${userId}`;
        await supabase.channel(channelName).send({
            type: "broadcast",
            event: "enriched_data",
            payload: enrichedData,
        });

        const processingTime = Date.now() - startTime;

        return new Response(
            JSON.stringify({
                success: true,
                processing_time_ms: processingTime,
                enriched_data: enrichedData,
            }),
            {
                status: 200,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
        );
    } catch (error) {
        console.error("Enrichment processing error:", error);
        return new Response(
            JSON.stringify({
                error: "Internal server error",
                details: error instanceof Error
                    ? error.message
                    : "Unknown error",
            }),
            {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
        );
    }
});

async function calculateRollingAverages(
    supabase: any,
    userId: string,
    dataType: string,
    currentValue: number,
    timestamp: Date,
): Promise<{ avg5min?: number; avg15min?: number; avg30min?: number }> {
    const intervals = [
        { minutes: 5, key: "avg5min" },
        { minutes: 15, key: "avg15min" },
        { minutes: 30, key: "avg30min" },
    ];

    const results: any = {};

    for (const interval of intervals) {
        const startTime = new Date(
            timestamp.getTime() - (interval.minutes * 60 * 1000),
        );

        const { data, error } = await supabase
            .from("wearable_health_data")
            .select("value")
            .eq("user_id", userId)
            .eq("data_type", dataType)
            .gte("timestamp", startTime.toISOString())
            .lte("timestamp", timestamp.toISOString())
            .order("timestamp", { ascending: false })
            .limit(100);

        if (!error && data && data.length > 0) {
            const values = data.map((row: any) => parseFloat(row.value));
            values.unshift(currentValue); // Include current value
            const average = values.reduce((sum: number, val: number) =>
                sum + val, 0) /
                values.length;
            results[interval.key] = Math.round(average * 100) / 100;
        }
    }

    return results;
}

function extractBatteryInfo(
    source: string,
): { level?: number; status: string } {
    // Extract battery info from source metadata or device identifier
    // This is a simplified implementation - in practice, battery info would come from device metadata
    const defaultInfo = { status: "unknown" as const };

    if (source.toLowerCase().includes("garmin")) {
        // Garmin devices typically report battery in device metadata
        return { level: 85, status: "not_charging" };
    } else if (source.toLowerCase().includes("apple")) {
        // Apple Health doesn't typically include battery info
        return defaultInfo;
    }

    return defaultInfo;
}

async function calculateValueTrend(
    supabase: any,
    userId: string,
    dataType: string,
    currentValue: number,
    timestamp: Date,
): Promise<string> {
    // Get recent values to determine trend
    const startTime = new Date(timestamp.getTime() - (10 * 60 * 1000)); // Last 10 minutes

    const { data, error } = await supabase
        .from("wearable_health_data")
        .select("value, timestamp")
        .eq("user_id", userId)
        .eq("data_type", dataType)
        .gte("timestamp", startTime.toISOString())
        .lt("timestamp", timestamp.toISOString())
        .order("timestamp", { ascending: true })
        .limit(10);

    if (error || !data || data.length < 2) {
        return "stable";
    }

    const values = data.map((row: any) => parseFloat(row.value));
    values.push(currentValue);

    // Simple trend calculation
    const firstHalf = values.slice(0, Math.floor(values.length / 2));
    const secondHalf = values.slice(Math.floor(values.length / 2));

    const firstAvg =
        firstHalf.reduce((sum: number, val: number) => sum + val, 0) /
        firstHalf.length;
    const secondAvg =
        secondHalf.reduce((sum: number, val: number) => sum + val, 0) /
        secondHalf.length;

    const thresholdPercent = 0.05; // 5% threshold
    const change = (secondAvg - firstAvg) / firstAvg;

    if (change > thresholdPercent) return "rising";
    if (change < -thresholdPercent) return "falling";
    return "stable";
}

function getUnitForDataType(dataType: string): string {
    const unitMap: Record<string, string> = {
        "heartRate": "bpm",
        "steps": "count",
        "sleepDuration": "minutes",
        "activeEnergyBurned": "kcal",
        "distanceWalking": "meters",
        "weight": "kg",
    };

    return unitMap[dataType] || "unknown";
}
