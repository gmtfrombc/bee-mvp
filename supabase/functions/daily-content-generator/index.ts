import { createClient } from "npm:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SERVICE_ROLE_KEY")!;

// Determine AI coaching engine URL.
// Priority: env override > same Supabase project Edge Function route.
let aiCoachingEngineUrl = Deno.env.get("AI_COACHING_ENGINE_URL");
if (!aiCoachingEngineUrl || aiCoachingEngineUrl.trim().length === 0) {
    // Derive from project Supabase URL – replace path and append function route
    // e.g. https://abcd.supabase.co -> https://abcd.supabase.co/functions/v1/ai-coaching-engine
    try {
        const supaUri = new URL(supabaseUrl);
        aiCoachingEngineUrl =
            `${supaUri.origin}/functions/v1/ai-coaching-engine`;
    } catch (_) {
        // Fallback to localhost (local dev)
        aiCoachingEngineUrl =
            "http://localhost:54321/functions/v1/ai-coaching-engine";
    }
}

/**
 * Daily Content Generator - Edge Function
 * Generates daily health content using the AI coaching engine
 * Should be scheduled to run daily at 3 AM UTC
 */
export default async function handler(req: Request): Promise<Response> {
    // Only allow POST requests (from cron or manual trigger)
    if (req.method !== "POST") {
        return new Response("Method not allowed", { status: 405 });
    }

    const corsHeaders = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
            "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
    };

    // Detect development environment (local CLI) – ENVIRONMENT is set via .env or config.toml
    const isDevEnv =
        (Deno.env.get("ENVIRONMENT") || "development") === "development";
    const isLocalProject = supabaseUrl.startsWith("http://") &&
        (supabaseUrl.includes("127.0.0.1") ||
            supabaseUrl.includes("localhost"));
    const _isDev = isDevEnv || isLocalProject;

    let job_id: string | undefined;

    try {
        const body = await req.json().catch(() => ({}));
        const { target_date, force_regenerate = false } = body;
        job_id = body.job_id;

        // Use target date or default to today
        const contentDate = target_date ||
            new Date().toISOString().split("T")[0];

        console.log(`🌅 Starting daily content generation for ${contentDate}`);
        if (job_id) {
            console.log(`📊 Job ID: ${job_id}`);
        }

        /* ------------------------------------------------------------------
         * Fast-return: immediately queue generation in background and respond
         *  (placed BEFORE any heavyweight DB/network init to avoid edge timeouts)
         * ------------------------------------------------------------------*/
        const requestPayload = {
            content_date: contentDate,
            force_regenerate,
        };

        // Fire-and-forget call to AI coaching engine – detach after 5 s to avoid
        // keeping the event-loop alive and hitting the 30 s gateway timeout.
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 5000);
        fetch(`${aiCoachingEngineUrl}/generate-daily-content`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${supabaseServiceKey}`,
                // Execute downstream function in the same region to minimise latency
                "x-region": "us-west-1",
            },
            body: JSON.stringify(requestPayload),
            signal: controller.signal,
        }).catch((e) => console.warn("⚠️ Background generate failed:", e))
            .finally(() => clearTimeout(timeout));

        return new Response(
            JSON.stringify({
                success: true,
                queued: true,
                content_date: contentDate,
            }),
            {
                status: 202,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
        );
    } catch (error) {
        console.error("❌ Error in daily content generation:", error);

        // Update job status if job_id was provided
        if (job_id) {
            try {
                const supabase = createClient(supabaseUrl, supabaseServiceKey);
                await supabase.rpc("update_content_generation_job_status", {
                    p_job_id: job_id,
                    p_status: "failed",
                    p_error_message: error instanceof Error
                        ? error.message
                        : "Unknown error",
                });
                console.log(`📊 Job ${job_id} marked as failed`);
            } catch (jobError) {
                console.warn(`⚠️ Failed to update job status: ${jobError}`);
            }
        }

        return new Response(
            JSON.stringify({
                success: false,
                error: "Failed to generate daily content",
                message: error instanceof Error
                    ? error.message
                    : "Unknown error",
                timestamp: new Date().toISOString(),
            }),
            {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
        );
    }
}
