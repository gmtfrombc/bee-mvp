import { handleRequest } from "./index.ts";

Deno.test({
    name: "unauthenticated request returns 401",
    sanitizeResources: false,
    sanitizeOps: false,
}, async () => {
    const res = await handleRequest(
        new Request("http://localhost/v1/history", {
            method: "GET",
            headers: { "X-Api-Version": "1" },
        }),
    );
    if (res.status !== 401) throw new Error(`expected 401, got ${res.status}`);
});

Deno.test({
    name: "service key request allowed",
    sanitizeResources: false,
    sanitizeOps: false,
}, async () => {
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "sk-test");
    Deno.env.set("SUPABASE_URL", "http://localhost");
    Deno.env.set("SUPABASE_ANON_KEY", "anon-test");
    const res = await handleRequest(
        new Request("http://localhost/v1/history", {
            method: "GET",
            headers: {
                "Authorization": "Bearer sk-test",
                "X-Api-Version": "1",
            },
        }),
    );
    if (res.status === 401) throw new Error("service key rejected");
    Deno.env.delete("SUPABASE_URL");
    Deno.env.delete("SUPABASE_ANON_KEY");
});
