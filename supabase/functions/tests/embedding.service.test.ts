import { getEmbedding } from "../ai-coaching-engine/services/embedding.service.ts";

Deno.test("getEmbedding returns 1536-length vector in test mode", async () => {
    Deno.env.set("DENO_TESTING", "true");
    const v = await getEmbedding("hello world");
    if (v.length !== 1536) {
        throw new Error(`Expected 1536 dims, got ${v.length}`);
    }
    Deno.env.delete("DENO_TESTING");
});
