// routes/frequency-opt.controller.ts
// Controller for POST /optimize-frequency endpoint.

import { FrequencyOptimizer } from '../personalization/frequency-optimizer.ts'

interface ControllerOptions {
  cors: Record<string, string>
}

export async function frequencyOptController(
  req: Request,
  { cors }: ControllerOptions,
): Promise<Response> {
  const start = Date.now()

  try {
    const body = await req.json()
    const { user_id, force_update = false } = body
    if (!user_id) return json({ error: 'Missing required field: user_id' }, 400, cors)

    const authToken = req.headers.get('Authorization')?.replace('Bearer ', '')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (authToken !== serviceRoleKey) {
      return json({ error: 'Unauthorized: Service role key required' }, 401, cors)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseAnon = Deno.env.get('SUPABASE_ANON_KEY')
    if (!supabaseUrl || !supabaseAnon) {
      return json({ error: 'Missing Supabase configuration' }, 500, cors)
    }

    const optimizer = new FrequencyOptimizer(supabaseUrl, supabaseAnon)
    const optimization = await optimizer.optimizeFrequency(user_id)

    if (optimization.recommendedFrequency !== optimization.currentFrequency || force_update) {
      await optimizer.updateUserPreferences(user_id, optimization, force_update)
    }

    return json(
      {
        success: true,
        user_id,
        optimization,
        applied: optimization.recommendedFrequency !== optimization.currentFrequency ||
          force_update,
        response_time_ms: Date.now() - start,
      },
      200,
      cors,
    )
  } catch (err) {
    console.error('Frequency optimization error:', err)
    return json({ error: 'Failed to optimize frequency' }, 500, cors)
  }
}

function json(payload: unknown, status: number, headers: Record<string, string>): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  })
}
