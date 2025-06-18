import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
};

interface DayLevelData {
    date: string;
    user_id: string;
    steps_total: number;
    heart_rate_avg: number;
    sleep_duration_hours: number;
    active_energy_kcal: number;
    sample_count: number;
    data_sources: string;
}

interface WearableHealthData {
    user_id: string;
    data_type: string;
    value: string;
    timestamp: string;
    source: string;
}

interface ExportParams {
    startDate: string;
    endDate: string;
    userId?: string;
}

interface AuthResult {
    supabase: SupabaseClient;
    user: User;
}

// Supabase types are only used for linting; avoid static dep weight.
type SupabaseClient = any;
type User = any;

serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    const API_VERSION = "1";
    const versionHeader = req.headers.get("X-Api-Version");
    if (!versionHeader || versionHeader !== API_VERSION) {
        return errorResponse(
            "Unsupported or missing X-Api-Version",
            "INVALID_VERSION",
            400,
        );
    }

    if (req.method !== "GET") {
        return errorResponse("Method not allowed", "METHOD_NOT_ALLOWED", 405);
    }

    try {
        const url = new URL(req.url);
        const isTestMode = url.searchParams.get("test") === "true";

        let supabase: SupabaseClient;

        if (isTestMode) {
            // For testing, create supabase client without user auth
            console.log("🔧 Running in test mode - bypassing auth");
            supabase = await getSupabaseClient(
                Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
            );
        } else {
            // Production: require authentication
            const authResult = await authenticate(req);
            supabase = authResult.supabase;
        }

        const { startDate, endDate, userId } = parseExportParams(req);

        validateDateRange(startDate, endDate);

        let aggregations: DayLevelData[];

        if (isTestMode) {
            // Use mock data for testing
            console.log("📊 Using mock data for CSV export test");
            aggregations = generateMockData(startDate, endDate, userId);
        } else {
            // Real database query
            aggregations = await fetchDayLevelData(
                supabase,
                startDate,
                endDate,
                userId,
            );
        }

        const csv = formatAsCSV(aggregations);

        return new Response(csv, {
            status: 200,
            headers: {
                ...corsHeaders,
                "Content-Type": "text/csv",
                "Content-Disposition":
                    `attachment; filename="wearable_data_${startDate}_${endDate}.csv"`,
            },
        });
    } catch (error) {
        console.error("❌ Export error:", error);
        return errorResponse(
            "Export failed",
            "EXPORT_FAILED",
            500,
            error instanceof Error ? error.message : String(error),
        );
    }
});

async function authenticate(
    req: Request,
): Promise<AuthResult> {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
        throw new Error("Missing authorization header");
    }

    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabase = await getSupabaseClient(supabaseServiceKey);

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
        throw new Error("Invalid authorization token");
    }

    return { supabase, user };
}

function parseExportParams(req: Request): ExportParams {
    const url = new URL(req.url);
    const defaultStartDate =
        new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split(
            "T",
        )[0];
    const defaultEndDate = new Date().toISOString().split("T")[0];

    return {
        startDate: url.searchParams.get("start_date") || defaultStartDate,
        endDate: url.searchParams.get("end_date") || defaultEndDate,
        userId: url.searchParams.get("user_id") || undefined,
    };
}

function validateDateRange(startDate: string, endDate: string): void {
    const daysDiff = Math.ceil(
        (new Date(endDate).getTime() - new Date(startDate).getTime()) /
            (1000 * 60 * 60 * 24),
    );

    if (daysDiff > 90) {
        throw new Error("Date range too large. Maximum 90 days allowed.");
    }
}

async function fetchDayLevelData(
    supabase: SupabaseClient,
    startDate: string,
    endDate: string,
    userId?: string,
): Promise<DayLevelData[]> {
    // Optimized query - only fetch needed columns
    let query = supabase
        .from("wearable_health_data")
        .select("user_id, data_type, value, timestamp, source")
        .gte("timestamp", `${startDate}T00:00:00Z`)
        .lte("timestamp", `${endDate}T23:59:59Z`);

    if (userId) {
        query = query.eq("user_id", userId);
    }

    const { data: healthData, error } = await query;

    if (error) {
        throw new Error(`Database query failed: ${error.message}`);
    }

    if (!healthData?.length) {
        return [];
    }

    return aggregateByDay(healthData);
}

