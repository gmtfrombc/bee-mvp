import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";

/*
 * Wearable Correlation Analysis – T2.2.3.8
 * ---------------------------------------
 * Computes simple Pearson correlations between physiological metrics (steps,
 * avg_hr, sleep_hours, hrv_avg) for a given date across all users and stores
 * results in `wearable_daily_correlations`.
 */

const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

function pearson(x: number[], y: number[]): number | null {
    if (x.length !== y.length || x.length < 2) return null;
    const n = x.length;
    const sumX = x.reduce((a, b) => a + b, 0);
    const sumY = y.reduce((a, b) => a + b, 0);
    const sumXY = x.reduce((a, _, i) => a + x[i] * y[i], 0);
    const sumX2 = x.reduce((a, b) => a + b * b, 0);
    const sumY2 = y.reduce((a, b) => a + b * b, 0);
    const numerator = (n * sumXY) - (sumX * sumY);
    const denominator = Math.sqrt(
        ((n * sumX2) - (sumX ** 2)) * ((n * sumY2) - (sumY ** 2)),
    );
    if (denominator === 0) return null;
    return Number((numerator / denominator).toFixed(4));
}

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
    // deno-lint-ignore no-explicit-any
    const client: any = await getSupabaseClient(serviceRole);

    try {
        const { data: summaries, error } = await client
            .from("wearable_daily_summary")
            .select("user_id, steps_total, avg_hr, sleep_hours, hrv_avg")
            .eq("summary_date", targetDate);
        if (error) throw error;
        if (!summaries?.length) {
            return new Response(
                JSON.stringify({ success: true, message: "no summaries" }),
                { headers: { ...cors, "Content-Type": "application/json" } },
            );
        }

        // Build metric arrays in user-aligned order
        type SummaryRow = {
            steps_total: number | null;
            avg_hr: number | null;
            sleep_hours: number | null;
            hrv_avg: number | null;
        };
        const castSummaries = summaries as unknown as SummaryRow[];
        const steps = castSummaries.map((s) => Number(s.steps_total || 0));
        const hr = castSummaries.map((s) => Number(s.avg_hr || 0));
        const sleep = castSummaries.map((s) => Number(s.sleep_hours || 0));
        const hrv = castSummaries.map((s) => Number(s.hrv_avg || 0));

        const correlations = {
            steps_vs_hr: pearson(steps, hr),
            steps_vs_sleep: pearson(steps, sleep),
            steps_vs_hrv: pearson(steps, hrv),
            hr_vs_sleep: pearson(hr, sleep),
            hr_vs_hrv: pearson(hr, hrv),
            sleep_vs_hrv: pearson(sleep, hrv),
        } as Record<string, number | null>;

        const { error: upErr } = await client.from(
            "wearable_daily_correlations",
        ).upsert({
            summary_date: targetDate,
            correlations,
            computed_at: new Date().toISOString(),
        }, { onConflict: "summary_date" });
        if (upErr) throw upErr;

        return new Response(JSON.stringify({ success: true, correlations }), {
            headers: { ...cors, "Content-Type": "application/json" },
        });
    } catch (err) {
        console.error("Correlation error", err);
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
