import { handleRequest } from "../wearable-summary-api/index.ts";

Deno.test("should reject when X-Api-Version header missing", async () => {
    Deno.env.set("DENO_TESTING", "true");
    const res = await handleRequest(
        new Request("http://localhost/v1/ping", { method: "GET" }),
    );
    if (res.status !== 400) {
        throw new Error(`Expected 400, got ${res.status}`);
    }
    Deno.env.delete("DENO_TESTING");
});

Deno.test({
    name: "/v1/ping returns 200 with version header",
    sanitizeResources: false,
    sanitizeOps: false,
}, async () => {
    Deno.env.set("DENO_TESTING", "true");
    const res = await handleRequest(
        new Request("http://localhost/v1/ping", {
            method: "GET",
            headers: { "X-Api-Version": "1" },
        }),
    );
    if (res.status !== 200) {
        throw new Error(`Expected 200, got ${res.status}`);
    }
    const body = await res.json();
    if (body.version !== "1") {
        throw new Error("Incorrect version field in response");
    }
    Deno.env.delete("DENO_TESTING");
});

Deno.test("returns 401 when Authorization missing in production mode", async () => {
    // Ensure test mode disabled
    Deno.env.set("DENO_TESTING", "false");
    const res = await handleRequest(
        new Request(
            "http://localhost/v1/daily-sleep-score?user_id=abc&date=2024-01-01",
            {
                method: "GET",
                headers: { "X-Api-Version": "1" },
            },
        ),
    );
    if (res.status !== 401) {
        throw new Error(`Expected 401, got ${res.status}`);
    }
    Deno.env.delete("DENO_TESTING");
});
