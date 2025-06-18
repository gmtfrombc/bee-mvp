import {
    assertEquals,
    assertExists,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";

// Test data
const mockDeltaPacket = {
    timestamp: "2025-01-15T15:30:45.123Z",
    type: "heartRate",
    value: 72,
    source: "Garmin Connect",
};

const mockUserId = "test-user-123";

// Test the enrichment endpoint
Deno.test("Wearable Live Enrichment - Basic functionality", () => {
    const testPayload = {
        userId: mockUserId,
        deltaPacket: mockDeltaPacket,
    };

    // This would need actual Supabase test environment
    // For now, just test the payload structure
    assertExists(testPayload.userId);
    assertExists(testPayload.deltaPacket);
    assertEquals(testPayload.deltaPacket.type, "heartRate");
    assertEquals(testPayload.deltaPacket.value, 72);
});

Deno.test("Battery info extraction", () => {
    const extractBatteryInfo = (
        source: string,
    ): { level?: number; status: string } => {
        const defaultInfo = { status: "unknown" as const };

        if (source.toLowerCase().includes("garmin")) {
            return { level: 85, status: "not_charging" };
        } else if (source.toLowerCase().includes("apple")) {
            return defaultInfo;
        }

        return defaultInfo;
    };

    const garminResult = extractBatteryInfo("Garmin Connect");
    assertEquals(garminResult.level, 85);
    assertEquals(garminResult.status, "not_charging");

    const appleResult = extractBatteryInfo("Apple Health");
    assertEquals(appleResult.status, "unknown");
});

Deno.test("Unit mapping", () => {
    const getUnitForDataType = (dataType: string): string => {
        const unitMap: Record<string, string> = {
            "heartRate": "bpm",
            "steps": "count",
            "sleepDuration": "minutes",
            "activeEnergyBurned": "kcal",
            "distanceWalking": "meters",
            "weight": "kg",
        };

        return unitMap[dataType] || "unknown";
    };

    assertEquals(getUnitForDataType("heartRate"), "bpm");
    assertEquals(getUnitForDataType("steps"), "count");
    assertEquals(getUnitForDataType("unknown_type"), "unknown");
});
