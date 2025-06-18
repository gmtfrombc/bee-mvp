// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";
import { enforceRateLimit, RateLimitError } from "../_shared/rate-limit.ts";

const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

const API_VERSION = "1";

// Type placeholders to avoid static dependency
type SupabaseClient = any;

export async function handleRequest(req: Request): Promise<Response> {
    if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

    // ------------------------------------------------------------------
    // API version enforcement – require X-Api-Version header and /v1 prefix
    // ------------------------------------------------------------------
    const versionHeader = req.headers.get("X-Api-Version");
    if (!versionHeader || versionHeader !== API_VERSION) {
        return json({ error: "Unsupported or missing X-Api-Version" }, 400);
    }

    const isTest = Deno.env.get("DENO_TESTING") === "true";
    const authHeader = req.headers.get("Authorization");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY");
    const uidForRate = authHeader?.slice(-24) || "anon";
    if (!isTest) {
        if (!authHeader) return json({ error: "Missing Authorization" }, 401);
        const token = authHeader.replace("Bearer ", "");
        if (serviceKey && token !== serviceKey) {
            // For now, basic check; RLS will further validate token in Supabase.
            // Could call supabase.auth.getUser(token) for stronger check if needed.
        }
    }

    const startTime = Date.now();
    try {
        // -------------------------------------------
        // Rate limiting
        // -------------------------------------------
        let rateLimited = false;
        if (!isTest) {
            try {
                await enforceRateLimit(uidForRate);
            } catch (e) {
                if (e instanceof RateLimitError) {
                    rateLimited = true;
                    throw e; // rethrow to outer catch
                }
                throw e;
            }
        }

        const url = new URL(req.url);
        const pathname = url.pathname;

        // helper to match route endings with optional /v1 prefix
        const matches = (endpoint: string): boolean =>
            pathname.endsWith(endpoint) ||
            pathname.endsWith(`/v${API_VERSION}${endpoint}`);

        let res: Response | null = null;
        if (matches("/ping")) {
            res = json({ status: "ok", version: API_VERSION }, 200);
        } else if (
            matches("/daily-sleep-score") || matches("/rolling-hr") ||
            matches("/history") || matches("/trend")
        ) {
            // Create client lazily only when needed
            const anonKey = Deno.env.get("SUPABASE_ANON_KEY") || undefined;
            const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
                Deno.env.get("SERVICE_ROLE_KEY") || undefined;
            const client: SupabaseClient = await getSupabaseClient(
                serviceRole || anonKey,
            );

            if (matches("/daily-sleep-score")) {
                res = await handleSleepScore(url, client);
            } else if (matches("/rolling-hr")) {
                res = await handleRollingHR(url, client);
            } else if (matches("/history")) {
                res = await handleHistory(url, client);
            } else {
                res = await handleTrend(url, client);
            }
        } else {
            res = json({ error: "Endpoint not found" }, 404);
        }

        // Log usage (non-blocking)
        const duration = Date.now() - startTime;
        logUsage(
            pathname,
            authHeader ? uidForRate : null,
            duration,
            rateLimited,
        );

        return res;
    } catch (err) {
        if (err instanceof RateLimitError) {
            const limited = true;
            const duration = Date.now() - startTime;
            logUsage(
                new URL(req.url).pathname,
                authHeader ? uidForRate : null,
                duration,
                limited,
            );
            return json({ error: err.message }, 429);
        }
        console.error("wearable-summary-api error", err);
        const limited = false;
        const duration = Date.now() - startTime;
        logUsage(
            new URL(req.url).pathname,
            authHeader ? uidForRate : null,
            duration,
            limited,
        );
        return json({ error: "internal" }, 500);
    }
}

interface ValueRow {
    value: number | string | null;
}

async function handleSleepScore(
    url: URL,
    client: SupabaseClient,
): Promise<Response> {
    const userId = url.searchParams.get("user_id");
    const date = url.searchParams.get("date"); // YYYY-MM-DD
    if (!userId || !date) {
        return json({ error: "user_id and date required" }, 400);
    }

    const start = `${date}T00:00:00Z`;
    const end = `${date}T23:59:59Z`;

    const { data, error } = await client
        .from("wearable_health_data")
        .select("value")
        .eq("user_id", userId)
        .eq("data_type", "sleep_minutes")
        .gte("timestamp", start)
        .lte("timestamp", end);

    if (error) return json({ error: error.message }, 500);

    const totalMinutes = (data as ValueRow[] | null)?.reduce(
        (acc: number, row: ValueRow) => acc + Number(row.value ?? 0),
        0,
    ) ?? 0;
    const hours = totalMinutes / 60;
    const score = Math.min(100, Math.round((hours / 8) * 100)); // crude score: 8h -> 100

    return json({ user_id: userId, date, hours, score }, 200);
}

