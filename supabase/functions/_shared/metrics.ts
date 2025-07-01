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
    // deno-lint-ignore no-explicit-any
    const db = await client() as any;
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

/**
 * Record token usage & cost for an AI call. Writes to table `ai_token_usage`.
 */
export async function recordTokenUsage(
  userId: string,
  path: string,
  totalTokens: number,
  costUsd: number,
): Promise<void> {
  if (Deno.env.get("DENO_TESTING") === "true") return;
  try {
    const db = await client() as any;
    await db.from("ai_token_usage").insert({
      user_id: userId,
      path,
      total_tokens: totalTokens,
      cost_usd: costUsd,
      captured_at: new Date().toISOString(),
    });
  } catch (err) {
    console.warn("[metrics] failed to record token usage", err);
  }
}
