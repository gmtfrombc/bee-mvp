import { getSupabaseClient } from "../_shared/supabase_client.ts";

// Allowed readiness enum values as defined in onboarding scoring docs
const VALID_READINESS_LEVELS = ["Low", "Moderate", "High"] as const;

type ReadinessLevel = typeof VALID_READINESS_LEVELS[number];

// In-memory store used when SKIP_SUPABASE=true (unit-test mode)
const inMemoryStore = new Map<string, {
  motivation_type: string;
  readiness_level: string;
  coach_style: string;
}>();

export default async function handler(req: Request): Promise<Response> {
  // --------------------------------------------------
  // Guard HTTP method
  // --------------------------------------------------
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // --------------------------------------------------
  // Parse & validate JSON body
  // --------------------------------------------------
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_err) {
    return jsonError("invalid json", 400);
  }

  const user_id = body["user_id"] as string | undefined;
  const motivation_type = body["motivation_type"] as string | undefined;
  const readiness_level = body["readiness_level"] as string | undefined;
  const coach_style = body["coach_style"] as string | undefined;

  if (!user_id) return jsonError("user_id required", 400);
  if (!motivation_type) return jsonError("motivation_type required", 400);
  if (!readiness_level) return jsonError("readiness_level required", 400);
  if (!coach_style) return jsonError("coach_style required", 400);
  if (!VALID_READINESS_LEVELS.includes(readiness_level as ReadinessLevel)) {
    return jsonError(
      "readiness_level must be Low/Moderate/High",
      400,
    );
  }

  // --------------------------------------------------
  // Offline mode for unit tests (no DB interaction)
  // --------------------------------------------------
  if (Deno.env.get("SKIP_SUPABASE") === "true") {
    const existing = inMemoryStore.get(user_id);
    if (
      existing &&
      existing.motivation_type === motivation_type &&
      existing.readiness_level === readiness_level &&
      existing.coach_style === coach_style
    ) {
      return jsonSuccess("duplicate_ignored", 409);
    }

    inMemoryStore.set(user_id, {
      motivation_type,
      readiness_level,
      coach_style,
    });
    return jsonSuccess("success", 200);
  }

  // --------------------------------------------------
  // Live DB path – upsert into coach_memory
  // --------------------------------------------------
  try {
    const supabase = await getSupabaseClient();

    // Check existing row first for idempotency
    const { data: existingRow, error: selectErr } = await supabase
      .from("coach_memory")
      .select("motivation_type, readiness_level, coach_style")
      .eq("user_id", user_id)
      .maybeSingle();

    if (selectErr && selectErr.code !== "PGRST116") { // ignore row missing
      console.error("Error selecting coach_memory", selectErr);
      return jsonError("internal", 500);
    }

    if (
      existingRow &&
      existingRow.motivation_type === motivation_type &&
      existingRow.readiness_level === readiness_level &&
      existingRow.coach_style === coach_style
    ) {
      return jsonSuccess("duplicate_ignored", 409);
    }

    const { error: upsertErr } = await supabase.from("coach_memory").upsert({
      user_id,
      motivation_type,
      readiness_level,
      coach_style,
    }, {
      onConflict: "user_id",
    });

    if (upsertErr) {
      console.error("Upsert error", upsertErr);
      return jsonError("internal", 500);
    }

    return jsonSuccess("success", 200);
  } catch (err) {
    console.error("Unhandled error in sync-ai-tags", err);
    return jsonError("internal", 500);
  }
}

// ------------------------ Helpers ------------------------
function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function jsonSuccess(statusMsg: string, status: number = 200): Response {
  return new Response(JSON.stringify({ status: statusMsg }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
