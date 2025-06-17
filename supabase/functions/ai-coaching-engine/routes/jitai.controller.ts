import { getLatestWearableData } from '../services/wearable-data.stub.ts'
import { predictTriggers } from '../services/predictive-trigger-model.ts'
import { logJITAIEvent } from '../services/jitai-event-logger.ts'
import { enqueueJITAITriggers } from '../services/jitai-push.ts'
import { recordJITAIOutcome } from '../services/jitai-effectiveness.ts'
import { getDailySleepScore, getRollingAvgHR } from '../services/wearable-summary.client.ts'
import { logCoachInteraction } from '../services/coach-interaction-logger.ts'
import { broadcastEvent } from '../../_shared/realtime-util.ts'

interface ControllerOptions {
  cors: Record<string, string>
}

export async function jitaiController(
  req: Request,
  { cors }: ControllerOptions,
): Promise<Response> {
  const start = Date.now()
  try {
    const body = await req.json()
    const { user_id } = body

    if (!user_id) {
      return json({ error: 'Missing required field: user_id' }, 400, cors)
    }

    // Obtain latest (mock) wearable data
    const wearableData = await getLatestWearableData(user_id)

    // Fetch summary metrics in parallel (non-blocking if fails)
    const [sleepScore, avgHr] = await Promise.all([
      getDailySleepScore(user_id),
      getRollingAvgHR(user_id, 60),
    ])

    let triggers = await predictTriggers(user_id, wearableData)

    // Additional heuristic triggers using summaries
    const push = (type: import('../types.ts').JITAITrigger['type'], message: string) => {
      if (!triggers.some((t) => t.type === type)) {
        triggers.push({ id: `${type}-${Date.now()}`, type, message })
      }
    }

    if (sleepScore !== null && sleepScore < 60) {
      push('sleep_hygiene', 'Your sleep score was low—aim for an earlier wind-down tonight.')
    }

    if (avgHr !== null && avgHr > 110 && wearableData.steps < 3000) {
      push('hydration_reminder', 'Elevated heart rate detected—take a hydration break.')
    }

    const source = Deno.env.get('PREDICTIVE_MODEL_URL') ? 'predictive' : 'rules'
    await logJITAIEvent(user_id, wearableData, triggers, source)

    // ⏺️ Persist each AI coach interaction (Epic 2.3)
    for (const trig of triggers) {
      await logCoachInteraction({
        userId: user_id,
        sender: 'ai',
        message: trig.message,
        metadata: {
          type: trig.type,
          source,
          latency_ms: Date.now() - start,
        },
      })
    }

    // Enqueue push notifications for triggers
    await enqueueJITAITriggers(user_id, triggers)

    // Log initial outcome as delivered
    for (const trig of triggers) {
      await recordJITAIOutcome(user_id, trig.id, 'delivered', trig.type)
    }

    // Broadcast momentum update event via realtime
    await broadcastEvent('coach_stream', 'momentum_update', {
      user_id,
      triggers,
      timestamp: new Date().toISOString(),
    })

    const requestId = crypto.randomUUID()
    return json({ success: true, triggers, response_time_ms: Date.now() - start }, 200, {
      ...cors,
      'X-Request-Id': requestId,
      'X-Response-Time-ms': (Date.now() - start).toString(),
    })
  } catch (err) {
    console.error('Error evaluating JITAI triggers:', err)
    return json(
      {
        error: 'Failed to evaluate JITAI triggers',
        message: err instanceof Error ? err.message : 'Unknown error',
        response_time_ms: Date.now() - start,
      },
      500,
      cors,
    )
  }
}

function json(payload: unknown, status: number, headers: Record<string, string>): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  })
}