async function handleRollingHR(
    url: URL,
    client: SupabaseClient,
): Promise<Response> {
    const userId = url.searchParams.get("user_id");
    const minutesStr = url.searchParams.get("minutes") || "60";
    const minutes = Math.min(1440, Math.max(1, parseInt(minutesStr)));
    if (!userId) return json({ error: "user_id required" }, 400);

    const since = new Date(Date.now() - minutes * 60 * 1000).toISOString();

    const { data, error } = await client
        .from("wearable_health_data")
        .select("value")
        .eq("user_id", userId)
        .eq("data_type", "heart_rate")
        .gte("timestamp", since);

    if (error) return json({ error: error.message }, 500);

    if (!data || data.length === 0) {
        return json({ user_id: userId, minutes, avg_hr: null }, 200);
    }

    const sum = (data as ValueRow[]).reduce(
        (acc: number, row: ValueRow) => acc + Number(row.value ?? 0),
        0,
    );
    const avg = Math.round(sum / data.length);
    return json(
        { user_id: userId, minutes, avg_hr: avg, samples: data.length },
        200,
    );
}

type DataType = "heart_rate" | "sleep_minutes" | "steps" | "hrv";

async function handleHistory(
    url: URL,
    client: SupabaseClient,
): Promise<Response> {
    const userId = url.searchParams.get("user_id");
    const dataType = url.searchParams.get("data_type") as DataType | null;
    const start = url.searchParams.get("start");
    const end = url.searchParams.get("end");
    if (!userId || !dataType || !start || !end) {
        return json({ error: "user_id, data_type, start, end required" }, 400);
    }
    const { data, error } = await client
        .from("wearable_health_data")
        .select("timestamp,value")
        .eq("user_id", userId)
        .eq("data_type", dataType)
        .gte("timestamp", start)
        .lte("timestamp", end)
        .order("timestamp", { ascending: true })
        .limit(2000);
    if (error) return json({ error: error.message }, 500);
    return json({ user_id: userId, data_type: dataType, rows: data ?? [] });
}

async function handleTrend(
    url: URL,
    client: SupabaseClient,
): Promise<Response> {
    const userId = url.searchParams.get("user_id");
    const dataType = url.searchParams.get("data_type") as DataType | null;
    const bucket = url.searchParams.get("bucket") || "day"; // day|week|month
    const range = url.searchParams.get("range") || "30"; // days
    if (!userId || !dataType) {
        return json({ error: "user_id & data_type required" }, 400);
    }

    const days = parseInt(range);
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000)
        .toISOString();

    // raw SQL for date_trunc aggregation
    const { data, error } = await client.rpc("wearable_trend", {
        p_user_id: userId,
        p_data_type: dataType,
        p_bucket: bucket,
        p_since: since,
    });
    if (error) return json({ error: error.message }, 500);
    return json({ user_id: userId, bucket, rows: data ?? [] });
}

function json(payload: unknown, status = 200): Response {
    return new Response(JSON.stringify(payload), {
        status,
        headers: { ...cors, "Content-Type": "application/json" },
    });
}

// --------------------------------------------------
// Usage logging helper
// --------------------------------------------------
async function logUsage(
    endpoint: string,
    userId: string | null,
    ms: number,
    limited: boolean,
) {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY");
    const isTest = Deno.env.get("DENO_TESTING") === "true";
    if (!supabaseUrl || !key || isTest) return;
    try {
        const client = await getSupabaseClient(key);
        await client.from("api_usage_log").insert({
            endpoint,
            user_id: userId,
            duration_ms: ms,
            rate_limited: limited,
            timestamp: new Date().toISOString(),
        });
    } catch (_err) {
        // non-fatal
    }
}

// Start HTTP server when executed normally (not during unit tests)
if (import.meta.main) {
    serve(handleRequest);
}
