import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import {
  CompletionLog,
  computeSuggestions,
  handler,
  PlannedStep,
} from "../suggest-action-steps/index.ts";

Deno.test("computeSuggestions returns 3–5 ranked suggestions", () => {
  const steps: PlannedStep[] = [
    {
      id: "s1",
      category: "sleep",
      frequency: 7,
      week_start: "2025-07-14",
    },
    {
      id: "s2",
      category: "hydration",
      frequency: 7,
      week_start: "2025-07-14",
    },
    {
      id: "s3",
      category: "mobility",
      frequency: 7,
      week_start: "2025-07-14",
    },
    {
      id: "s4",
      category: "mindfulness",
      frequency: 7,
      week_start: "2025-07-14",
    },
  ];

  // No completion logs – all categories under-performing
  const suggestions = computeSuggestions(steps, [] as CompletionLog[]);
  assertEquals(Array.isArray(suggestions), true);
  // Should cap at 5 and have at least 3
  assertEquals(suggestions.length >= 3 && suggestions.length <= 5, true);
  // All required fields present
  const first = suggestions[0]!;
  assertEquals(typeof first.id, "string");
  assertEquals(typeof first.title, "string");
  assertEquals(typeof first.category, "string");
  assertEquals(typeof first.description, "string");
});

Deno.test("handler enforces hourly rate-limit and returns 429 on repeat call", async () => {
  const userId = "00000000-0000-0000-0000-00000000rate";
  const reqInit = {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ user_id: userId }),
  } as const;

  const req1 = new Request("http://localhost/", reqInit);
  const res1 = await handler(req1);
  assertEquals(res1.status, 200);

  // Immediate second request with the same user should hit the in-memory limiter
  const req2 = new Request("http://localhost/", reqInit);
  const res2 = await handler(req2);
  assertEquals(res2.status, 429);

  const body = await res2.json();
  assertEquals(body.code, "RATE_LIMITED");
  // Retry-After header should be present
  assertEquals(res2.headers.has("Retry-After"), true);
});
