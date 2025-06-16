import { handleRequest } from "./index.ts";

Deno.bench("summary API sleep score 100 req", async () => {
    const reqInit = { method: "GET" };
    for (let i = 0; i < 100; i++) {
        const req = new Request(
            `http://localhost/daily-sleep-score?user_id=test&date=2025-01-01`,
            reqInit,
        );
        await handleRequest(req);
    }
});
