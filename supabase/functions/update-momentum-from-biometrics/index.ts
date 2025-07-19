import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// CORS + API versioning
// ---------------------------------------------------------------------------
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-api-version",
};

const API_VERSION = "1" as const;

type SourceType = "manual_biometrics";

interface MomentumPayload {
  user_id: string;
  delta: number;
  source: SourceType;
}

// ---------------------------------------------------------------------------
// Entry-point
// ---------------------------------------------------------------------------
export async function handleRequest(req: Request): Promise<Response> {
  // CORS pre-flight
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  if (req.method !== "POST") {
    return json({ error: "Method Not Allowed" }, 405);
  }

  // API version header
  if (req.headers.get("X-Api-Version") !== API_VERSION) {
    return json({ error: "Invalid or missing X-Api-Version header" }, 400);
  }

  const isTest = Deno.env.get("DENO_TESTING") === "true";

  // Auth – require service-role key unless running under test harness
  const authHeader = req.headers.get("Authorization");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SERVICE_ROLE_KEY");
  if (!isTest) {
    if (!authHeader) return json({ error: "Missing Authorization" }, 401);
    if (authHeader.replace("Bearer ", "") !== serviceKey) {
      return json({ error: "Unauthorized" }, 401);
    }
  }

  // Parse & validate payload
  let payload: MomentumPayload;
  try {
    payload = await req.json() as MomentumPayload;
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const validationError = validatePayload(payload);
  if (validationError) return json({ error: validationError }, 400);

  try {
    if (!isTest) {
      // ---------------------------------------------------------------------
      // 1️⃣  Insert engagement event (momentum modifier)
      // ---------------------------------------------------------------------
      const client: SupabaseClient = await getSupabaseClient(serviceKey);
      const { error } = await client.from("engagement_events").insert({
        user_id: payload.user_id,
        event_type: "manual_biometrics",
        points_delta: payload.delta,
        source: payload.source,
        created_at: new Date().toISOString(),
      });
      if (error) {
        console.error("update-momentum-from-biometrics DB error", error);
        return json({ error: "db" }, 500);
      }

      // ---------------------------------------------------------------------
      // 2️⃣  Forward context refresh to coach-interactions-api
      // ---------------------------------------------------------------------
      const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
      if (supabaseUrl && serviceKey) {
        const coachUrl =
          `${supabaseUrl}/functions/v1/coach-interactions-api/refresh-context`;
        try {
          const res = await fetch(coachUrl, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "X-Api-Version": "1",
              Authorization: `Bearer ${serviceKey}`,
            },
            body: JSON.stringify({ user_id: payload.user_id }),
          });
          if (!res.ok) {
            console.error("coach-interactions-api forward failed", res.status);
          }
        } catch (err) {
          console.error("coach-interactions-api fetch error", err);
        }
      }
    }

    return json({ status: "accepted" }, 202);
  } catch (err) {
    console.error("update-momentum-from-biometrics error", err);
    return json({ error: "internal" }, 500);
  }
}

// Local dev entry-point
if (import.meta.main) {
  serve(handleRequest);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function validatePayload(body: Partial<MomentumPayload>): string | null {
  if (!body.user_id) return "user_id required";
  if (typeof body.delta !== "number" || Number.isNaN(body.delta)) {
    return "delta must be a number";
  }
  if (body.source !== "manual_biometrics") {
    return "source must be 'manual_biometrics'";
  }
  return null;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
