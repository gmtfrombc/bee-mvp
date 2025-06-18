// Lazy Supabase client creator – avoids static supabase-js import
// This helper should be used instead of directly importing `createClient`.
// It dynamically loads the library only when you actually need to talk to Postgres.
// Runtime overhead is negligible once cached, but cold-start compile time stays minimal.

export async function getSupabaseClient(options?: {
  /**
   * Force a particular key (e.g. anon, service-role). Defaults to service-role
   * when available, otherwise falls back to anon key.
   */
  overrideKey?: string
}) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''

  // Prefer explicitly provided key → service-role → anon
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('SERVICE_ROLE_KEY')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const apiKey = options?.overrideKey ?? serviceRoleKey ?? anonKey ?? ''

  if (!supabaseUrl || !apiKey) {
    throw new Error('Missing SUPABASE_URL or API key env')
  }

  // Dynamic import keeps supabase-js out of the cold-start bundle
  const { createClient } = await import('npm:@supabase/supabase-js@2')
  return createClient(supabaseUrl, apiKey)
}
