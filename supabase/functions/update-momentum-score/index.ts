// deno-lint-ignore-file
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-api-version",
};

const API_VERSION = "1" as const;

type SourceType = "pes_entry";

interface UpdateMomentumPayload {
  user_id: string;
  delta: number;
  source: SourceType;
}

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export async function handleRequest(req: Request): Promise<Response> {
  // -----------------------------
  // CORS pre-flight
  // -----------------------------
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method Not Allowed" }, 405);
  }

  // -----------------------------
  // API version check
  // -----------------------------
  if (req.headers.get("X-Api-Version") !== API_VERSION) {
    return jsonResponse(
      { error: "Invalid or missing X-Api-Version header" },
      400,
    );
  }

  // -----------------------------
  // Auth (service-role key unless in test env)
  // -----------------------------
  const isTestingEnv = Deno.env.get("DENO_TESTING") === "true";
  const authHeader = req.headers.get("Authorization");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SERVICE_ROLE_KEY");

  if (!isTestingEnv) {
    if (!authHeader) {
      return jsonResponse({ error: "Missing Authorization" }, 401);
    }
    if (authHeader.replace("Bearer ", "") !== serviceKey) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }
  }

  // -----------------------------
  // Parse & validate payload
  // -----------------------------
  let payload: UpdateMomentumPayload;
  try {
    payload = await req.json() as UpdateMomentumPayload;
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }

  const { user_id, delta, source } = payload;
  if (!user_id) return jsonResponse({ error: "user_id required" }, 400);
  if (typeof delta !== "number" || Number.isNaN(delta)) {
    return jsonResponse({ error: "delta must be a number" }, 400);
  }
  if (source !== "pes_entry") {
    return jsonResponse({ error: "source must be 'pes_entry'" }, 400);
  }

  try {
    if (!isTestingEnv) {
      const client = (await getSupabaseClient(serviceKey)) as SupabaseClient;

      const { error } = await client.from("engagement_events").insert({
        user_id,
        event_type: "pes_entry",
        points_delta: delta,
        source,
        created_at: new Date().toISOString(),
      });

      if (error) {
        console.error("update-momentum-score DB error", error);
        return jsonResponse({ error: "db" }, 500);
      }
    }

    return jsonResponse({ status: "accepted" }, 202);
  } catch (err) {
    console.error("update-momentum-score error", err);
    return jsonResponse({ error: "internal" }, 500);
  }
}

// Local dev entry-point
if (import.meta.main) {
  serve(handleRequest);
}
