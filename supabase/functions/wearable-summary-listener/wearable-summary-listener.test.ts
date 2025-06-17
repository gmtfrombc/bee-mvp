import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.test("listener forwards wearable summary update to coaching engine", async () => {
    // Arrange fake env
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-key");
    Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
    Deno.env.set("AI_COACHING_ENGINE_URL", "https://coach.example.com");

    // Import handler after env vars so module picks up overrides
    const { default: handler } = await import("./index.ts");

    let capturedRequest: Request | null = null;

    // Stub global fetch for downstream call
    const origFetch = globalThis.fetch;
    globalThis.fetch = async (
        info: Request | URL | string,
        init?: RequestInit,
    ) => {
        const url = typeof info === "string"
            ? info
            : info instanceof URL
            ? info.toString()
            : info.url;
        if (url.startsWith("https://coach.example.com")) {
            capturedRequest = new Request(url, init);
            return new Response(JSON.stringify({ success: true }), {
                status: 200,
            });
        }
        return origFetch(info as any, init);
    };

    const payload = {
        record: {
            user_id: "user123",
            summary_date: "2025-06-17",
            steps_total: 4567,
        },
    };
    const req = new Request("http://localhost", {
        method: "POST",
        body: JSON.stringify(payload),
        headers: { "Content-Type": "application/json" },
    });

    // Act
    const res = await handler(req);

    // Assert
    assertEquals(res.status, 200);
    if (!capturedRequest) throw new Error("Coaching engine was not called");
    const body = await (capturedRequest as Request).json();
    assertEquals(body.user_id, "user123");
    assertEquals(body.system_event, "wearable_summary_update");

    // Cleanup
    globalThis.fetch = origFetch;
});
