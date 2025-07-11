import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";

const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type, x-api-version",
};

const API_VERSION = "1";

type SupabaseClientLike = {
    from: (...args: unknown[]) => unknown;
    rpc: (...args: unknown[]) => unknown;
};

type RPCResult<T> = { data: T | null; error: unknown };

interface SupabaseLike {
    rpc: <T>(
        fn: string,
        params: Record<string, unknown>,
    ) => Promise<RPCResult<T>>;
    from: (table: string) => {
        select: (cols: string) => {
            gte: (col: string, val: string) => {
                lt: (col: string, val: string) => Promise<RPCResult<unknown[]>>;
            };
        };
        upsert: (row: Record<string, unknown>) => Promise<RPCResult<unknown>>;
    };
}

export async function handleRequest(req: Request): Promise<Response> {
    if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

    const version = req.headers.get("X-Api-Version");
    if (!version || version !== API_VERSION) {
        return json({ error: "Unsupported or missing X-Api-Version" }, 400);
    }

    // service role required (skip in test)
    const isTest = Deno.env.get("DENO_TESTING") === "true";
    const token = req.headers.get("Authorization")?.replace("Bearer ", "");
    const srKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY");
    if (!isTest && token !== srKey) {
        return json({ error: "Unauthorized" }, 401);
    }

    const url = new URL(req.url);
    const dateParam = url.searchParams.get("date"); // YYYY-MM-DD
    const targetDate = dateParam
        ? new Date(dateParam)
        : new Date(Date.now() - 24 * 60 * 60 * 1000);
    const ymd = targetDate.toISOString().slice(0, 10);

    // Cast because getSupabaseClient returns unknown in stubbed env
    const client = await (getSupabaseClient as unknown as (
        opts: unknown,
    ) => Promise<unknown>)({ overrideKey: srKey }) as SupabaseLike;

    try {
        // Fetch aggregated stats per user for the day
        const { data, error } = await client.rpc<
            Array<
                {
                    user_id: string;
                    response_time_avg: number | null;
                    persona_mix: Record<string, number>;
                }
            >
        >(
            "coach_interaction_daily_aggregate",
            {
                target_date: ymd,
            },
        );
        // If RPC not available, compute manually
        let aggregates: Array<
            {
                user_id: string;
                response_time_avg: number | null;
                persona_mix: Record<string, number>;
            }
        > = [];
        if (error || !data) {
            // Manual SQL: select user_id, avg((metadata->>'latency_ms')::numeric) as response_time_avg, jsonb_object_agg(sender, cnt) as persona_mix
            const { data: rows, error: err2 } = await client.from(
                "coach_interactions",
            )
                .select("user_id, sender, metadata")
                .gte("created_at", `${ymd}T00:00:00Z`).lt(
                    "created_at",
                    `${ymd}T23:59:59Z`,
                );
            if (err2) throw err2;
            const map = new Map<
                string,
                {
                    sumLat: number;
                    countLat: number;
                    persona: Record<string, number>;
                }
            >();
            for (const row of (rows ?? []) as Array<Record<string, unknown>>) {
                const u = String(row.user_id);
                const meta = row.metadata as
                    | Record<string, unknown>
                    | undefined;
                const latency = Number(meta?.latency_ms ?? NaN);
                if (!map.has(u)) {
                    map.set(u, { sumLat: 0, countLat: 0, persona: {} });
                }
                const agg = map.get(u)!;
                if (!isNaN(latency)) {
                    agg.sumLat += latency;
                    agg.countLat += 1;
                }
                const sender = String(row.sender ?? "unknown");
                agg.persona[sender] = (agg.persona[sender] ?? 0) + 1;
            }
            aggregates = [...map.entries()].map(([user_id, v]) => ({
                user_id,
                response_time_avg: v.countLat
                    ? Math.round(v.sumLat / v.countLat)
                    : null,
                persona_mix: v.persona,
            }));
        } else {
            aggregates = data ?? [];
        }

        // Upsert into metrics table
        for (const row of aggregates) {
            await client.from("coach_interaction_metrics").upsert({
                user_id: row.user_id,
                metric_date: ymd,
                response_time_avg: row.response_time_avg,
                persona_mix: row.persona_mix,
            });
        }

        return json({ processed: aggregates.length, date: ymd }, 200);
    } catch (err) {
        console.error("interaction-aggregate error", err);
        return json({ error: "internal" }, 500);
    }
}

// start server when run
if (import.meta.main) {
    serve(handleRequest);
}

function json(payload: unknown, status = 200): Response {
    return new Response(JSON.stringify(payload), {
        status,
        headers: { ...cors, "Content-Type": "application/json" },
    });
}
