import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PROJECT_ID = "okptsizouuanwnpqjfui"; // replace if project id changes
const FUNCTION_URL =
  `https://${PROJECT_ID}.functions.supabase.co/ai-coaching-engine`;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const SUPABASE_URL = `https://${PROJECT_ID}.supabase.co`;

// Auto-run when the service role key is available; otherwise skip
const shouldRun = !!Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

Deno.test({
  name: "Remote integration: conversation logs coach_interactions row",
  ignore: !shouldRun,
  sanitizeResources: false,
  sanitizeOps: false,
}, async () => {
  const userId = crypto.randomUUID();
  const message = "Hello from integration test";

  // Call remote AI function
  const res = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ user_id: userId, message }),
  });

  if (!res.ok) throw new Error(`API call failed ${res.status}`);

  // Give DB a moment to commit
  await new Promise((r) => setTimeout(r, 1000));

  // Query coach_interactions
  const client = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const { data, error } = await client
    .from("coach_interactions")
    .select("message")
    .eq("user_id", userId)
    .eq("message", message)
    .limit(1);

  if (error) throw error;
  if (!data || data.length === 0) {
    throw new Error("No coach_interactions row found for test message");
  }

  // -------------------
  // Run interaction-aggregate edge function for today to populate metrics
  // -------------------
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const AGG_FUNCTION_URL =
    `https://${PROJECT_ID}.functions.supabase.co/interaction-aggregate?date=${today}`;

  const aggRes = await fetch(AGG_FUNCTION_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Api-Version": "1",
      "Authorization": `Bearer ${SERVICE_ROLE_KEY}`,
    },
  });

  if (!aggRes.ok) {
    throw new Error(
      `interaction-aggregate failed status ${aggRes.status}`,
    );
  }

  // Give the upsert a moment to commit
  await new Promise((r) => setTimeout(r, 1000));

  // Verify metrics row was inserted for the test user
  const { data: metricRows, error: metricErr } = await client
    .from("coach_interaction_metrics")
    .select("user_id")
    .eq("user_id", userId)
    .eq("metric_date", today)
    .limit(1);

  if (metricErr) throw metricErr;
  if (!metricRows || metricRows.length === 0) {
    throw new Error(
      "No coach_interaction_metrics row found for test user",
    );
  }
});
