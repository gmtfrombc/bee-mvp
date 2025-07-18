import { handleRequest } from "../update-momentum-score/index.ts";

const API_VERSION_HEADER = { "X-Api-Version": "1" } as const;

Deno.test("rejects when X-Api-Version header missing", async () => {
  // Enable test mode so DB access is skipped
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
    delta: 10,
    source: "pes_entry" as const,
  };
  const res = await handleRequest(
    new Request("http://localhost/update", {
      method: "POST",
      headers: API_VERSION_HEADER,
      body: JSON.stringify(payload),
    }),
  );
  if (res.status !== 202) {
    throw new Error(`Expected 202, got ${res.status}`);
  }
  Deno.env.delete("DENO_TESTING");
});
