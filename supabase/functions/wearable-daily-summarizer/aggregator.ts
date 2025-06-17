import { assert } from "https://deno.land/std@0.168.0/testing/asserts.ts";

/**
 * Minimal shape of a wearable sample row used by the summarizer.
 */
export interface WearableSample {
    data_type: string;
    /** Numeric value (string or number) */
    value: number | string;
}

export interface DailySummary {
    sleep_hours: number; // hours slept on the day (fraction)
    sleep_score: number; // crude score 0-100 where 8h => 100
    avg_hr: number | null; // average heart-rate (bpm) or null if none
    steps_total: number; // total steps across day
    hrv_avg: number | null; // average HRV (ms) or null if no samples
}

/**
 * Re-implements the core aggregation logic found in the Edge Function so we can
 * unit-test it in isolation without hitting the database.
 *
 * NOTE: Keep this implementation in sync with
 * `supabase/functions/wearable-daily-summarizer/index.ts` (T1.3.9.13).
 */
export function computeDailySummary(
    samples: WearableSample[],
): DailySummary {
    // --- Sleep ---
    const totalSleepMinutes = samples
        .filter((s) => s.data_type === "sleep_minutes")
        .reduce((acc, s) => acc + Number(s.value || 0), 0);
    const sleepHours = totalSleepMinutes / 60;
    const sleepScore = Math.min(100, Math.round((sleepHours / 8) * 100));

    // --- HRV ---
    const hrvSamples = samples
        .filter((s) => s.data_type === "hrv")
        .map((s) => Number(s.value));
    const hrvAvg = hrvSamples.length
        ? Math.round(hrvSamples.reduce((a, b) => a + b, 0) / hrvSamples.length)
        : null;

    // --- Heart-Rate ---
    const hrSamples = samples
        .filter((s) => s.data_type === "heart_rate")
        .map((s) => Number(s.value));
    const avgHr = hrSamples.length
        ? Math.round(hrSamples.reduce((a, b) => a + b, 0) / hrSamples.length)
        : null;

    // --- Steps ---
    const stepsTotal = samples
        .filter((s) => s.data_type === "steps")
        .reduce((acc, s) => acc + Number(s.value || 0), 0);

    return {
        sleep_hours: sleepHours,
        sleep_score: sleepScore,
        avg_hr: avgHr,
        steps_total: stepsTotal,
        hrv_avg: hrvAvg,
    };
}

// ---------------------------------------------------------------------------
// Quick sanity test (acts as safeguard when file is imported outside Deno.test)
// ---------------------------------------------------------------------------
if (import.meta.main) {
    const summary = computeDailySummary([
        { data_type: "steps", value: 3500 },
        { data_type: "hrv", value: 60 },
        { data_type: "hrv", value: 80 },
        { data_type: "sleep_minutes", value: 480 },
        { data_type: "heart_rate", value: 70 },
        { data_type: "heart_rate", value: 90 },
    ]);
    assert(summary.steps_total === 3500);
    assert(summary.hrv_avg === 70);
    console.log("Aggregator self-check passed →", summary);
}
