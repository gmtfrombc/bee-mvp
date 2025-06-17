import { handleRequest } from "./index.ts";

Deno.test({
    name: "daily-sleep-score requires params (v1)",
    sanitizeResources: false,
    sanitizeOps: false,
}, async () => {
    // Enable test mode to bypass auth & rate-limit
    Deno.env.set("DENO_TESTING", "true");
    Deno.env.set("SUPABASE_URL", "http://localhost");
    Deno.env.set("SUPABASE_ANON_KEY", "anon-test");

    const req = new Request("http://localhost/v1/daily-sleep-score", {
        method: "GET",
        headers: {
            "X-Api-Version": "1",
        },
    });

    const res = await handleRequest(req);
    if (res.status !== 400) {
        throw new Error(`Expected 400, got ${res.status}`);
    }

    Deno.env.delete("DENO_TESTING");
    Deno.env.delete("SUPABASE_URL");
    Deno.env.delete("SUPABASE_ANON_KEY");
});
