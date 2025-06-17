import { processConversation } from "../ai-coaching-engine/services/conversation.service.ts";

Deno.test("average latency below 400ms", async () => {
    Deno.env.set("DENO_TESTING", "true");
    Deno.env.set("OFFLINE_AI", "true");

    const reqBody = {
        user_id: "00000000-0000-0000-0000-000000000001",
        message: "Hi coach, I feel tired today",
        system_event: "momentum_change",
        momentum_state: "Steady",
        previous_state: "Rising",
        current_score: 75,
    };
    const request = new Request("http://localhost/conversation", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            Authorization: "Bearer test",
            "X-System-Event": "true",
        },
        body: JSON.stringify(reqBody),
    });

    const runs = 30;
    let totalMs = 0;
    for (let i = 0; i < runs; i++) {
        const t0 = Date.now();
        const response = await processConversation(request.clone(), {
            cors: {},
            isTestingEnv: true,
        });
        if (!response.ok) {
            throw new Error(`unexpected status ${response.status}`);
        }
        totalMs += Date.now() - t0;
    }
    const avg = totalMs / runs;
    if (avg >= 400) {
        throw new Error(`Average latency ${avg}ms exceeds threshold`);
    }
});
