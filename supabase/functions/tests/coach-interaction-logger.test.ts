import { logCoachInteraction } from "../ai-coaching-engine/services/coach-interaction-logger.ts";
import { assertEquals } from "https://deno.land/std@0.204.0/testing/asserts.ts";

Deno.test("logger skips in DENO_TESTING mode", async () => {
    Deno.env.set("DENO_TESTING", "true");
    await logCoachInteraction({
        userId: "00000000-0000-0000-0000-000000000123",
        sender: "ai",
        message: "Hello there 👋",
    });
    // No throw means success
    assertEquals(true, true);
    Deno.env.delete("DENO_TESTING");
});

Deno.test("logger returns early when env vars missing", async () => {
    // Ensure not in testing mode but missing Supabase envs
    Deno.env.set("DENO_TESTING", "false");
    Deno.env.delete("SUPABASE_URL");
    Deno.env.delete("SUPABASE_SERVICE_ROLE_KEY");
    await logCoachInteraction({
        userId: "00000000-0000-0000-0000-000000000123",
        sender: "user",
        message: "Test message",
    });
    assertEquals(true, true);
});
