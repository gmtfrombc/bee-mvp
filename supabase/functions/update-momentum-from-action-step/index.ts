// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";
import { broadcastEvent } from "../_shared/realtime-util.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-api-version",
};

const API_VERSION = "1";

// Runtime-light types to avoid heavy imports
interface ActionStepLogEvent {
  user_id: string;
  action_step_id: string;
  day: string; // yyyy-mm-dd
  status: "completed" | "skipped";
  correlation_id: string;
}

type SupabaseClient = any; // Supabase JS client (lazy-loaded)

export async function handleRequest(req: Request): Promise<Response> {
  // ---------------------------------------------
  // CORS pre-flight
  // ---------------------------------------------
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  // ---------------------------------------------
  // Method check
  // ---------------------------------------------
  if (req.method !== "POST") {
    return json({ error: "Method Not Allowed" }, 405);
  }

  // ---------------------------------------------
  // API version header
  // ---------------------------------------------
  const versionHeader = req.headers.get("X-Api-Version");
  if (!versionHeader || versionHeader !== API_VERSION) {
    return json({ error: "Unsupported or missing X-Api-Version" }, 400);
  }

  const isTest = Deno.env.get("DENO_TESTING") === "true";

  // ---------------------------------------------
  // Auth (service-role key required when not testing)
  // ---------------------------------------------
  const authHeader = req.headers.get("Authorization");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
    Deno.env.get("SERVICE_ROLE_KEY");
  if (!isTest) {
    if (!authHeader) return json({ error: "Missing Authorization" }, 401);
    const token = authHeader.replace("Bearer ", "");
    if (serviceKey && token !== serviceKey) {
      return json({ error: "Unauthorized" }, 401);
    }
  }

  // ---------------------------------------------
  // Parse & validate body
  // ---------------------------------------------
  let payload: ActionStepLogEvent;
  try {
    payload = await req.json() as ActionStepLogEvent;
  } catch (_) {
    return json({ error: "Invalid JSON" }, 400);
  }

  const validationError = validatePayload(payload);
  if (validationError) {
    return json({ error: validationError }, 400);
  }

  try {
    if (!isTest) {
      // -----------------------------------------
      // DB upsert (idempotent via correlation_id)
      // -----------------------------------------
      const client: SupabaseClient = await getSupabaseClient(serviceKey);
      const { error } = await client.from("momentum_updates").upsert({
        user_id: payload.user_id,
        action_step_id: payload.action_step_id,
        day: payload.day,
        status: payload.status,
        correlation_id: payload.correlation_id,
      }, { onConflict: "correlation_id" });
      if (error) {
        console.error("update-momentum-from-action-step DB error", error);
        return json({ error: "db" }, 500);
      }

      // -----------------------------------------
      // Broadcast realtime event
      // -----------------------------------------
      const channel = `momentum_updates:${payload.user_id}`;
      await broadcastEvent(channel, "momentum_update", payload);
    }

    return json({ status: "accepted" }, 202);
  } catch (err) {
    console.error("update-momentum-from-action-step error", err);
    return json({ error: "internal" }, 500);
  }
}

// --------------------------------------------------
// Local dev server
// --------------------------------------------------
if (import.meta.main) {
  serve(handleRequest);
}

// --------------------------------------------------
// Helpers
// --------------------------------------------------
function validatePayload(body: Partial<ActionStepLogEvent>): string | null {
  const required = [
    "user_id",
    "action_step_id",
    "day",
    "status",
    "correlation_id",
  ] as const;
  for (const key of required) {
    if (!body[key]) return `Missing field: ${key}`;
  }

  // Very simple YYYY-MM-DD check
  if (!/^\d{4}-\d{2}-\d{2}$/.test(body.day!)) {
    return "Invalid day format (YYYY-MM-DD)";
  }

  if (body.status !== "completed" && body.status !== "skipped") {
    return "Invalid status (completed|skipped)";
  }

  return null;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
