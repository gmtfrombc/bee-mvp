import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Listener for inserts/updates to `public.wearable_daily_summary`
// Triggers evaluation of JITAI rules via the ai-coaching-engine Edge Function.
// Implements Task T1.3.10.2 (Sprint-E).

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const aiCoachingEngineUrl = Deno.env.get("AI_COACHING_ENGINE_URL") ||
    "http://localhost:54321/functions/v1/ai-coaching-engine/evaluate-jitai";

interface WearableSummaryPayload {
    user_id: string;
    summary_date: string;
    steps_total?: number;
    hrv_avg?: number;
    sleep_score?: number;
    [key: string]: unknown;
}

export default async function handler(req: Request): Promise<Response> {
    if (req.method !== "POST") {
        return new Response("Method not allowed", { status: 405 });
    }

    try {
        const payload = await req.json();

        // Supabase will provide either `record` (for INSERT) or `old_record` (for UPDATE)
        // We prioritise the new record.
        const record: WearableSummaryPayload | undefined = payload.record ??
            payload.new ?? null;
        if (!record) {
            console.log("No record detected in payload – exiting early");
            return new Response("OK", { status: 200 });
        }

        const { user_id } = record;
        if (!user_id) {
            console.warn("Payload missing user_id – skipping");
            return new Response("OK", { status: 200 });
        }

        // Forward minimal event to AI Coaching Engine (evaluate-jitai path)
        const serviceToken = supabaseServiceKey;

        const res = await fetch(aiCoachingEngineUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${serviceToken}`,
                "X-System-Event": "true",
            },
            body: JSON.stringify({
                user_id,
                // Additional context for model (lightweight – avoid PHI leakage)
                system_event: "wearable_summary_update",
                wearable_metrics: {
                    steps_total: record.steps_total,
                    hrv_avg: record.hrv_avg,
                    sleep_score: record.sleep_score,
                },
            }),
        });

        if (!res.ok) {
            const text = await res.text();
            console.error("ai-coaching-engine responded with error:", text);
            return new Response("Downstream error", { status: 502 });
        }

        return new Response("OK", { status: 200 });
    } catch (err) {
        console.error("wearable-summary-listener error:", err);
        return new Response("Internal error", { status: 500 });
    }
}
