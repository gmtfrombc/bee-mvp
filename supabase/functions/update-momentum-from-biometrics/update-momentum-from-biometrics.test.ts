import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";

import { handleRequest } from "./index.ts";

// -----------------------------------------------------------------------------
// Environment setup for test harness
// -----------------------------------------------------------------------------
Deno.env.set("DENO_TESTING", "true");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-service-key");
Deno.env.set("SUPABASE_URL", "http://localhost:54321");

Deno.test("update-momentum-from-biometrics accepts penalty payload", async () => {
  const req = new Request(
    "http://localhost/functions/v1/update-momentum-from-biometrics",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Api-Version": "1",
      },
      body: JSON.stringify({
        user_id: "user_123",
        penalty: -10,
      }),
    },
  );

  const res = await handleRequest(req);
  assertEquals(res.status, 202);
  const body = await res.json();
  assertEquals(body.status, "accepted");
});
