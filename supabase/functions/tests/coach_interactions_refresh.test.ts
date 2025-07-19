import { handleRequest } from "../coach-interactions-api/index.ts";

const API_HEADER = { "X-Api-Version": "1" } as const;

Deno.test("refresh-context requires POST", async () => {
  Deno.env.set("DENO_TESTING", "true");
  const res = await handleRequest(
    new Request("http://localhost/v1/coach-interactions/refresh-context", {
      method: "GET",
      headers: {
        "X-Api-Version": "1",
        Authorization: "Bearer dummy",
      },
    }),
  );
  if (res.status !== 405) {
    throw new Error(`Expected 405, got ${res.status}`);
  }
  Deno.env.delete("DENO_TESTING");
});

Deno.test("refresh-context happy path", async () => {
  Deno.env.set("DENO_TESTING", "true");
  const res = await handleRequest(
    new Request("http://localhost/v1/coach-interactions/refresh-context", {
      method: "POST",
      headers: {
        ...API_HEADER,
        Authorization: "Bearer dummy",
      },
      body: JSON.stringify({ user_id: crypto.randomUUID() }),
    }),
  );
  if (res.status !== 202) {
    throw new Error(`Expected 202, got ${res.status}`);
  }
  Deno.env.delete("DENO_TESTING");
});
