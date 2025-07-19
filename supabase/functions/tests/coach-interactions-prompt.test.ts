import { handleRequest } from "../coach-interactions-api/index.ts";

Deno.test("prompt endpoint rejects missing headers", async () => {
  Deno.env.set("DENO_TESTING", "true");
  const res = await handleRequest(
    new Request(
      "http://localhost/v1/coach-interactions-api/prompt",
      {
        method: "POST",
        headers: {
          Authorization: "Bearer dummy",
        },
        body: JSON.stringify({
          user_id: "abc",
          template: "biometric_drop",
          flag_type: "low_steps",
        }),
      },
    ),
  );
  if (res.status !== 400) {
    throw new Error(`Expected 400, got ${res.status}`);
  }
  Deno.env.delete("DENO_TESTING");
});

Deno.test({
  name: "prompt endpoint happy path returns 202",
  sanitizeResources: false,
  sanitizeOps: false,
}, async () => {
  Deno.env.set("DENO_TESTING", "true");
  Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
  Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service_key");

  const res = await handleRequest(
    new Request(
      "http://localhost/v1/coach-interactions-api/prompt",
      {
        method: "POST",
        headers: {
          "X-Api-Version": "1",
          Authorization: "Bearer service_key",
        },
        body: JSON.stringify({
          user_id: "abc",
          template: "biometric_drop",
          flag_type: "low_steps",
        }),
      },
    ),
  );
  if (res.status !== 202) {
    throw new Error(`Expected 202, got ${res.status}`);
  }
  Deno.env.delete("DENO_TESTING");
  Deno.env.delete("SUPABASE_URL");
  Deno.env.delete("SUPABASE_SERVICE_ROLE_KEY");
});
