import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
    createClient,
    SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Nightly job: export JITAI training data for the previous day to Google Cloud Storage.
 * Data sources:
 *   - jitai_training_events
 *   - wearable_daily_summary
 *
 * Environment variables expected:
 *   SUPABASE_URL / SERVICE_ROLE_KEY  – for DB access
 *   GCS_EXPORT_BUCKET                – gs://bucket-name (service account bound via CLI)
 */

interface TrainingRow {
    user_id: string;
    timestamp: string;
    trigger_type: string;
    outcome: string;
    sleep_score?: number;
    avg_hr?: number;
}

serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok");
    const url = new URL(req.url);
    const date = url.searchParams.get("date") ||
        new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split("T")[0];
    const supabase = getSupabase();

    try {
        const rows = await fetchRows(supabase, date);
        const exported = await writeToGCS(rows, date);
        return json({ success: true, exported, date });
    } catch (err) {
        console.error("export job failure", err);
        return json({
            success: false,
            error: err instanceof Error ? err.message : String(err),
        }, 500);
    }
});

function getSupabase(): SupabaseClient {
    const url = Deno.env.get("SUPABASE_URL") || "";
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY") || "";
    return createClient(url, key);
}

async function fetchRows(
    client: SupabaseClient,
    date: string,
): Promise<TrainingRow[]> {
    const start = `${date}T00:00:00Z`;
    const end = `${date}T23:59:59Z`;

    const { data: events, error } = await client
        .from("jitai_training_events")
        .select("user_id, created_at, triggers")
        .gte("created_at", start)
        .lte("created_at", end);
    if (error) throw error;
    if (!events) return [];

    const { data: summaries, error: sumErr } = await client
        .from("wearable_daily_summary")
        .select("user_id, summary_date, sleep_score, avg_hr")
        .eq("summary_date", date);
    if (sumErr) throw sumErr;

    const summaryMap = new Map<
        string,
        { sleep_score?: number; avg_hr?: number }
    >();
    for (const s of summaries ?? []) {
        summaryMap.set(s.user_id, {
            sleep_score: s.sleep_score,
            avg_hr: s.avg_hr,
        });
    }

    const rows: TrainingRow[] = [];
    for (const ev of events) {
        for (
            const trig of ev.triggers as {
                type: string;
                id: string;
                outcome?: string;
            }[]
        ) {
            rows.push({
                user_id: ev.user_id,
                timestamp: ev.created_at,
                trigger_type: trig.type,
                outcome: trig.outcome ?? "delivered",
                ...summaryMap.get(ev.user_id),
            });
        }
    }
    return rows;
}

async function writeToGCS(rows: TrainingRow[], date: string): Promise<number> {
    const bucket = Deno.env.get("GCS_EXPORT_BUCKET");
    if (!bucket) {
        console.warn("GCS_EXPORT_BUCKET not set – skipping upload");
        console.log(JSON.stringify(rows.slice(0, 3), null, 2));
        return rows.length;
    }
    const content = rows.map((r) => JSON.stringify(r)).join("\n");
    const objName = `jitai_training/${date}.ndjson`;

    const script = `echo '${
        content.replaceAll("'", "'\\''")
    }' | gsutil cp - ${bucket}/${objName}`;
    const cmd = new Deno.Command("bash", { args: ["-c", script] });
    const { code } = await cmd.output();
    if (code !== 0) throw new Error("gsutil upload failed");
    return rows.length;
}

function json(payload: unknown, status = 200): Response {
    return new Response(JSON.stringify(payload), {
        status,
        headers: { "Content-Type": "application/json" },
    });
}
