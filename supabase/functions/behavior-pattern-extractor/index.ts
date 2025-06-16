import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/*
 * Behavior-Pattern Extractor – T1.3.2.1 (minimal viable stub)
 * -----------------------------------------------------------
 * Each run aggregates yesterday's engagement events (table: engagement_events)
 * and upserts a lightweight summary into user_behavior_patterns:
 *   – engagement_count
 *   – unique_event_types
 *   – last_active_at
 * Designed as a stopgap so that the personalization engine has basic features.
 */

serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok");
    if (req.method !== "POST" && req.method !== "GET") {
        return new Response("Method not allowed", { status: 405 });
    }

    const url = new URL(req.url);
    const targetDate = url.searchParams.get("date") ||
        new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split("T")[0];

    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY") || "";
    const client = createClient(supabaseUrl, serviceRole);

    try {
        const { data: events, error } = await client
            .from("engagement_events")
            .select("user_id,event_type,created_at")
            .gte("created_at", `${targetDate}T00:00:00Z`)
            .lte("created_at", `${targetDate}T23:59:59Z`);
        if (error) throw error;

        if (!events?.length) {
            return new Response(
                JSON.stringify({ success: true, message: "no events" }),
                { headers: { "Content-Type": "application/json" } },
            );
        }

        const summaries = new Map<
            string,
            { count: number; types: Set<string>; last: string }
        >();
        for (const e of events) {
            const uid = e.user_id as string;
            if (!summaries.has(uid)) {
                summaries.set(uid, {
                    count: 0,
                    types: new Set(),
                    last: e.created_at,
                });
            }
            const s = summaries.get(uid)!;
            s.count += 1;
            s.types.add(e.event_type);
            if (e.created_at > s.last) s.last = e.created_at;
        }

        const rows = Array.from(summaries.entries()).map(([uid, s]) => ({
            user_id: uid,
            summary_date: targetDate,
            engagement_count: s.count,
            unique_event_types: Array.from(s.types),
            last_active_at: s.last,
        }));

        const { error: upErr } = await client.from("user_behavior_patterns")
            .upsert(rows, { onConflict: "user_id,summary_date" });
        if (upErr) throw upErr;

        return new Response(
            JSON.stringify({ success: true, processed: rows.length }),
            { headers: { "Content-Type": "application/json" } },
        );
    } catch (err) {
        console.error("behavior-pattern extractor error", err);
        return new Response(
            JSON.stringify({
                success: false,
                error: err instanceof Error ? err.message : String(err),
            }),
            { status: 500, headers: { "Content-Type": "application/json" } },
        );
    }
});
