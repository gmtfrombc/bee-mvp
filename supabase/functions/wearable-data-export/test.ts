import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";

// Core business logic interfaces for testing
interface WearableHealthData {
    user_id: string;
    data_type: string;
    value: string;
    timestamp: string;
    source: string;
}

interface DayLevelData {
    date: string;
    user_id: string;
    steps_total: number;
    heart_rate_avg: number;
    sleep_duration_hours: number;
    active_energy_kcal: number;
    sample_count: number;
    data_sources: string;
}

// Core business logic functions for testing
function calculateDayMetrics(
    date: string,
    userId: string,
    samples: WearableHealthData[],
): DayLevelData {
    let steps = 0;
    let heartRateSum = 0;
    let heartRateCount = 0;
    let sleepMinutes = 0;
    let activeEnergy = 0;
    const sources = new Set<string>();

    for (const sample of samples) {
        sources.add(sample.source);
        const value = parseFloat(sample.value);
        if (isNaN(value)) continue;

        switch (sample.data_type) {
            case "steps":
                steps += value;
                break;
            case "heartRate":
                heartRateSum += value;
                heartRateCount++;
                break;
            case "sleepDuration":
                sleepMinutes += value;
                break;
            case "activeEnergyBurned":
                activeEnergy += value;
                break;
        }
    }

    return {
        date,
        user_id: userId,
        steps_total: Math.round(steps),
        heart_rate_avg: heartRateCount > 0
            ? Math.round(heartRateSum / heartRateCount)
            : 0,
        sleep_duration_hours: Math.round((sleepMinutes / 60) * 100) / 100,
        active_energy_kcal: Math.round(activeEnergy),
        sample_count: samples.length,
        data_sources: Array.from(sources).join(";"),
    };
}

function validateDateRange(startDate: string, endDate: string): void {
    const daysDiff = Math.ceil(
        (new Date(endDate).getTime() - new Date(startDate).getTime()) /
            (1000 * 60 * 60 * 24),
    );

    if (daysDiff > 90) {
        throw new Error("Date range too large. Maximum 90 days allowed.");
    }
}

function formatAsCSV(data: DayLevelData[]): string {
    const headers = [
        "date",
        "user_id",
        "steps_total",
        "heart_rate_avg_bpm",
        "sleep_duration_hours",
        "active_energy_kcal",
        "sample_count",
        "data_sources",
    ];

    const rows = data.map((row) => [
        row.date,
        row.user_id,
        row.steps_total.toString(),
        row.heart_rate_avg.toString(),
        row.sleep_duration_hours.toString(),
        row.active_energy_kcal.toString(),
        row.sample_count.toString(),
        `"${row.data_sources}"`,
    ]);

    return [headers, ...rows].map((row) => row.join(",")).join("\n");
}

// Test Suite - Essential tests only per testing policy
Deno.test("Happy Path: calculateDayMetrics aggregates health data correctly", () => {
    const mockHealthData: WearableHealthData[] = [
        {
            user_id: "user1",
            data_type: "steps",
            value: "5000",
            timestamp: "2024-01-01T10:00:00Z",
            source: "Garmin",
        },
        {
            user_id: "user1",
            data_type: "heartRate",
            value: "72",
            timestamp: "2024-01-01T10:30:00Z",
            source: "Garmin",
        },
        {
            user_id: "user1",
            data_type: "sleepDuration",
            value: "420", // 7 hours in minutes
            timestamp: "2024-01-01T06:00:00Z",
            source: "Garmin",
        },
    ];

    const result = calculateDayMetrics("2024-01-01", "user1", mockHealthData);

    assertEquals(result.date, "2024-01-01");
    assertEquals(result.user_id, "user1");
    assertEquals(result.steps_total, 5000);
    assertEquals(result.heart_rate_avg, 72);
    assertEquals(result.sleep_duration_hours, 7.0);
    assertEquals(result.sample_count, 3);
    assertEquals(result.data_sources, "Garmin");
});

Deno.test("Critical Edge Case: validateDateRange rejects range over 90 days", () => {
    const startDate = "2024-01-01";
    const endDate = "2024-05-01"; // > 90 days

    let threwError = false;
    let errorMessage = "";

    try {
        validateDateRange(startDate, endDate);
    } catch (error) {
        threwError = true;
        errorMessage = error instanceof Error ? error.message : String(error);
    }

    assertEquals(threwError, true);
    assertEquals(errorMessage.includes("Date range too large"), true);
});

Deno.test("Critical Edge Case: calculateDayMetrics handles invalid values gracefully", () => {
    const invalidData: WearableHealthData[] = [
        {
            user_id: "user1",
            data_type: "steps",
            value: "invalid",
            timestamp: "2024-01-01T10:00:00Z",
            source: "Test",
        },
        {
            user_id: "user1",
            data_type: "heartRate",
            value: "70",
            timestamp: "2024-01-01T10:00:00Z",
            source: "Test",
        },
    ];

    const result = calculateDayMetrics("2024-01-01", "user1", invalidData);

    assertEquals(result.steps_total, 0); // Invalid value ignored
    assertEquals(result.heart_rate_avg, 70); // Valid value processed
    assertEquals(result.sample_count, 2); // All samples counted
});

Deno.test("Core Function: formatAsCSV produces correct CSV format", () => {
    const testData: DayLevelData[] = [{
        date: "2024-01-01",
        user_id: "user1",
        steps_total: 5000,
        heart_rate_avg: 72,
        sleep_duration_hours: 7.0,
        active_energy_kcal: 0,
        sample_count: 3,
        data_sources: "Garmin;Apple",
    }];

    const csv = formatAsCSV(testData);
    const lines = csv.split("\n");

    assertEquals(
        lines[0],
        "date,user_id,steps_total,heart_rate_avg_bpm,sleep_duration_hours,active_energy_kcal,sample_count,data_sources",
    );
    assertEquals(lines[1], '2024-01-01,user1,5000,72,7,0,3,"Garmin;Apple"');
});
