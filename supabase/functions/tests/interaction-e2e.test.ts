import { conversationController } from "../ai-coaching-engine/routes/conversation.controller.ts";

Deno.test({
    name: "E2E: chat request logs coach interaction",
    sanitizeResources: false,
    sanitizeOps: false,
    ignore: true,
}, async () => {
    Deno.env.set("DENO_TESTING", "true");

    const req = new Request("http://localhost/converse", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Api-Version": "1" },
        body: JSON.stringify({
            user_id: "00000000-0000-0000-0000-000000000001",
            message: "Hello",
        }),
    });

    const res = await conversationController(req, {
        cors: { "Access-Control-Allow-Origin": "*" },
        isTestingEnv: true,
    });

    if (!res.ok) throw new Error("controller returned non-200");
    if (!res.headers.get("X-Request-Id")) {
        throw new Error("missing request id header");
    }

    Deno.env.delete("DENO_TESTING");
});
