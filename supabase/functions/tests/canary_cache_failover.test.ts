import { processConversation as _processConversation } from "../ai-coaching-engine/services/conversation.service.ts";

Deno.test("cache canary – first MISS then HIT", async () => {
    const perm = await Deno.permissions.query({ name: "env" as const });
    if (perm.state !== "granted") {
        console.warn("⏩ Skipping cache canary: --allow-env not granted");
        return;
    }

    const { processConversation } = await import(
        "../ai-coaching-engine/services/conversation.service.ts"
    );

    Deno.env.set("DENO_TESTING", "true");
    Deno.env.set("OFFLINE_AI", "true");
    Deno.env.set("CACHE_ENABLED", "true");

    const body = {
        user_id: "00000000-0000-0000-0000-000000000001",
        message: "Quick ping for cache canary",
    };

    const makeReq = () =>
        new Request("http://localhost/conversation", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Authorization: "Bearer test",
            },
            body: JSON.stringify(body),
        });

    const res1 = await processConversation(makeReq(), {
        cors: {},
        isTestingEnv: true,
    });
    if (!res1.ok) throw new Error("conversation failed");
    const status1 = res1.headers.get("X-Cache-Status");
    if (status1 !== "MISS") throw new Error(`expected MISS got ${status1}`);

    const res2 = await processConversation(makeReq(), {
        cors: {},
        isTestingEnv: true,
    });
    const status2 = res2.headers.get("X-Cache-Status");
    if (status2 !== "HIT") throw new Error(`expected HIT got ${status2}`);
});
