// services/conversation.service.ts
// Conversation service extracted from previous handleConversation logic.
// Provides processConversation that returns an HTTP Response for the conversational coaching endpoint.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildPrompt } from '../prompt-builder.ts'
import { detectRedFlags } from '../middleware/safety/red-flag-detector.ts'
import { analyzeSentiment, type SentimentResult } from '../sentiment/sentiment-analyzer.ts'
import { analyzeEngagement } from '../personalization/pattern-analysis.ts'
import { type CoachingPersona, derivePersona } from '../personalization/coaching-personas.ts'
import { getRecentMessages, logConversation } from '../response-logger.ts'
import { generateCacheKey, getCachedResponse, setCachedResponse } from '../middleware/cache.ts'
import { enforceRateLimit, RateLimitError } from '../middleware/rate-limit.ts'
import { engagementDataService } from './engagement-data.ts'
import { EffectivenessTracker } from '../personalization/effectiveness-tracker.ts'
import { StrategyOptimizer } from '../personalization/strategy-optimizer.ts'
import { callAIAPI } from './ai-client.ts'
import { GenerateResponseRequest, GenerateResponseResponse } from '../types.ts'

// --- Environment / singletons -------------------------------------------------

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_ANON = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
  Deno.env.get('SERVICE_ROLE_KEY') ?? ''

// Prevent DENO_TESTING leakage across subsequent test files
if (Deno.env.get('DENO_TESTING') === 'true') {
  Deno.env.set('DENO_TESTING', 'false')
}

// -----------------------------------------------------------------------------

interface ServiceOptions {
  cors: Record<string, string>
  isTestingEnv: boolean
}

