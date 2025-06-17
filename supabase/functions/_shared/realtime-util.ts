import {
    createClient,
    SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

let client: SupabaseClient | null = null;

function getClient(): SupabaseClient {
    if (client) return client;
    const url = Deno.env.get("SUPABASE_URL");
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
        Deno.env.get("SERVICE_ROLE_KEY");
    if (!url || !key) {
        throw new Error(
            "Realtime util missing SUPABASE_URL or SERVICE_ROLE_KEY",
        );
    }
    client = createClient(url, key);
    return client;
}

export async function broadcastEvent(
    channel: string,
    event: string,
    payload: unknown,
): Promise<void> {
    if (Deno.env.get("DENO_TESTING") === "true") return; // no-op in tests
    const supabase = getClient();
    const ch = supabase.channel(channel);
    const res = await ch.send({ type: "broadcast", event, payload });
    if (res !== "ok") {
        console.error("[Realtime] broadcast failed", res);
    }
    // optional: unsubscribe to avoid leaks in edge function lifetime
    ch.unsubscribe();
}
