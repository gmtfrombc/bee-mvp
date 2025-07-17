import { handleRequest } from "../update-momentum-from-action-step/index.ts";

const API_VERSION_HEADER = { "X-Api-Version": "1" } as const;

Deno.test("rejects when X-Api-Version header missing", async () => {
  Deno.env.set("DENO_TESTING", "true");
  const res = await handleRequest(
    new Request("http://localhost/update", { method: "POST" }),
  );
  if (res.status !== 400) {
    throw new Error(`Expected 400, got ${res.status}`);
  }
  Deno.env.delete("DENO_TESTING");
});

Deno.test("returns 400 on invalid payload", async () => {
  Deno.env.set("DENO_TESTING", "true");
  const res = await handleRequest(
    new Request("http://localhost/update", {
      method: "POST",
      headers: API_VERSION_HEADER,
      body: JSON.stringify({ foo: "bar" }),
    }),
  );
  if (res.status !== 400) {
    throw new Error(`Expected 400, got ${res.status}`);
  }
  Deno.env.delete("DENO_TESTING");
});

Deno.test("happy-path returns 202", async () => {
  Deno.env.set("DENO_TESTING", "true");
  const payload = {
    user_id: crypto.randomUUID(),
    action_step_id: crypto.randomUUID(),
    day: "2025-07-17",
    status: "completed" as const,
    correlation_id: crypto.randomUUID(),
  };
  const res1 = await handleRequest(
    new Request("http://localhost/update", {
      method: "POST",
      headers: API_VERSION_HEADER,
      body: JSON.stringify(payload),
    }),
  );
  if (res1.status !== 202) {
    throw new Error(`Expected 202, got ${res1.status}`);
  }

  // Idempotent second call
  const res2 = await handleRequest(
    new Request("http://localhost/update", {
      method: "POST",
      headers: API_VERSION_HEADER,
      body: JSON.stringify(payload),
    }),
  );
  if (res2.status !== 202) {
    throw new Error(`Expected 202 on duplicate, got ${res2.status}`);
  }
  Deno.env.delete("DENO_TESTING");
});
