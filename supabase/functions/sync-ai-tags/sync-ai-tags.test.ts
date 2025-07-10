import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";

// Set offline test mode
Deno.env.set("SKIP_SUPABASE", "true");

// Import the handler under test (relative path)
import handler from "./index.ts";

function buildRequest(body: unknown, method = "POST"): Request {
  return new Request("http://localhost:8000", {
    method,
    headers: { "Content-Type": "application/json" },
    body: method === "POST" ? JSON.stringify(body) : undefined,
  });
}

Deno.test("sync-ai-tags: happy path returns 200", async () => {
  const payload = {
    user_id: "user-123",
    motivation_type: "Internal",
    readiness_level: "High",
    coach_style: "RH",
  };

  const res = await handler(buildRequest(payload));
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.status, "success");
});

Deno.test("sync-ai-tags: duplicate payload returns 409", async () => {
  const payload = {
    user_id: "dup-user",
    motivation_type: "Internal",
    readiness_level: "High",
    coach_style: "LH",
  };

  // First call → 200
  const firstRes = await handler(buildRequest(payload));
  assertEquals(firstRes.status, 200);

  // Second identical call → 409
  const secondRes = await handler(buildRequest(payload));
  assertEquals(secondRes.status, 409);
  const body = await secondRes.json();
  assertEquals(body.status, "duplicate_ignored");
});

Deno.test("sync-ai-tags: missing field returns 400", async () => {
  const payload = {
    user_id: "user-missing",
    motivation_type: "Internal",
    readiness_level: "High",
    // coach_style missing
  };

  const res = await handler(buildRequest(payload));
  assertEquals(res.status, 400);
  const body = await res.json();
  assertEquals(body.error.includes("coach_style"), true);
});

Deno.test("sync-ai-tags: non-POST request returns 405", async () => {
  const res = await handler(buildRequest({}, "GET"));
  assertEquals(res.status, 405);
  const text = await res.text();
  assertEquals(text, "Method not allowed");
});
