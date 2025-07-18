import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// API version constant – increment on breaking changes
const API_VERSION = "1";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-api-version",
};

export function handleRequest(req: Request): Response {
  // CORS pre-flight
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  if (req.method !== "POST") {
    return json({ error: "Method Not Allowed" }, 405);
  }

  // API version check
  const versionHeader = req.headers.get("X-Api-Version");
  if (!versionHeader || versionHeader !== API_VERSION) {
    return json({ error: "Unsupported or missing X-Api-Version" }, 400);
  }

  // NOTE: This is a stub implementation created during pre-milestone prep.
  // The full business logic will be added in the milestone proper.
  return json({ status: "not_implemented" }, 501);
}

// Local dev entrypoint
if (import.meta.main) {
  serve(handleRequest);
}

// ──────────────────────────────────────────────────────────────────────────
// Helper
// --------------------------------------------------------------------------
function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
