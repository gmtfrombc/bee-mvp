// routes/pattern-aggregate.controller.ts
// Controller for POST /aggregate-patterns endpoint.

import { getSupabaseClient } from '../_shared/supabase_client.ts'
import { CrossPatientPatternsService } from '../personalization/cross-patient-patterns.ts'

interface ControllerOptions {
  cors: Record<string, string>
}

type SupabaseClient = unknown

export async function patternAggregateController(
  req: Request,
  { cors }: ControllerOptions,
): Promise<Response> {
  const start = Date.now()

  try {
    const body = await req.json()
    const {
      week_start,
      force_regenerate: _forceRegenerate = false,
      operation = 'weekly_aggregation',
    } = body

    // Authorization (service role)
    const authToken = req.headers.get('Authorization')?.replace('Bearer ', '')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
      Deno.env.get('SERVICE_ROLE_KEY')
    if (authToken !== serviceRoleKey) {
      return json({ error: 'Unauthorized: Service role key required' }, 401, cors)
    }

    // Compose service
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRole = serviceRoleKey
    if (!supabaseUrl || !serviceRole) {
      return json({ error: 'Missing Supabase configuration' }, 500, cors)
    }

    const supabaseClient: SupabaseClient = await getSupabaseClient({ overrideKey: serviceRole })
    const service = new CrossPatientPatternsService(supabaseClient)

    switch (operation) {
      case 'weekly_aggregation': {
        const weekStart = week_start ? new Date(week_start) : undefined
        const result = await service.processWeeklyAggregation(weekStart)
        return json(
          {
            success: result.success,
            patterns_created: result.patternsCreated,
            insights_generated: result.insightsGenerated,
            week_processed:
              (weekStart ?? new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)).toISOString().split(
                'T',
              )[0],
            response_time_ms: Date.now() - start,
          },
          result.success ? 200 : 500,
          cors,
        )
      }

      case 'generate_insights': {
        const weekStart = week_start
          ? new Date(week_start)
          : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
        const insights = await service.generateInsights(weekStart)
        return json(
          {
            success: true,
            insights,
            insights_count: insights.length,
            week_processed: weekStart.toISOString().split('T')[0],
            response_time_ms: Date.now() - start,
          },
          200,
          cors,
        )
      }

      default:
        return json(
          {
            error: 'Invalid operation type',
            supported_operations: ['weekly_aggregation', 'generate_insights'],
          },
          400,
          cors,
        )
    }
  } catch (err) {
    console.error('Pattern aggregation error:', err)
    return json({ error: 'Failed to process pattern aggregation' }, 500, cors)
  }
}

function json(payload: unknown, status: number, headers: Record<string, string>): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  })
}