function aggregateByDay(samples: WearableHealthData[]): DayLevelData[] {
    const dayGroups = new Map<string, WearableHealthData[]>();

    // Group samples by date-user key
    for (const sample of samples) {
        const date = new Date(sample.timestamp).toISOString().split("T")[0];
        const key = `${date}|${sample.user_id}`;

        if (!dayGroups.has(key)) {
            dayGroups.set(key, []);
        }
        dayGroups.get(key)!.push(sample);
    }

    // Calculate aggregations
    const results: DayLevelData[] = [];
    for (const [key, daySamples] of dayGroups.entries()) {
        const [date, userId] = key.split("|");
        results.push(calculateDayMetrics(date, userId, daySamples));
    }

    return results.sort((a, b) =>
        a.date.localeCompare(b.date) || a.user_id.localeCompare(b.user_id)
    );
}

function calculateDayMetrics(
    date: string,
    userId: string,
    samples: WearableHealthData[],
): DayLevelData {
    let steps = 0;
    let heartRateSum = 0;
    let heartRateCount = 0;
    let sleepMinutes = 0;
    let activeEnergy = 0;
    const sources = new Set<string>();

    for (const sample of samples) {
        sources.add(sample.source);
        const value = parseFloat(sample.value);
        if (isNaN(value)) continue;

        switch (sample.data_type) {
            case "steps":
                steps += value;
                break;
            case "heartRate":
                heartRateSum += value;
                heartRateCount++;
                break;
            case "sleepDuration":
                sleepMinutes += value;
                break;
            case "activeEnergyBurned":
                activeEnergy += value;
                break;
        }
    }

    return {
        date,
        user_id: userId,
        steps_total: Math.round(steps),
        heart_rate_avg: heartRateCount > 0
            ? Math.round(heartRateSum / heartRateCount)
            : 0,
        sleep_duration_hours: Math.round((sleepMinutes / 60) * 100) / 100,
        active_energy_kcal: Math.round(activeEnergy),
        sample_count: samples.length,
        data_sources: Array.from(sources).join(";"),
    };
}

function formatAsCSV(data: DayLevelData[]): string {
    const headers = [
        "date",
        "user_id",
        "steps_total",
        "heart_rate_avg_bpm",
        "sleep_duration_hours",
        "active_energy_kcal",
        "sample_count",
        "data_sources",
    ];

    const rows = data.map((row) => [
        row.date,
        row.user_id,
        row.steps_total.toString(),
        row.heart_rate_avg.toString(),
        row.sleep_duration_hours.toString(),
        row.active_energy_kcal.toString(),
        row.sample_count.toString(),
        `"${row.data_sources}"`,
    ]);

    return [headers, ...rows].map((row) => row.join(",")).join("\n");
}

function generateMockData(
    startDate: string,
    endDate: string,
    userId?: string,
): DayLevelData[] {
    const mockData: DayLevelData[] = [];
    const start = new Date(startDate);
    const end = new Date(endDate);

    for (const d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
        const dateStr = d.toISOString().split("T")[0];
        mockData.push({
            date: dateStr,
            user_id: userId || "test-user-123",
            steps_total: Math.floor(Math.random() * 5000) + 5000, // 5000-10000 steps
            heart_rate_avg: Math.floor(Math.random() * 30) + 60, // 60-90 bpm
            sleep_duration_hours: Math.round((Math.random() * 2 + 7) * 100) /
                100, // 7-9 hours
            active_energy_kcal: Math.floor(Math.random() * 300) + 200, // 200-500 kcal
            sample_count: Math.floor(Math.random() * 50) + 20, // 20-70 samples
            data_sources: "Garmin;HealthKit",
        });
    }

    return mockData;
}

function errorResponse(
    message: string,
    code: string,
    status: number,
    details?: string,
): Response {
    return new Response(
        JSON.stringify({
            error: message,
            error_code: code,
            ...(details && { details }),
        }),
        {
            status,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
    );
}
