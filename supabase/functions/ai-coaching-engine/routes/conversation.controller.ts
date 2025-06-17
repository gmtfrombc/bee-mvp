// routes/conversation.controller.ts
// Controller for conversation endpoint (default route).

import { processConversation } from '../services/conversation.service.ts'
import { logCoachInteraction } from '../services/coach-interaction-logger.ts'

const aiModel = Deno.env.get('AI_MODEL') || 'gpt-4o'

interface ControllerOptions {
  cors: Record<string, string>
  isTestingEnv: boolean
}

export async function conversationController(
  req: Request,
  { cors, isTestingEnv }: ControllerOptions,
): Promise<Response> {
  const startTime = Date.now()

  // Clone the incoming request so we can safely parse the body for logging
  const reqClone = req.clone()
  let userId = req.headers.get('x-user-id') ?? ''
  let userMessage = ''
  let momentumState: string | undefined = undefined

  try {
    const body = await reqClone.json()
    userId = body.user_id ?? userId ?? 'unknown'
    userMessage = body.message ?? ''
    momentumState = body.momentum_state
  } catch (_) {
    // Malformed JSON or empty body – keep defaults
  }

  // Log the user message (skip if no content)
  if (userMessage) {
    await logCoachInteraction({
      userId,
      sender: 'user',
      message: userMessage,
      metadata: { momentum_state: momentumState },
    })
  }

  const result = await processConversation(req, { cors, isTestingEnv })

  // Clone response to extract assistant message without consuming the stream
  const resClone = result.clone()
  let assistantMessage = ''
  let metaTokens: Record<string, number | string | undefined> = {}

  try {
    const json = await resClone.json()
    assistantMessage = json?.assistant_message ?? ''
    metaTokens = {
      prompt_tokens: json?.prompt_tokens,
      completion_tokens: json?.completion_tokens,
      total_tokens: json?.total_tokens,
      cost_usd: json?.cost_usd,
    }
  } catch (_) {
    // Non-JSON response – ignore
  }

  if (assistantMessage) {
    await logCoachInteraction({
      userId,
      sender: 'ai',
      message: assistantMessage,
      metadata: {
        model: aiModel,
        latency_ms: Date.now() - startTime,
        momentum_state: momentumState,
        ...metaTokens,
      },
    })
  }

  return result
}
