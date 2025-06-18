// deno-lint-ignore-file no-explicit-any
import { getSupabaseClient } from "./supabase_client.ts";

// Using `any` to avoid heavy type import; runtime still typed.
type SupabaseClient = any;

let client: SupabaseClient | null = null;
async function getClient(): Promise<SupabaseClient> {
    if (client) return client;
    client = await getSupabaseClient();
    return client;
}

export async function broadcastEvent(
    channel: string,
    event: string,
    payload: unknown,
): Promise<void> {
    if (Deno.env.get("DENO_TESTING") === "true") return; // no-op in tests
    const supabase = await getClient();
    const ch = supabase.channel(channel);
    const res = await ch.send({ type: "broadcast", event, payload });
    if (res !== "ok") {
        console.error("[Realtime] broadcast failed", res);
    }
    // optional: unsubscribe to avoid leaks in edge function lifetime
    ch.unsubscribe();
}
