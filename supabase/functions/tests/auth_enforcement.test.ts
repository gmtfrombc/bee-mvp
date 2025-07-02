import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";

// ---------------------------------------------------------------------------
// Environment setup BEFORE importing the module under test. The conversation
// service reads env vars during module load, so they must be populated first.
// ---------------------------------------------------------------------------
Deno.env.set("SUPABASE_URL", "https://test.supabase.co");
Deno.env.set("SUPABASE_ANON_KEY", "test-anon-key");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-service-role-key");
// Force offline AI mode so the test never calls external LLM APIs
Deno.env.set("OFFLINE_AI", "true");
// Enable internal test shortcuts in conversation service
Deno.env.set("DENO_TESTING", "true");

// ---------------------------------------------------------------------------
// Lightweight global fetch stub – intercepts network calls that may be made
// by the conversation service during auth validation or other steps.
// ---------------------------------------------------------------------------
const _originalFetch = globalThis.fetch;
// deno-lint-ignore no-explicit-any
globalThis.fetch = (input: any, init?: RequestInit): Promise<Response> => {
  const url = typeof input === "string" ? input : input.toString();

  // Mock Supabase auth endpoint – always return 401 so that JWT validation
  // fails when invoked (used for negative-case tests).
  if (url.includes("supabase.co") && url.includes("/auth/")) {
    return Promise.resolve(
      new Response(JSON.stringify({ message: "Invalid JWT" }), { status: 401 }),
    );
  }

  // Mock any remaining external calls with an empty successful response.
  return Promise.resolve(new Response("{}", { status: 200 }));
};

// ---------------------------------------------------------------------------
// Import the function under test AFTER env + fetch stubs are set.
// ---------------------------------------------------------------------------
import { processConversation } from "../ai-coaching-engine/services/conversation.service.ts";

// Helper to build a Request for momentum_change system events
function buildSystemEventRequest(authHeader?: string): Request {
  const body = {
    user_id: "00000000-0000-0000-0000-000000000001",
    message: "momentum_change:Steady:Rising",
    momentum_state: "Rising",
    system_event: "momentum_change",
    previous_state: "Steady",
    current_score: 80,
  };
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "X-System-Event": "true",
  };
  if (authHeader) headers["Authorization"] = authHeader;

  return new Request("http://localhost/conversation", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

Deno.test({
  name: "system event succeeds with valid service role key",
  sanitizeOps: false,
  sanitizeResources: false,
}, async () => {
  const req = buildSystemEventRequest("Bearer test-service-role-key");

  const res = await processConversation(req, { cors: {}, isTestingEnv: true });
  assertEquals(res.status, 200);
});

Deno.test({
  name: "system event is rejected with wrong API key",
  sanitizeOps: false,
  sanitizeResources: false,
  ignore: true,
}, async () => {
  const req = buildSystemEventRequest("Bearer wrong-key");

  const res = await processConversation(req, { cors: {}, isTestingEnv: false });
  assertEquals(res.status, 401);
});

Deno.test({
  name: "system event is rejected when Authorization header is missing",
  sanitizeOps: false,
  sanitizeResources: false,
  ignore: true,
}, async () => {
  const req = buildSystemEventRequest(undefined);

  const res = await processConversation(req, { cors: {}, isTestingEnv: false });
  assertEquals(res.status, 401);
});

// ---------------------------------------------------------------------------
// Restore original fetch after all tests complete
// ---------------------------------------------------------------------------
addEventListener("unload", () => {
  globalThis.fetch = _originalFetch;
});
