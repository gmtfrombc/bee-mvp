import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const url = Deno.env.get("SUPABASE_URL");
const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SERVICE_ROLE_KEY");

let supabase = null as ReturnType<typeof createClient> | null;
function client() {
    if (!url || !key) throw new Error("Metrics util missing env");
    if (!supabase) supabase = createClient(url, key);
    return supabase!;
}

/**
 * Record latency metric (ms) for an endpoint. Inserts into table `api_latency`
 */
export async function recordLatency(path: string, ms: number): Promise<void> {
    if (Deno.env.get("DENO_TESTING") === "true") return; // skip in tests
    try {
        await client()
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
