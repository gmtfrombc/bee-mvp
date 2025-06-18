import { getSupabaseClient } from "./supabase_client.ts";

let supabase: Awaited<ReturnType<typeof getSupabaseClient>> | null = null;
async function client() {
    if (!supabase) supabase = await getSupabaseClient();
    return supabase;
}

/**
 * Record latency metric (ms) for an endpoint. Inserts into table `api_latency`
 */
export async function recordLatency(path: string, ms: number): Promise<void> {
    if (Deno.env.get("DENO_TESTING") === "true") return; // skip in tests
    try {
        const db = await client();
        await db
            .from("api_latency")
            .insert({
                path,
                latency_ms: ms,
                captured_at: new Date().toISOString(),
            });
    } catch (err) {
        console.warn("[metrics] failed to record latency", err);
    }
}
