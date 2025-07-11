// Shared lazy Supabase client creator for all Edge Functions
// Applies Node-compat polyfills before loading any third-party libs.

import "./node_polyfills.ts";
// Avoids static `@supabase/supabase-js` compile-time dependency.

export async function getSupabaseClient(overrideKey?: string) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const apiKey = overrideKey ?? serviceRoleKey ?? anonKey ?? "";

  if (!supabaseUrl || !apiKey) {
    throw new Error("Missing SUPABASE_URL or API key env");
  }

  const { createClient } = await import(
    "https://esm.sh/@supabase/supabase-js@2"
  );
  return createClient(supabaseUrl, apiKey);
}
