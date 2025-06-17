import { computeDailySummary } from "../wearable-daily-summarizer/aggregator.ts";

Deno.test("aggregator computes steps_total & hrv_avg correctly", () => {
    const samples = [
        { data_type: "steps", value: 1000 },
        { data_type: "steps", value: 2500 },
        { data_type: "hrv", value: 60 },
        { data_type: "hrv", value: 80 },
        { data_type: "sleep_minutes", value: 480 }, // 8h sleep
        { data_type: "heart_rate", value: 70 },
        { data_type: "heart_rate", value: 90 },
    ];

    const summary = computeDailySummary(samples);

    if (summary.steps_total !== 3500) {
        throw new Error(
            `Expected steps_total 3500, got ${summary.steps_total}`,
        );
    }
    if (summary.hrv_avg !== 70) {
        throw new Error(`Expected hrv_avg 70, got ${summary.hrv_avg}`);
    }
    if (summary.sleep_hours !== 8) {
        throw new Error(`Expected sleep_hours 8, got ${summary.sleep_hours}`);
    }
    if (summary.sleep_score !== 100) {
        throw new Error(`Expected sleep_score 100, got ${summary.sleep_score}`);
    }
});
