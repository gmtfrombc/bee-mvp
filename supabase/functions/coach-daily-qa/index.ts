import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";

/*
 * Coach Daily QA Check – T1.3.6.5
 * --------------------------------
 * Simple quality-assurance job that examines the previous day's conversation
 * logs and records high-level metrics into `coach_daily_qa`.
 */

serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok");
    if (req.method !== "POST" && req.method !== "GET") {
        return new Response("Method not allowed", { status: 405 });
    }

    const url = new URL(req.url);
    const targetDate = url.searchParams.get("date") ||
        new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split("T")[0];

    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY") || "";
    const client = await getSupabaseClient(serviceRole);

    try {
        // Fetch assistant messages for the date
        const { data: logs, error } = await client
            .from("conversation_logs")
            .select("id,response_time_ms,persona")
            .gte("created_at", `${targetDate}T00:00:00Z`)
            .lte("created_at", `${targetDate}T23:59:59Z`)
            .eq("sender", "assistant");
        if (error) throw error;

        if (!logs || logs.length === 0) {
            return new Response(
                JSON.stringify({ success: true, message: "no data" }),
                { headers: { "Content-Type": "application/json" } },
            );
        }

        const total = logs.length;
        const medianResponse = median(
            logs.map((l: any) => l.response_time_ms || 0),
        );
        const personaCounts: Record<string, number> = {};
        logs.forEach((l: any) => {
            personaCounts[l.persona] = (personaCounts[l.persona] || 0) + 1;
        });

        await client.from("coach_daily_qa").upsert({
            summary_date: targetDate,
            total_messages: total,
            median_response_ms: medianResponse,
            persona_distribution: personaCounts,
        }, { onConflict: "summary_date" });

        return new Response(
            JSON.stringify({ success: true, total, medianResponse }),
            { headers: { "Content-Type": "application/json" } },
        );
    } catch (err) {
        console.error("QA check error", err);
        return new Response(
            JSON.stringify({
                success: false,
                error: err instanceof Error ? err.message : String(err),
            }),
            { status: 500, headers: { "Content-Type": "application/json" } },
        );
    }
});

function median(values: number[]): number {
    if (values.length === 0) return 0;
    const sorted = [...values].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 !== 0
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
}
