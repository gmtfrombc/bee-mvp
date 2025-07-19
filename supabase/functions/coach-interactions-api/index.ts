// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-api-version",
};

const API_VERSION = "1";

type SupabaseClient = any;

export async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const versionHeader = req.headers.get("X-Api-Version");
  if (!versionHeader || versionHeader !== API_VERSION) {
    return json({ error: "Unsupported or missing X-Api-Version" }, 400);
  }

  // Require service-role key for now (skip in test mode)
  const isTest = Deno.env.get("DENO_TESTING") === "true";
  const auth = req.headers.get("Authorization")?.replace("Bearer ", "");
  const srKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
    Deno.env.get("SERVICE_ROLE_KEY");
  if (!isTest && (!auth || auth !== srKey)) {
    return json({ error: "Unauthorized" }, 401);
  }

  const url = new URL(req.url);
  const pathname = url.pathname;
  const matches = (e: string) =>
    pathname.endsWith(e) || pathname.endsWith(`/v${API_VERSION}${e}`);

  if (matches("/history")) {
    return await handleHistory(url);
  }

  // ------------------------------------------------------------------
  // NEW: POST /prompt – deliver AI Coach prompt based on flag trigger
  // ------------------------------------------------------------------
  if (matches("/prompt")) {
    if (req.method !== "POST") {
      return json({ error: "Method Not Allowed" }, 405);
    }

    let body: {
      user_id?: string;
      template?: string;
      flag_type?: string;
    };
    try {
      body = await req.json();
    } catch (_) {
      return json({ error: "Invalid JSON" }, 400);
    }

    const { user_id, template, flag_type } = body;
    if (!user_id || !template || !flag_type) {
      return json({ error: "user_id, template, and flag_type required" }, 400);
    }
    if (template !== "biometric_drop") {
      return json({ error: "Unsupported template" }, 400);
    }
    if (!(flag_type === "low_steps" || flag_type === "low_sleep")) {
      return json(
        { error: "flag_type must be 'low_steps' or 'low_sleep'" },
        400,
      );
    }

    // Dynamically import the prompt template
    try {
      const path =
        `../ai-coaching-engine/prompt_templates/${template}_${flag_type}.ts`;
      const mod = await import(
        new URL(path, import.meta.url).href
      ) as { default: string };
      const prompt = mod.default;

      // Future: enqueue prompt for delivery via conversation engine.
      console.log("Prepared Coach prompt", {
        user_id,
        flag_type,
        prompt_snippet: prompt.slice(0, 60),
      });
    } catch (err) {
      console.error("Template load error", err);
      return json({ error: "template_load" }, 500);
    }

    return json({ status: "accepted" }, 202);
  }

  // ------------------------------------------------------------------
  // POST /refresh-context – invoked after biometrics save to refresh
  // downstream conversation context. For MVP it simply acknowledges the
  // request; future iterations may push events to a job queue.
  // ------------------------------------------------------------------
  if (matches("/refresh-context")) {
    if (req.method !== "POST") {
      return json({ error: "Method Not Allowed" }, 405);
    }

    let body: { user_id?: string };
    try {
      body = await req.json();
    } catch (_) {
      return json({ error: "Invalid JSON" }, 400);
    }
    if (!body.user_id) {
      return json({ error: "user_id required" }, 400);
    }

    // Future: call AI-coach pipeline, clear caches, etc.
    return json({ status: "accepted" }, 202);
  }

  return json({ error: "Not found" }, 404);
}

async function handleHistory(url: URL): Promise<Response> {
  const userId = url.searchParams.get("user_id");
  const limitStr = url.searchParams.get("limit") || "20";
  const limit = Math.min(100, Math.max(1, parseInt(limitStr)));
  if (!userId) return json({ error: "user_id required" }, 400);

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
    Deno.env.get("SERVICE_ROLE_KEY");
  const client: SupabaseClient = await getSupabaseClient(serviceKey);

  const { data, error } = await client
    .from("coach_interactions")
    .select("id, sender, message, metadata, created_at")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(limit);

  if (error) return json({ error: error.message }, 500);
  return json({ user_id: userId, interactions: data }, 200);
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

// Auto-start server in production runtime
if (import.meta.main) {
  serve(handleRequest);
}
