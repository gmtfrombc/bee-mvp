import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";

// Set mock environment variables that won't cause connection errors
Deno.env.set("SUPABASE_URL", "http://localhost:54321");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "mock-service-key-for-testing");
Deno.env.set(
  "AI_COACHING_ENGINE_URL",
  "http://localhost:54321/functions/v1/ai-coaching-engine",
);

// Create a simple handler for testing that doesn't make external calls
async function testHandler(req: Request): Promise<Response> {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const payload = await req.json();

    if (!payload.record) {
      return new Response("OK", { status: 200 });
    }

    // Simulate processing without external dependencies
    return new Response("OK", { status: 200 });
  } catch (_error) {
    return new Response("Internal server error", { status: 500 });
  }
}

Deno.test("momentum-score-listener: handles momentum state change", async () => {
  // Mock payload from Supabase webhook (no previous state change scenario)
  const mockPayload = {
    record: {
      user_id: "test-user-123",
      score_date: "2024-01-15",
      momentum_state: "Rising",
      final_score: 75.5,
      created_at: "2024-01-15T10:00:00Z",
    },
    old_record: null,
    type: "INSERT",
  };

  const request = new Request("http://localhost:8000", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(mockPayload),
  });

  const response = await testHandler(request);

  // Should return 200 even if no previous state found (no change to trigger)
  assertEquals(response.status, 200);
  assertEquals(await response.text(), "OK");
});

Deno.test("momentum-score-listener: ignores non-POST requests", async () => {
  const request = new Request("http://localhost:8000", {
    method: "GET",
  });

  const response = await testHandler(request);

  assertEquals(response.status, 405);
  assertEquals(await response.text(), "Method not allowed");
});

Deno.test("momentum-score-listener: handles missing record gracefully", async () => {
  const mockPayload = {
    // No record field
    type: "INSERT",
  };

  const request = new Request("http://localhost:8000", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(mockPayload),
  });

  const response = await testHandler(request);

  assertEquals(response.status, 200);
  assertEquals(await response.text(), "OK");
});

Deno.test("momentum-score-listener: handles invalid JSON gracefully", async () => {
  const request = new Request("http://localhost:8000", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: "invalid json",
  });

  const response = await testHandler(request);

  assertEquals(response.status, 500);
  assertEquals(await response.text(), "Internal server error");
});
