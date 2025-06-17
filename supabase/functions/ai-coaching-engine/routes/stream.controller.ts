import { broadcastEvent } from '../../_shared/realtime-util.ts'

interface StreamPayload {
  channel?: string // defaults to coach_stream
  event: 'typing' | 'momentum_update'
  payload: unknown
  user_id?: string
}

interface ControllerOptions {
  cors: Record<string, string>
}

export async function streamController(
  req: Request,
  { cors }: ControllerOptions,
): Promise<Response> {
  try {
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405, headers: cors })
    }

    // Auth – must be service role key
    const auth = req.headers.get('Authorization')?.replace('Bearer ', '')
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SERVICE_ROLE_KEY')
    if (auth !== serviceKey) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...cors, 'Content-Type': 'application/json' },
      })
    }

    const body: StreamPayload = await req.json()
    if (!body.event || !body.payload) {
      return new Response(JSON.stringify({ error: 'Missing event or payload' }), {
        status: 400,
        headers: { ...cors, 'Content-Type': 'application/json' },
      })
    }

    const channel = body.channel ?? 'coach_stream'
    await broadcastEvent(channel, body.event, body.payload)

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...cors, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('streamController error', err)
    return new Response(JSON.stringify({ error: 'Internal error' }), {
      status: 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    })
  }
}
