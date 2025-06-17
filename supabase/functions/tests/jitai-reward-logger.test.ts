import { recordJITAIOutcome } from "../ai-coaching-engine/services/jitai-effectiveness.ts";

Deno.test("recordJITAIOutcome prints in test env", async () => {
    Deno.env.set("DENO_TESTING", "true");
    await recordJITAIOutcome("user-x", "trig-1", "engaged", "sleep_hygiene");
    Deno.env.delete("DENO_TESTING");
});