export async function processConversation(
  req: Request,
  { cors, isTestingEnv }: ServiceOptions,
): Promise<Response> {
  const startTime = Date.now()

  const IS_TEST_ENV = isTestingEnv

  // Initialize trackers lazily to avoid network calls in tests
  const effTracker = (!IS_TEST_ENV && SUPABASE_URL && SUPABASE_ANON)
    ? new EffectivenessTracker(SUPABASE_URL, SUPABASE_ANON)
    : null
  const stratOptimizer = effTracker ? new StrategyOptimizer(effTracker) : null

  try {
    // Parse body
    const body: GenerateResponseRequest = await req.json()
    const {
      user_id,
      message,
      momentum_state = 'Steady',
      system_event,
      previous_state,
      current_score,
      article_id,
      article_summary,
    } = body as any

    if (!user_id || !message) {
      return json({ error: 'Missing required fields: user_id, message' }, 400, cors)
    }

    // Early safety check
    const redFlag = detectRedFlags(message)
    if (redFlag) {
      return json({ error: 'red_flag', category: redFlag }, 403, cors)
    }

    // Auth token extraction
    const authToken = req.headers.get('Authorization')?.replace('Bearer ', '')
    const isDev = SUPABASE_URL.includes('127.0.0.1') ||
      SUPABASE_URL.includes('localhost') || Deno.env.get('ENVIRONMENT') === 'development'
    const isTestUser = user_id === '00000000-0000-0000-0000-000000000001'

    // Require an auth token unless in dev mode with test user adjustments
    if (!authToken && !(isDev && isTestUser)) {
      return json({ error: 'Missing authorization token' }, 401, cors)
    }

    // Validate JWT unless explicitly skipped in test environment
    const isSystemEvent = req.headers.get('X-System-Event') === 'true'
    if (!IS_TEST_ENV && !(isSystemEvent && authToken === SERVICE_ROLE_KEY)) {
      if (!SUPABASE_URL || !SUPABASE_ANON) {
        return json({ error: 'Internal server error' }, 500, cors)
      }
      const supabase = createClient(SUPABASE_URL, SUPABASE_ANON)
      const { data: user, error: authErr } = await supabase.auth.getUser(authToken || '')
      if (authErr || !user?.user || user.user.id !== user_id) {
        return json({ error: 'Unauthorized' }, 401, cors)
      }
    }

    // Rate limit (skip for system momentum events)
    if (system_event !== 'momentum_change') {
      try {
        await enforceRateLimit(user_id)
      } catch (err) {
        if (err instanceof RateLimitError) {
          return new Response(
            JSON.stringify({ error: err.message, retryAfter: err.retryAfter }),
            {
              status: 429,
              headers: {
                ...cors,
                'Content-Type': 'application/json',
                'Retry-After': err.retryAfter?.toString() || '60',
              },
            },
          )
        }
        throw err
      }
    }

    // Log incoming message
    if (system_event === 'momentum_change') {
      await logConversation(
        user_id,
        'system',
        `Momentum changed from ${previous_state} to ${momentum_state}`,
        undefined,
        authToken || undefined,
      )
    } else {
      await logConversation(user_id, 'user', message, undefined, authToken || undefined)
    }

    // Historical context and engagement data
    const conversationHistory = await getRecentMessages(user_id, 20, authToken || undefined)
    const engagementEvents = await engagementDataService.getUserEngagementEvents(
      user_id,
      authToken || undefined,
    )
    const patternSummary = analyzeEngagement(engagementEvents)

    // Sentiment
    let sentiment: SentimentResult | null = null
    if (system_event !== 'momentum_change') {
      sentiment = await analyzeSentiment(message)
    }

    // Persona selection
    const timeOfDay = (() => {
      const h = new Date().getHours()
      return h < 12 ? 'morning' : h >= 18 ? 'evening' : 'afternoon'
    })()
    const engagementLevel = patternSummary.engagementFrequency === 'high'
      ? 'high'
      : patternSummary.engagementFrequency === 'low'
      ? 'low'
      : 'medium'

    let persona: string
    try {
      if (stratOptimizer) {
        const strat = await stratOptimizer.optimizeStrategyForUser(user_id, {
          momentumState: momentum_state as 'Rising' | 'Steady' | 'NeedsCare',
          userEngagementLevel: engagementLevel,
          timeOfDay,
          daysSinceLastInteraction: 0,
        })
        persona = strat.preferredPersona
      } else {
        persona = derivePersona(patternSummary, momentum_state)
      }
    } catch (_) {
      persona = derivePersona(patternSummary, momentum_state)
    }

    // Caching
    const cacheKey = await generateCacheKey(user_id, message, persona, sentiment?.label)
    let assistantMessage = await getCachedResponse(cacheKey)
    let cacheHit = !!assistantMessage

    if (!assistantMessage) {
      let promptMsg = message
      if (system_event === 'momentum_change') {
        promptMsg =
          `I noticed your momentum has shifted from ${previous_state} to ${momentum_state}. Let me offer some personalized guidance.`
      }
      const prompt = await buildPrompt(
        promptMsg,
        persona as CoachingPersona,
        patternSummary,
        momentum_state,
        conversationHistory,
        system_event === 'momentum_change'
          ? { isSystemEvent: true, previousState: previous_state, currentScore: current_score }
          : undefined,
        sentiment,
        article_summary
          ? { id: article_id as string | undefined, summary: article_summary as string }
          : undefined,
      )

      assistantMessage = await callAIAPI(prompt)
      await setCachedResponse(
        cacheKey,
        assistantMessage,
        system_event === 'momentum_change' ? 300 : 900,
      )
    }

    // Log assistant response
    const logId = await logConversation(
      user_id,
      'assistant',
      assistantMessage,
      persona,
      authToken || undefined,
    )

    if (logId && effTracker && system_event !== 'momentum_change') {
      try {
        await effTracker.recordInteractionEffectiveness({
          userId: user_id,
          conversationLogId: logId,
          personaUsed: persona as 'supportive' | 'challenging' | 'educational',
          interventionTrigger: system_event || 'user_message',
          momentumState: momentum_state as 'Rising' | 'Steady' | 'NeedsCare',
          responseTimeSeconds: Math.round((Date.now() - startTime) / 1000),
        })
      } catch (err) {
        console.error('Effectiveness tracking error:', err)
      }
    }

    const payload: GenerateResponseResponse = {
      assistant_message: assistantMessage,
      persona,
      response_time_ms: Date.now() - startTime,
      cache_hit: cacheHit,
    }

    return json(payload, 200, {
      ...cors,
      'X-Cache-Status': cacheHit ? 'HIT' : 'MISS',
      'X-Response-Time-ms': payload.response_time_ms.toString(),
    })
  } catch (err) {
    console.error('Conversation handler error:', err)
    return json({ error: 'Internal server error' }, 500, cors)
  }
}

function json(payload: unknown, status: number, headers: Record<string, string>): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  })
}
