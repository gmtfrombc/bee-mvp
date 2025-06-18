import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";

const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type, x-api-version",
};

const API_VERSION = "1";

type SupabaseClient = any;

export async function handleRequest(req: Request): Promise<Response> {
    if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

    const versionHeader = req.headers.get("X-Api-Version");
    if (!versionHeader || versionHeader !== API_VERSION) {
        return json({ error: "Unsupported or missing X-Api-Version" }, 400);
    }

    // Require service-role key for now (skip in test mode)
    const isTest = Deno.env.get("DENO_TESTING") === "true";
    const auth = req.headers.get("Authorization")?.replace("Bearer ", "");
    const srKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY");
    if (!isTest && (!auth || auth !== srKey)) {
        return json({ error: "Unauthorized" }, 401);
    }

    const url = new URL(req.url);
    const pathname = url.pathname;
    const matches = (e: string) =>
        pathname.endsWith(e) || pathname.endsWith(`/v${API_VERSION}${e}`);

    if (matches("/history")) {
        return await handleHistory(url);
    }

    return json({ error: "Not found" }, 404);
}

async function handleHistory(url: URL): Promise<Response> {
    const userId = url.searchParams.get("user_id");
    const limitStr = url.searchParams.get("limit") || "20";
    const limit = Math.min(100, Math.max(1, parseInt(limitStr)));
    if (!userId) return json({ error: "user_id required" }, 400);

    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY");
    const client: SupabaseClient = await getSupabaseClient(serviceKey);

    const { data, error } = await client
        .from("coach_interactions")
        .select("id, sender, message, metadata, created_at")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(limit);

    if (error) return json({ error: error.message }, 500);
    return json({ user_id: userId, interactions: data }, 200);
}

function json(payload: unknown, status = 200): Response {
    return new Response(JSON.stringify(payload), {
        status,
        headers: { ...cors, "Content-Type": "application/json" },
    });
}

// Auto-start server in production runtime
if (import.meta.main) {
    serve(handleRequest);
}
