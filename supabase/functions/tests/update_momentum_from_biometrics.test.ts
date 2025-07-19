import { handleRequest } from "../update-momentum-from-biometrics/index.ts";

const API_HEADER = { "X-Api-Version": "1" } as const;

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
      headers: API_HEADER,
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
    delta: 15,
    source: "manual_biometrics" as const,
  };
  const res = await handleRequest(
    new Request("http://localhost/update", {
      method: "POST",
      headers: API_HEADER,
      body: JSON.stringify(payload),
    }),
  );
  if (res.status !== 202) {
    throw new Error(`Expected 202, got ${res.status}`);
  }
  Deno.env.delete("DENO_TESTING");
});
