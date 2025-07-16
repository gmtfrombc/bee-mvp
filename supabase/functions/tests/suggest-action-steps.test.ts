import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { handler } from "../suggest-action-steps/index.ts";

Deno.test("suggest-action-steps returns 3 placeholder suggestions", async () => {
  const req = new Request("http://localhost/", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ user_id: "00000000-0000-0000-0000-000000000001" }),
  });

  const res = await handler(req);
  assertEquals(res.status, 200);

  const body = await res.json();
  assertEquals(Array.isArray(body.suggestions), true);
  assertEquals(body.suggestions.length, 3);
});
