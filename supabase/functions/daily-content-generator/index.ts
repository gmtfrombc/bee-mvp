import { createClient } from "npm:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

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
    const isDev = isDevEnv || isLocalProject;

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

        // Initialize Supabase client
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // Check if content already exists for this date
        if (!force_regenerate) {
            const { data: existingContent } = await supabase
                .from("daily_feed_content")
                .select("id, title, created_at")
                .eq("content_date", contentDate)
                .single();

            if (existingContent) {
                console.log(
                    `📋 Content already exists for ${contentDate}: "${existingContent.title}"`,
                );
                return new Response(
                    JSON.stringify({
                        success: true,
                        message: "Content already exists for this date",
                        content_date: contentDate,
                        existing_content: existingContent,
                        generated: false,
                    }),
                    {
                        status: 200,
                        headers: {
                            ...corsHeaders,
                            "Content-Type": "application/json",
                        },
                    },
                );
            }
        }

        // Prepare request payload
        const requestPayload = {
            content_date: contentDate,
            force_regenerate,
        };

        if (isDev) {
            // 🚀 Fire-and-forget in development to avoid 30s timeout in local edge-runtime
            fetch(`${aiCoachingEngineUrl}/generate-daily-content`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${supabaseServiceKey}`,
                },
                body: JSON.stringify(requestPayload),
            }).catch((e) => console.warn("⚠️ Background generate failed:", e));

            return new Response(
                JSON.stringify({
                    success: true,
                    queued: true,
                    content_date: contentDate,
                }),
                {
                    status: 202,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        // Timeout safeguard – return queued response if AI engine exceeds 25s
        const MAX_WAIT_MS = 25000;
        const generateResponse = await Promise.race([
            fetch(`${aiCoachingEngineUrl}/generate-daily-content`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${supabaseServiceKey}`,
                },
                body: JSON.stringify(requestPayload),
            }),
            new Promise<Response>((_resolve, reject) =>
                setTimeout(() => reject(new Error("timeout")), MAX_WAIT_MS)
            ),
        ]).catch((e) => {
            console.warn(
                `⚠️ AI engine call timed-out after ${MAX_WAIT_MS}ms`,
                e,
            );
            return null;
        });

        if (generateResponse === null) {
            // Treat as queued to avoid edge runtime 504
            return new Response(
                JSON.stringify({
                    success: true,
                    queued: true,
                    content_date: contentDate,
                }),
                {
                    status: 202,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        if (!generateResponse.ok) {
            const errorText = await generateResponse.text();
            throw new Error(
                `AI content generation failed: ${generateResponse.status} - ${errorText}`,
            );
        }

        const result = await generateResponse.json();

        if (!result.success) {
            throw new Error(`Content generation failed: ${result.message}`);
        }

        console.log(
            `✅ Daily content generated successfully for ${contentDate}`,
        );
        console.log(`📝 Title: "${result.content.title}"`);
        console.log(`🎯 Topic: ${result.content.topic_category}`);
        console.log(`📊 Confidence: ${result.content.ai_confidence_score}`);

        // Update job status if job_id was provided
        if (job_id && result.content) {
            try {
                await supabase.rpc("update_content_generation_job_status", {
                    p_job_id: job_id,
                    p_status: "completed",
                    p_content_id: result.content.id,
                    p_topic_category: result.content.topic_category,
                    p_ai_confidence_score: result.content.ai_confidence_score,
                    p_generation_time_ms: result.response_time_ms,
                });
                console.log(`📊 Job ${job_id} marked as completed`);
            } catch (jobError) {
                console.warn(`⚠️ Failed to update job status: ${jobError}`);
            }
        }

        // Send success response
        return new Response(
            JSON.stringify({
                success: true,
                message: "Daily content generated and saved successfully",
                content_date: contentDate,
                content: result.content,
                generated: true,
                generation_time_ms: result.response_time_ms,
            }),
            {
                status: 200,
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
