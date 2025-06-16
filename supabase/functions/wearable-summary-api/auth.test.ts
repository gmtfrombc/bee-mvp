import { handleRequest } from "./index.ts";

Deno.test("unauthenticated request returns 401", async () => {
    const res = await handleRequest(
        new Request("http://localhost/history", { method: "GET" }),
    );
    if (res.status !== 401) throw new Error(`expected 401, got ${res.status}`);
});

Deno.test("service key request allowed", async () => {
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "sk-test");
    const res = await handleRequest(
        new Request("http://localhost/history", {
            method: "GET",
            headers: { "Authorization": "Bearer sk-test" },
        }),
    );
    if (res.status === 401) throw new Error("service key rejected");
});
