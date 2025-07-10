import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { z } from "https://deno.land/x/zod@v3.22.2/mod.ts";
import handler from "./index.ts";

// Ensure tests run in offline mode
Deno.env.set("SKIP_SUPABASE", "true");

// -----------------------------------------------------------------------------
// JSON contract schema – mirrors docs/MVP_ROADMAP/1-11 onboarding scoring specs
// -----------------------------------------------------------------------------
const RequestSchema = z.object({
  user_id: z.string(),
  motivation_type: z.string(),
  readiness_level: z.enum(["Low", "Moderate", "High"]),
  coach_style: z.string(),
});

type RequestPayload = z.infer<typeof RequestSchema>;

function buildRequest(body: RequestPayload | Record<string, unknown>): Request {
  return new Request("http://localhost/sync-ai-tags", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

// ----------------------------- Test Cases -----------------------------------
Deno.test("contract schema: valid payload passes schema & handler returns 200", async () => {
  const payload: RequestPayload = {
    user_id: "contract-user-1",
    motivation_type: "Internal",
    readiness_level: "High",
    coach_style: "RH",
  };

  // Schema validation (throws on failure)
  RequestSchema.parse(payload);

  const res = await handler(buildRequest(payload));
  assertEquals(res.status, 200);
  const json = await res.json();
  assertEquals(json.status, "success");
});

Deno.test("contract schema: invalid payload fails schema & handler returns 400", async () => {
  const badPayload = {
    user_id: "bad-user-1",
    motivation_type: "Internal",
    readiness_level: "Invalid", // invalid enum value
    // coach_style missing
  };

  let schemaRejected = false;
  try {
    RequestSchema.parse(badPayload);
  } catch (_err) {
    schemaRejected = true;
  }
  assertEquals(schemaRejected, true);

  const res = await handler(buildRequest(badPayload));
  assertEquals(res.status, 400);
});
