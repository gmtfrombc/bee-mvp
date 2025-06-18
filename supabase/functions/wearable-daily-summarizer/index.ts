import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";

const STEP_GOAL = 10000; // default daily step goal for goal-tracking (can be user-specific later)

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok");
    if (req.method !== "POST" && req.method !== "GET") {
        return new Response("Method not allowed", { status: 405 });
    }

    const url = new URL(req.url);
    const isTest = url.searchParams.get("test") === "true";
    const targetDate = url.searchParams.get("date") ||
        new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split("T")[0];

    const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
        Deno.env.get("SERVICE_ROLE_KEY");

    const client: SupabaseClient = await getSupabaseClient(serviceRole);

    try {
        // fetch distinct users with any data for date
        const { data: users, error: userErr } = await client
            .from("wearable_health_data")
            .select("user_id", { head: false, count: "exact" })
            .gte("timestamp", `${targetDate}T00:00:00Z`)
            .lte("timestamp", `${targetDate}T23:59:59Z`)
            .order("user_id", { ascending: true })
            .limit(isTest ? 5 : 10000);

        if (userErr) throw userErr;
        const uniqueUsers = [
            ...new Set(users?.map((u: { user_id: string }) => u.user_id)),
        ];

        let processed = 0;
        for (const uid of uniqueUsers) {
            const { data, error } = await client
                .from("wearable_health_data")
                .select("data_type,value")
                .eq("user_id", uid)
                .gte("timestamp", `${targetDate}T00:00:00Z`)
                .lte("timestamp", `${targetDate}T23:59:59Z`);

            if (error) {
                console.error("fetch error", uid, error.message);
                continue;
            }

            const totalSleepMinutes = data?.filter((
                r: { data_type: string; value: string | number },
            ) => r.data_type === "sleep_minutes").reduce(
                (a: number, r: { value: string | number }) =>
                    a + Number(r.value || 0),
                0,
            ) || 0;
            const hrs = totalSleepMinutes / 60;
            const sleepScore = Math.min(100, Math.round((hrs / 8) * 100));

            // Average heart rate
            const hrSamples = data?.filter((
                r: { data_type: string; value: string | number },
            ) => r.data_type === "heart_rate").map((
                r: { value: string | number },
            ) => Number(r.value)) || [];
            const avgHr = hrSamples.length
                ? Math.round(
                    hrSamples.reduce((a: number, b: number) => a + b, 0) /
                        hrSamples.length,
                )
                : null;

            // Total steps
            const stepsTotal = data?.filter((
                r: { data_type: string; value: string | number },
            ) => r.data_type === "steps")
                .reduce(
                    (a: number, r: { value: string | number }) =>
                        a + Number(r.value || 0),
                    0,
                ) ||
                0;

            // HRV average (ms) if present
            const hrvSamples = data?.filter((
                r: { data_type: string; value: string | number },
            ) => r.data_type === "hrv")
                .map((r: { value: string | number }) => Number(r.value)) ||
                [];
            const avgHrv = hrvSamples.length
                ? Math.round(
                    hrvSamples.reduce((a: number, b: number) => a + b, 0) /
                        hrvSamples.length,
                )
                : null;

            // ===== Task 4: Activity data processing =====
            // Active energy burned (kcal)
            const activeEnergy = data?.filter((
                r: { data_type: string; value: string | number },
            ) => r.data_type === "active_energy").reduce(
                (a: number, r: { value: string | number }) =>
                    a + Number(r.value || 0),
                0,
            ) || 0;

            // Active minutes – if explicit exercise_time available use it, else estimate via 100 steps ≈ 1 min
            let activeMinutes = data?.filter((
                r: { data_type: string; value: string | number },
            ) => r.data_type === "active_minutes").reduce(
                (a: number, r: { value: string | number }) =>
                    a + Number(r.value || 0),
                0,
            ) || 0;
            if (!activeMinutes && stepsTotal) {
                activeMinutes = Math.round(stepsTotal / 100);
            }

            const goalStepsMet = stepsTotal >= STEP_GOAL;

            // ===== Task 5: HRV stress / recovery classification =====
            let hrvStatus: string | null = null;
            if (avgHrv !== null) {
                if (avgHrv >= 70) {
                    hrvStatus = "excellent";
                } else if (avgHrv >= 50) {
                    hrvStatus = "good";
                } else if (avgHrv >= 30) {
                    hrvStatus = "moderate";
                } else hrvStatus = "poor";
            }

            const { error: upErr } = await client
                .from("wearable_daily_summary")
                .upsert({
                    user_id: uid,
                    summary_date: targetDate,
                    sleep_score: sleepScore,
                    sleep_hours: hrs,
                    avg_hr: avgHr,
                    steps_total: stepsTotal,
                    hrv_avg: avgHrv,
                    active_energy_kcal: activeEnergy,
                    active_minutes: activeMinutes,
                    goal_steps_target: STEP_GOAL,
                    goal_steps_met: goalStepsMet,
                    hrv_status: hrvStatus,
                }, { onConflict: "user_id,summary_date" });

            if (upErr) {
                console.error("upsert error", upErr.message);
            } else processed++;
        }

        return new Response(
            JSON.stringify({ success: true, date: targetDate, processed }),
            { headers: { "Content-Type": "application/json" } },
        );
    } catch (err) {
        console.error("summarizer error", err);
        return new Response(
            JSON.stringify({
                success: false,
                error: err instanceof Error ? err.message : String(err),
            }),
            { status: 500, headers: { "Content-Type": "application/json" } },
        );
    }
});
