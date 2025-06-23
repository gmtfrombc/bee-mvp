// ---------------------------------------------------------------------------
// Environment helpers – make local serve resilient even if stack isn't running
// ---------------------------------------------------------------------------

// Supabase URL is injected automatically when using `supabase start`.  When we
// run `supabase functions serve` *without* starting the full stack first, the
// variable is missing and the handler crashes during early guards.  Provide a
// sensible fallback so local smoke-tests still work.

const supabaseUrl: string = Deno.env.get("SUPABASE_URL") ??
    "http://127.0.0.1:54321";

// Service-role key isn't required for the happy-path (we only send it to the
// downstream AI engine). Leave empty if not available so we don't throw.

const supabaseServiceKey: string = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SERVICE_ROLE_KEY") ?? "";

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

// After computing aiCoachingEngineUrl, add debug log
console.log(`🔗 AI Coaching engine base URL: ${aiCoachingEngineUrl}`);

export const maxDuration = 10;

// EdgeRuntime global is provided by Supabase Edge environment
// deno-lint-ignore no-explicit-any
declare const EdgeRuntime: { waitUntil: (promise: Promise<any>) => void };

/**
 * Daily Content Generator - Edge Function
 * Generates daily health content using the AI coaching engine
 * Should be scheduled to run daily at 3 AM UTC
 */
const handler = async (req: Request): Promise<Response> => {
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
        console.log("📝 Handler reached after body parse");
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

        // Determine final URL (avoid double path when colon variant supplied)
        const fetchUrl = aiCoachingEngineUrl.includes(":generate-daily-content")
            ? aiCoachingEngineUrl
            : `${aiCoachingEngineUrl}/generate-daily-content`;
        console.log(`🛰️  Using fetch URL: ${fetchUrl}`);

        // Kick off downstream generation *without* blocking the response.
        const bgTask = (async () => {
            const controller = new AbortController();
            const timeout = setTimeout(() => controller.abort(), 90000);
            let fetchOk = false;
            let fetchStatus = 0;
            let fetchBody = "";
            try {
                const resp = await fetch(
                    fetchUrl,
                    {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json",
                            "Authorization": `Bearer ${supabaseServiceKey}`,
                            "x-region": "us-west-1",
                        },
                        body: JSON.stringify(requestPayload),
                        signal: controller.signal,
                    },
                );
                fetchOk = resp.ok;
                fetchStatus = resp.status;
                try {
                    fetchBody = await resp.text();
                } catch (_err) {
                    // Non-critical: response body text couldn't be read. Safe to ignore.
                }

                // --------------------------------------------------
                // Debug: log downstream response for troubleshooting
                // --------------------------------------------------
                console.log(
                    `⬅️  downstream status ${fetchStatus}, body: ${
                        fetchBody.slice(0, 200)
                    }`,
                );
            } catch (e) {
                console.warn("⚠️ Background generate failed:", e);
            } finally {
                clearTimeout(timeout);
            }

            // ----------------------------------------------------------
            // Update job status – mark as completed if downstream call
            // accepted (>=200 & <300). Otherwise keep queued so we can
            // inspect later manually.
            // ----------------------------------------------------------
            try {
                if (job_id && fetchOk) {
                    await updateJobStatus(job_id, "completed");
                    console.log(
                        `📊 Job ${job_id} marked as completed (via BG task)`,
                    );
                } else if (job_id && !fetchOk) {
                    await updateJobStatus(
                        job_id,
                        "failed",
                        `Downstream status ${fetchStatus}: ${
                            fetchBody.slice(0, 200)
                        }`,
                    );
                    console.warn(
                        `⚠️ Job ${job_id} failed – downstream status ${fetchStatus}`,
                    );
                }
            } catch (e) {
                console.warn("⚠️ Could not mark job completed:", e);
            }
        })();

        // Use EdgeRuntime.waitUntil when available (on the hosted platform).
        // Fall back to a detached promise locally so we don't crash.
        interface EdgeRuntimeLike {
            waitUntil?: (promise: Promise<unknown>) => void;
        }
        const _edge =
            (globalThis as { EdgeRuntime?: EdgeRuntimeLike }).EdgeRuntime;
        if (_edge?.waitUntil) {
            _edge.waitUntil(bgTask);
        } else {
            // Execute without blocking the response
            bgTask.catch(() => {});
        }

        const response = new Response(
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
        console.log("✅ Responding 202 early");
        return response;
    } catch (error) {
        console.error("❌ Error in daily content generation:", error);

        // Update job status if job_id was provided
        if (job_id) {
            try {
                await updateJobStatus(
                    job_id,
                    "failed",
                    error instanceof Error ? error.message : "Unknown error",
                );
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
};

// Start the Edge function HTTP server (Supabase runtime picks this up)
Deno.serve(handler);

export default handler;

// Remove heavy supabase-js dependency; use lightweight PostgREST RPC call on error
async function updateJobStatus(
    job_id: string,
    status: string,
    error_message?: string,
) {
    const url =
        `${supabaseUrl}/rest/v1/rpc/update_content_generation_job_status`;
    const body = {
        p_job_id: job_id,
        p_status: status,
        p_error_message: error_message ?? null,
    };

    await fetch(url, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "apikey": supabaseServiceKey,
            "Authorization": `Bearer ${supabaseServiceKey}`,
            "Prefer": "return=representation",
        },
        body: JSON.stringify(body),
    }).catch((e) => console.warn("⚠️ Failed to call RPC:", e));
}
