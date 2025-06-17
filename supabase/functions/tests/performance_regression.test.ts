// Performance regression: ensure 95th-percentile latency stays < 1 s.
Deno.test("p95 latency below 1000ms", async () => {
    const envPerm = await Deno.permissions.query({ name: "env" as const });
    if (envPerm.state !== "granted") {
        console.warn("⏩ Skipping p95 latency test: --allow-env not granted");
        return;
    }

    // Dynamically import after permission check to avoid env requirement at module load
    const { processConversation } = await import(
        "../ai-coaching-engine/services/conversation.service.ts"
    );

    Deno.env.set("DENO_TESTING", "true");
    Deno.env.set("OFFLINE_AI", "true");
    Deno.env.set("RATE_LIMIT_MAX", "1000");

    const reqBody = {
        user_id: "00000000-0000-0000-0000-000000000001",
        message: "Hello coach, quick check-in!",
    };
    const baseRequest = new Request("http://localhost/conversation", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            Authorization: "Bearer test",
        },
        body: JSON.stringify(reqBody),
    });

    const runs = 40;
    const durations: number[] = [];

    for (let i = 0; i < runs; i++) {
        const t0 = Date.now();
        const res = await processConversation(baseRequest.clone(), {
            cors: {},
            isTestingEnv: true,
        });
        if (!res.ok) throw new Error(`unexpected status ${res.status}`);
        durations.push(Date.now() - t0);
    }

    durations.sort((a, b) => a - b);
    const p95 = durations[Math.floor(runs * 0.95) - 1];
    if (p95 >= 1000) {
        throw new Error(`p95 latency ${p95}ms exceeds 1000ms`);
    }
});
