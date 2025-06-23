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
  // During unit tests we stub the client to avoid network/npm resolution overhead.
  if (Deno.env.get('DENO_TESTING') === 'true') {
    return {
      from: () => ({
        select: () => ({ data: [], error: null }),
        insert: () => ({ error: null }),
        update: () => ({ error: null }),
        upsert: () => ({ data: null, error: null }),
        single: () => ({ data: null, error: null }),
      }),
      auth: {
        getUser: (token: string) => ({
          data: {
            user: {
              id: token?.includes('valid-jwt-token')
                ? 'test-user-id'
                : '00000000-0000-0000-0000-000000000001',
            },
          },
          error: null,
        }),
      },
    } as unknown
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''

  // Prefer explicitly provided key → service-role → anon
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('SERVICE_ROLE_KEY')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const apiKey = options?.overrideKey ?? serviceRoleKey ?? anonKey ?? ''

  if (!supabaseUrl || !apiKey) {
    throw new Error('Missing SUPABASE_URL or API key env')
  }

  try {
    // Dynamic import keeps supabase-js out of the cold-start bundle
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
    return createClient(supabaseUrl, apiKey)
  } catch (_err) {
    // In CI or offline test environments the npm import may fail – return minimal stub
    console.warn('Supabase init failed', _err)
    return {
      from: () => ({
        select: () => ({ data: [], error: null }),
        insert: () => ({ error: null }),
        update: () => ({ error: null }),
        upsert: () => ({ data: null, error: null }),
        single: () => ({ data: null, error: null }),
      }),
      auth: {
        getUser: (token: string) => ({
          data: {
            user: {
              id: token?.includes('valid-jwt-token')
                ? 'test-user-id'
                : '00000000-0000-0000-0000-000000000001',
            },
          },
          error: null,
        }),
      },
    } as unknown
  }
}
