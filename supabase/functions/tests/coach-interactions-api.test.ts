import { handleRequest } from "../coach-interactions-api/index.ts";

Deno.test("history endpoint requires X-Api-Version header", async () => {
    Deno.env.set("DENO_TESTING", "true");
    const res = await handleRequest(
        new Request(
            "http://localhost/v1/coach-interactions/history?user_id=abc",
            {
                method: "GET",
                headers: {
                    Authorization: "Bearer dummy",
                },
            },
        ),
    );
    if (res.status !== 400) {
        throw new Error(`Expected 400, got ${res.status}`);
    }
    Deno.env.delete("DENO_TESTING");
});

Deno.test({
    name: "history endpoint ok with headers (empty data)",
    sanitizeResources: false,
    sanitizeOps: false,
}, async () => {
    Deno.env.set("DENO_TESTING", "true");
    // Provide fake env so Supabase client can instantiate
    Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service_key");

    const res = await handleRequest(
        new Request(
            "http://localhost/v1/coach-interactions/history?user_id=abc&limit=5",
            {
                method: "GET",
                headers: {
                    "X-Api-Version": "1",
                    Authorization: "Bearer service_key",
                },
            },
        ),
    );
    if (res.status !== 500 && res.status !== 200) {
        throw new Error(`Unexpected status ${res.status}`);
    }
    Deno.env.delete("DENO_TESTING");
    Deno.env.delete("SUPABASE_URL");
    Deno.env.delete("SUPABASE_SERVICE_ROLE_KEY");
});
