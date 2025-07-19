import { handleRequest } from "../biometric-flag-detector/index.ts";

Deno.test("GET method not allowed", async () => {
  const res = await handleRequest(
    new Request("http://localhost/flag", { method: "GET" }),
  );
  if (res.status !== 405) {
    throw new Error(`Expected 405, got ${res.status}`);
  }
});

Deno.test("returns 200 in test mode", async () => {
  Deno.env.set("DENO_TESTING", "true");
  const res = await handleRequest(
    new Request("http://localhost/flag?test=true", { method: "POST" }),
  );
  if (res.status !== 200) {
    throw new Error(`Expected 200, got ${res.status}`);
  }
  const body = await res.json();
  if (!body.success) {
    throw new Error("Response success false");
  }
  Deno.env.delete("DENO_TESTING");
});
