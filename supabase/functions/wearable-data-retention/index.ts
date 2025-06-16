import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/*
 * Wearable Data Retention Cleaner – T2.2.3.9
 * ------------------------------------------
 * Deletes raw records from `wearable_health_data` that are older than the
 * configured retention window (default 730 days). Retention window can be
 * overridden via the `days` query param.
 *
 * IMPORTANT: This function must be scheduled via Supabase "edge schedule" and
 * should use the Service Role key. It is idempotent – repeated runs will have
 * no additional effect once old rows are gone.
 */

const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
    if (req.method !== "POST" && req.method !== "GET") {
        return new Response("Method not allowed", {
            status: 405,
            headers: cors,
        });
    }

    const url = new URL(req.url);
    const retentionDays = Number(url.searchParams.get("days")) || 730; // default 2 years
    const dryRun = url.searchParams.get("dry_run") === "true";

    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY") || "";
    const client = createClient(supabaseUrl, serviceRole);

    try {
        const cutoffDate = new Date(
            Date.now() - retentionDays * 24 * 60 * 60 * 1000,
        )
            .toISOString();

        // Count rows older than cutoff
        const { count, error: countErr } = await client
            .from("wearable_health_data")
            .select("id", { head: true, count: "exact" })
            .lt("timestamp", cutoffDate);

        if (countErr) throw countErr;

        let deletedRows = 0;
        if (!dryRun && count && count > 0) {
            const { error: delErr } = await client
                .from("wearable_health_data")
                .delete()
                .lt("timestamp", cutoffDate);
            if (delErr) throw delErr;
            deletedRows = count;
        }

        return new Response(
            JSON.stringify({
                success: true,
                dryRun,
                retentionDays,
                cutoffDate,
                rowsAffected: dryRun ? count : deletedRows,
            }),
            {
                status: 200,
                headers: { ...cors, "Content-Type": "application/json" },
            },
        );
    } catch (err) {
        console.error("Retention cleaner error", err);
        return new Response(
            JSON.stringify({
                success: false,
                error: err instanceof Error ? err.message : String(err),
            }),
            {
                status: 500,
                headers: { ...cors, "Content-Type": "application/json" },
            },
        );
    }
});
