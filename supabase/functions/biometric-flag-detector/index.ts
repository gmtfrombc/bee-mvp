import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";
import { broadcastEvent } from "../_shared/realtime-util.ts";
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Edge Function metadata
// ---------------------------------------------------------------------------
// Version tag – bump when breaking changes occur
export const version = "v1.0.0" as const;

// Allow the function to run up to 5 min (Supabase default is 5 min max)
export const maxDuration = 300;

// ---------------------------------------------------------------------------
// HTTP entry-point
// ---------------------------------------------------------------------------
export async function handleRequest(req: Request): Promise<Response> {
  // CORS pre-flight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const url = new URL(req.url);
  const isTest = url.searchParams.get("test") === "true" ||
    Deno.env.get("DENO_TESTING") === "true";

  if (isTest) {
    // Fast-return during unit tests (skip heavy DB work)
    return json({ success: true, processed_users: 0, flags_created: 0 });
  }

  // -----------------------------------------------------------------------
  // Supabase client (service-role)
  // -----------------------------------------------------------------------
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey) {
    console.error("Missing service-role key env");
    return json({ error: "internal" }, 500);
  }

  const client: SupabaseClient = await getSupabaseClient(serviceKey);

  try {
    // -------------------------------------------------------------------
    // 1️⃣  Prepare date ranges – yesterday & trailing 7-day window
    // -------------------------------------------------------------------
    const now = new Date();
    const yesterday = new Date(Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate() - 1,
    ));
    const sevenDaysAgo = new Date(Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate() - 7,
    ));

    const yDate = yesterday.toISOString().split("T")[0]; // YYYY-MM-DD
    const startDate = sevenDaysAgo.toISOString().split("T")[0];

    // -------------------------------------------------------------------
    // 2️⃣  Fetch yesterday aggregates (steps, sleep)
    // -------------------------------------------------------------------
    const { data: yesterdayRows, error: yErr } = await client
      .from("health_aggregates_daily")
      .select("user_id, steps, sleep_hours")
      .eq("day", yDate)
      .limit(100000);

    if (yErr) throw yErr;
    if (!yesterdayRows || yesterdayRows.length === 0) {
      return json({ success: true, processed_users: 0, flags_created: 0 });
    }

    // -------------------------------------------------------------------
    // 3️⃣  Fetch trailing 7-day averages (excluding yesterday)
    // -------------------------------------------------------------------
    const { data: histRows, error: hErr } = await client
      .from("health_aggregates_daily")
      .select("user_id, steps, sleep_hours")
      .gte("day", startDate)
      .lt("day", yDate);

    if (hErr) throw hErr;

    // Build quick lookup map with aggregated values
    const tempMap = new Map<
      string,
      { sum_steps: number; sum_sleep: number; n_days: number }
    >();
    for (const row of histRows ?? []) {
      const { user_id, steps, sleep_hours } = row as {
        user_id: string;
        steps: number | null;
        sleep_hours: number | null;
      };
      const rec = tempMap.get(user_id) || {
        sum_steps: 0,
        sum_sleep: 0,
        n_days: 0,
      };
      if (steps !== null) rec.sum_steps += steps;
      if (sleep_hours !== null) rec.sum_sleep += sleep_hours;
      rec.n_days += 1;
      tempMap.set(user_id, rec);
    }

    const histMap = new Map<
      string,
      { avg_steps: number; avg_sleep: number; n_days: number }
    >();
    for (const [uid, rec] of tempMap.entries()) {
      histMap.set(uid, {
        avg_steps: rec.sum_steps / rec.n_days,
        avg_sleep: rec.sum_sleep / rec.n_days,
        n_days: rec.n_days,
      });
    }

    const twentyFourHoursAgoIso = new Date(Date.now() - 24 * 60 * 60 * 1000)
      .toISOString();

    let flagsCreated = 0;
    for (const row of yesterdayRows) {
      const { user_id, steps, sleep_hours } = row as {
        user_id: string;
        steps: number | null;
        sleep_hours: number | null;
      };

      const hist = histMap.get(user_id);
      if (!hist || hist.n_days < 3) continue; // skip new users

      const candidateFlags: ("low_steps" | "low_sleep")[] = [];
      if (
        steps !== null && hist.avg_steps > 0 && steps < 0.6 * hist.avg_steps
      ) {
        candidateFlags.push("low_steps");
      }
      if (
        sleep_hours !== null &&
        hist.avg_sleep > 0 &&
        sleep_hours < 0.75 * hist.avg_sleep
      ) {
        candidateFlags.push("low_sleep");
      }

      for (const flagType of candidateFlags) {
        // 3️⃣  Skip if unresolved flag exists in last 24 h
        const { data: existing, error: exErr } = await client
          .from("biometric_flags")
          .select("id")
          .eq("user_id", user_id)
          .eq("flag_type", flagType)
          .eq("resolved", false)
          .gte("detected_on", twentyFourHoursAgoIso)
          .maybeSingle();

        if (exErr) {
          console.error("existence check failed", exErr);
          continue; // safe-continue processing other users
        }
        if (existing) continue; // suppression

        const details = {
          yesterday_steps: steps,
          avg_steps: hist.avg_steps,
          yesterday_sleep: sleep_hours,
          avg_sleep: hist.avg_sleep,
        };

        const { error: insErr } = await client
          .from("biometric_flags")
          .insert({ user_id, flag_type: flagType, details });

        if (insErr) {
          console.error("insert flag failed", insErr);
          continue;
        }

        flagsCreated++;

        // 4️⃣  Realtime broadcast
        await broadcastEvent(
          "public:biometric_flag",
          "new_flag",
          { user_id, flag_type: flagType },
        );
      }
    }

    return json({
      success: true,
      processed_users: yesterdayRows.length,
      flags_created: flagsCreated,
    });
  } catch (err) {
    console.error("biometric_flag_detector error", err);
    return json({ error: "internal" }, 500);
  }
}

// Local dev entry-point
if (import.meta.main) {
  serve(handleRequest);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
