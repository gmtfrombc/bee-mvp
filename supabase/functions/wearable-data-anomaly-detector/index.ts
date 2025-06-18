import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";

/*
 * Wearable Data Anomaly Detector – T2.2.3.7
 * ----------------------------------------
 * Scans a single day of `wearable_health_data` samples for out-of-range values
 * and logs anomalies into `wearable_data_anomalies`.
 */

interface AnomalyConfig {
    data_type: string;
    min?: number;
    max?: number;
}

const anomalyRules: AnomalyConfig[] = [
    { data_type: "heart_rate", min: 30, max: 230 },
    { data_type: "steps", min: 0 },
    { data_type: "hrv", min: 5, max: 250 },
    { data_type: "active_energy_burned", min: 0 },
    { data_type: "sleep_minutes", min: 0, max: 1440 },
];

const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

// Minimal structural type for query chaining
type SupabaseClientLike = {
    from: (...args: unknown[]) => any;
};

serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
    if (req.method !== "POST" && req.method !== "GET") {
        return new Response("Method not allowed", {
            status: 405,
            headers: cors,
        });
    }

    const url = new URL(req.url);
    const targetDate = url.searchParams.get("date") ||
        new Date().toISOString().split("T")[0];
    const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY");
    const client = await getSupabaseClient(serviceRole) as SupabaseClientLike;

    try {
        // Pull day samples
        const { data: samples, error } = await client
            .from("wearable_health_data")
            .select("id,user_id,data_type,value,timestamp")
            .gte("timestamp", `${targetDate}T00:00:00Z`)
            .lte("timestamp", `${targetDate}T23:59:59Z`);

        if (error) throw error;
        if (!samples?.length) {
            return new Response(
                JSON.stringify({ success: true, message: "no data" }),
                { headers: { ...cors, "Content-Type": "application/json" } },
            );
        }

        const anomalies: Array<Record<string, unknown>> = [];

        for (const s of samples) {
            const rule = anomalyRules.find((r) => r.data_type === s.data_type);
            if (!rule) continue;
            const val = Number(s.value);
            if (isNaN(val)) continue;
            if (
                (rule.min !== undefined && val < rule.min) ||
                (rule.max !== undefined && val > rule.max)
            ) {
                anomalies.push({
                    sample_id: s.id,
                    user_id: s.user_id,
                    data_type: s.data_type,
                    value: val,
                    timestamp: s.timestamp,
                    reason: `out_of_range_${s.data_type}`,
                });
            }
        }

        if (anomalies.length) {
            const { error: insertErr } = await client.from(
                "wearable_data_anomalies",
            ).insert(anomalies);
            if (insertErr) throw insertErr;
        }

        return new Response(
            JSON.stringify({
                success: true,
                scanned: samples.length,
                anomalies: anomalies.length,
            }),
            { headers: { ...cors, "Content-Type": "application/json" } },
        );
    } catch (err) {
        console.error("Anomaly detector error", err);
        return new Response(
            JSON.stringify({
                success: false,
                error: err instanceof Error ? err.message : String(err),
            }),
            {
                status: 500,
                headers: { ...cors, "Content-Type": "application/json" },
            },
        );
    }
});
