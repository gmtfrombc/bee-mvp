import { getSupabaseClient } from './_shared/supabase_client.ts'
import { analyzeEngagement } from './personalization/pattern-analysis.ts'
import { type CoachingPersona, derivePersona } from './personalization/coaching-personas.ts'
import { buildPrompt } from './prompt-builder.ts'
import { getRecentMessages, logConversation } from './response-logger.ts'
import { generateCacheKey, getCachedResponse, setCachedResponse } from './middleware/cache.ts'
import { enforceRateLimit, RateLimitError } from './middleware/rate-limit.ts'
import { detectRedFlags } from './middleware/safety/red-flag-detector.ts'
import { analyzeSentiment, type SentimentResult } from './sentiment/sentiment-analyzer.ts'
import { engagementDataService } from './services/engagement-data.ts'
import { EffectivenessTracker } from './personalization/effectiveness-tracker.ts'
import { StrategyOptimizer } from './personalization/strategy-optimizer.ts'
import { FrequencyOptimizer } from './personalization/frequency-optimizer.ts'
import { CrossPatientPatternsService } from './personalization/cross-patient-patterns.ts'
import { dailyContentController } from './routes/daily-content.controller.ts'
import { frequencyOptController } from './routes/frequency-opt.controller.ts'
import { patternAggregateController } from './routes/pattern-aggregate.controller.ts'
import { conversationController } from './routes/conversation.controller.ts'
import { jitaiController } from './routes/jitai.controller.ts'
import { type Route, route } from 'jsr:@std/http/unstable-route'
import { streamController } from './routes/stream.controller.ts'
import { recordLatency } from '../_shared/metrics.ts'

// ---------------------------------------------------------------------------
// Environment configuration
// ---------------------------------------------------------------------------
const supabaseUrl = Deno.env.get('SUPABASE_URL')
const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SERVICE_ROLE_KEY')
console.log(`🔑 Service role key present: ${serviceRoleKey ? 'yes' : 'no'}`)

// Use service-role key for server-side inserts when available (bypasses RLS)
const supabaseKeyForWrites = serviceRoleKey ?? anonKey

// Allow either AI_API_KEY (preferred) or legacy OPENAI_API_KEY for backward compatibility
const aiApiKey: string = Deno.env.get('AI_API_KEY') ?? Deno.env.get('OPENAI_API_KEY') ?? ''
const aiModel = Deno.env.get('AI_MODEL') || 'gpt-4o'
console.log(`🤖 AI model selected: ${aiModel}`)

// ---------------------------------------------------------------------------
// Runtime flags
// ---------------------------------------------------------------------------
const isTestingEnvironment = Deno.env.get('DENO_TESTING') === 'true'

// Prevent DENO_TESTING leakage across subsequent test files
if (isTestingEnvironment) {
  Deno.env.set('DENO_TESTING', 'false')
}

// ---------------------------------------------------------------------------
// Service initialisation
// ---------------------------------------------------------------------------
const effectivenessTracker = (supabaseUrl && supabaseKeyForWrites && !isTestingEnvironment)
  ? new EffectivenessTracker(supabaseUrl, supabaseKeyForWrites)
  : null
const strategyOptimizer = effectivenessTracker ? new StrategyOptimizer(effectivenessTracker) : null
const frequencyOptimizer = (supabaseUrl && anonKey && !isTestingEnvironment)
  ? new FrequencyOptimizer(supabaseUrl, anonKey)
  : null

// Initialize cross-patient patterns service lazily to avoid supabase-js at compile time.
let crossPatientService: CrossPatientPatternsService | null = null
if (supabaseUrl && anonKey && serviceRoleKey && !isTestingEnvironment) {
  ;(async () => {
    try {
      const client = await getSupabaseClient({ overrideKey: serviceRoleKey })
      crossPatientService = new CrossPatientPatternsService(client)
    } catch (err) {
      console.warn('Failed to init crossPatientService', err)
    }
  })()
}

// TODO: Move model-ID lookup into prompt-builder.ts once we firm up tiered pricing
// This will allow for dynamic model selection based on user tier, conversation complexity, etc.

interface GenerateResponseRequest {
  user_id: string
  message: string
  momentum_state?: string
  system_event?: string
  previous_state?: string
  current_score?: number
}

interface GenerateResponseResponse {
  assistant_message: string
  persona: string
  response_time_ms: number
  cache_hit: boolean
}

interface DailyContentRequest {
  content_date: string
  topic_category?: string
  force_regenerate?: boolean
}

interface GeneratedContent {
  title: string
  summary: string
  topic_category: string
  confidence_score: number
  content_url?: string
  external_link?: string
}

interface AIMessage {
  role: 'system' | 'user' | 'assistant'
  content: string
}

interface OpenAIRequestBody {
  model: string
  messages: AIMessage[]
  max_tokens: number
  temperature: number
}

interface AnthropicRequestBody {
  model: string
  max_tokens: number
  messages: AIMessage[]
  system: string
}

// CORS headers constant (move out for global reuse)
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// OPTIONS preflight handler
function handleOptions(): Response {
  return new Response(null, { headers: corsHeaders })
}

// Build route definitions with lightweight wrappers for controllers
const routes: Route[] = [
  {
    pattern: new URLPattern({ pathname: '/generate-daily-content' }),
    handler: async (req) => {
      if (req.method === 'OPTIONS') return handleOptions()
      const start = Date.now()
      const res = await dailyContentController(req, {
        cors: corsHeaders,
        isTestingEnv: isTestingEnvironment,
        supabaseUrl,
        serviceRoleKey,
      })
      await recordLatency('/generate-daily-content', Date.now() - start)
      return res
    },
  },
  {
    pattern: new URLPattern({ pathname: '/optimize-frequency' }),
    handler: (req) => {
      if (req.method === 'OPTIONS') return handleOptions()
      return frequencyOptController(req, { cors: corsHeaders })
    },
  },
  {
    pattern: new URLPattern({ pathname: '/aggregate-patterns' }),
    handler: (req) => {
      if (req.method === 'OPTIONS') return handleOptions()
      return patternAggregateController(req, { cors: corsHeaders })
    },
  },
  {
    pattern: new URLPattern({ pathname: '/evaluate-jitai' }),
    handler: (req) => {
      if (req.method === 'OPTIONS') return handleOptions()
      return jitaiController(req, { cors: corsHeaders })
    },
  },
  // conversation endpoint for root path
  {
    pattern: new URLPattern({ pathname: '/' }),
    handler: (req) => {
      if (req.method === 'OPTIONS') return handleOptions()
      if (req.method !== 'POST') {
        return new Response('Method not allowed', { status: 405, headers: corsHeaders })
      }
      return conversationController(req, {
        cors: corsHeaders,
        isTestingEnv: isTestingEnvironment,
      })
    },
  },
  // wildcard catch-all for any sub-paths not matched above (still conversation)
  {
    pattern: new URLPattern({ pathname: '/*' }),
    handler: (req) => {
      if (req.method === 'OPTIONS') return handleOptions()
      if (req.method !== 'POST') {
        return new Response('Method not allowed', { status: 405, headers: corsHeaders })
      }
      return conversationController(req, {
        cors: corsHeaders,
        isTestingEnv: isTestingEnvironment,
      })
    },
  },
  {
    pattern: new URLPattern({ pathname: '/v1/stream' }),
    handler: (req) => {
      if (req.method === 'OPTIONS') return handleOptions()
      return streamController(req, { cors: corsHeaders })
    },
  },
]

const router = route(
  routes,
  (_req) => new Response('Not Found', { status: 404, headers: corsHeaders }),
)

export default async function handler(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return handleOptions()
  const start = Date.now()
  const res = await router(req)
  const ms = Date.now() - start
  try {
    const path = new URL(req.url).pathname
    await recordLatency(path, ms)
  } catch (_) {}
  if (res.status === 404 && req.method === 'POST') {
    return await conversationController(req, {
      cors: corsHeaders,
      isTestingEnv: isTestingEnvironment,
    })
  }
  return res
}

/**
 * Handle frequency optimization requests
 */
async function _handleFrequencyOptimization(
  req: Request,
  corsHeaders: Record<string, string>,
): Promise<Response> {
  const startTime = Date.now()

  try {
    // Parse request
    const body = await req.json()
    const { user_id, force_update = false } = body

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: user_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Validate service role authentication for system operations
    const authToken = req.headers.get('Authorization')?.replace('Bearer ', '')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
      Deno.env.get('SERVICE_ROLE_KEY')

    if (authToken !== serviceRoleKey) {
      return new Response(
        JSON.stringify({
          error: 'Unauthorized: Service role key required for frequency optimization',
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Check if frequency optimizer is available
    if (!frequencyOptimizer) {
      return new Response(
        JSON.stringify({ error: 'Frequency optimizer not available' }),
        { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Run frequency optimization for the user
    const optimization = await frequencyOptimizer.optimizeFrequency(user_id)

    // Apply the optimization if settings changed or forced
    if (optimization.recommendedFrequency !== optimization.currentFrequency || force_update) {
      await frequencyOptimizer.updateUserPreferences(user_id, optimization, force_update)
      console.log(
        `✅ Frequency optimization applied for user ${user_id}: ${optimization.adjustmentReason}`,
      )
    } else {
      console.log(`ℹ️ No frequency changes needed for user ${user_id}`)
    }

    return new Response(
      JSON.stringify({
        success: true,
        user_id,
        optimization,
        applied: optimization.recommendedFrequency !== optimization.currentFrequency ||
          force_update,
        response_time_ms: Date.now() - startTime,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    console.error('Error optimizing frequency:', error)
    return new Response(
      JSON.stringify({
        error: 'Failed to optimize frequency',
        message: error instanceof Error ? error.message : 'Unknown error',
        response_time_ms: Date.now() - startTime,
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
}

/**
 * Handle cross-patient pattern aggregation requests (Epic 3.1 preparation)
 */
async function _handlePatternAggregation(
  req: Request,
  corsHeaders: Record<string, string>,
): Promise<Response> {
  const startTime = Date.now()

  try {
    // Parse request
    const body = await req.json()
    const {
      week_start,
      force_regenerate: _force_regenerate = false,
      operation = 'weekly_aggregation',
    } = body

    // Validate service role authentication for system operations
    const authToken = req.headers.get('Authorization')?.replace('Bearer ', '')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
      Deno.env.get('SERVICE_ROLE_KEY')

    if (authToken !== serviceRoleKey) {
      return new Response(
        JSON.stringify({
          error: 'Unauthorized: Service role key required for pattern aggregation',
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Check if cross-patient service is available
    if (!crossPatientService) {
      return new Response(
        JSON.stringify({ error: 'Cross-patient patterns service not available' }),
        { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Handle different operation types
    switch (operation) {
      case 'weekly_aggregation': {
        const weekStart = week_start ? new Date(week_start) : undefined
        const result = await crossPatientService.processWeeklyAggregation(weekStart)

        return new Response(
          JSON.stringify({
            success: result.success,
            message: result.success
              ? 'Pattern aggregation completed successfully'
              : 'Pattern aggregation failed',
            patterns_created: result.patternsCreated,
            insights_generated: result.insightsGenerated,
            week_processed: weekStart?.toISOString().split('T')[0] ||
              new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
            response_time_ms: Date.now() - startTime,
          }),
          {
            status: result.success ? 200 : 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          },
        )
      }

      case 'generate_insights': {
        const weekStart = week_start
          ? new Date(week_start)
          : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
        const insights = await crossPatientService.generateInsights(weekStart)

        return new Response(
          JSON.stringify({
            success: true,
            message: 'Insights generated successfully',
            insights,
            insights_count: insights.length,
            week_processed: weekStart.toISOString().split('T')[0],
            response_time_ms: Date.now() - startTime,
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }

      default: {
        return new Response(
          JSON.stringify({
            error: 'Invalid operation type',
            supported_operations: ['weekly_aggregation', 'generate_insights'],
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    }
  } catch (error) {
    console.error('Error in pattern aggregation:', error)
    return new Response(
      JSON.stringify({
        error: 'Failed to process pattern aggregation',
        message: error instanceof Error ? error.message : 'Unknown error',
        response_time_ms: Date.now() - startTime,
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
}

/**
 * Handle conversation requests (original functionality)
 */
async function _handleConversation(
  req: Request,
  corsHeaders: Record<string, string>,
): Promise<Response> {
  const startTime = Date.now()

  try {
    // Parse request
    const body: GenerateResponseRequest = await req.json()
    const {
      user_id,
      message,
      momentum_state = 'Steady',
      system_event,
      previous_state,
      current_score,
    } = body

    if (!user_id || !message) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, message' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Check for red flags in user message early (before auth/db operations)
    const redFlag = detectRedFlags(message)
    if (redFlag) {
      console.log(`Red-flag ${redFlag} triggered for user: ${user_id}`)
      // TODO: Write flagged events to secured "moderation_logs" table when PHI audit work begins
      // This will enable proper audit trail and compliance reporting for content moderation
      return new Response(
        JSON.stringify({
          error: 'red_flag',
          category: redFlag,
          message: 'Message contains content that requires special handling',
        }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      )
    }

    // Extract auth token
    const authToken = req.headers.get('Authorization')?.replace('Bearer ', '')

    // Check for development mode (local Supabase instance)
    // Note: Supabase routes through Kong proxy, so check for local indicators
    const isDevelopmentMode = (supabaseUrl && (
      supabaseUrl.includes('127.0.0.1') ||
      supabaseUrl.includes('localhost') ||
      supabaseUrl.includes('kong:8000')
    )) || Deno.env.get('ENVIRONMENT') === 'development'
    const isTestUser = user_id === '00000000-0000-0000-0000-000000000001'

    // Debug logging
    console.log(`🔍 Auth Debug - URL: ${supabaseUrl}`)
    console.log(`🔍 Auth Debug - isDevelopmentMode: ${isDevelopmentMode}`)
    console.log(`🔍 Auth Debug - user_id: ${user_id}`)
    console.log(`🔍 Auth Debug - isTestUser: ${isTestUser}`)
    console.log(`🔍 Auth Debug - authToken present: ${!!authToken}`)
    console.log(`🔍 Auth Debug - authToken length: ${authToken?.length || 0}`)
    console.log(`🔐 Using service role key for writes: ${serviceRoleKey ? 'yes' : 'no'}`)

    if (isDevelopmentMode && isTestUser && !authToken) {
      // Allow development mode with test user ID (no auth required)
      console.log(`🧪 Development mode: allowing test user ${user_id} without authentication`)
    } else if (isDevelopmentMode && isTestUser && authToken) {
      // Development mode with test user but auth token present - allow anyway
      console.log(
        `🧪 Development mode: allowing test user ${user_id} with auth token (bypassing validation)`,
      )
    } else if (!authToken) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    } else {
      // Check if this is a system event with service role key
      const isSystemEvent = req.headers.get('X-System-Event') === 'true'
      const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

      if (isSystemEvent && authToken === serviceRoleKey) {
        // Allow system events with service role key
        console.log(`System event authenticated for user: ${user_id}`)
      } else {
        // Validate JWT for regular user requests (skip in test environment)
        if (isTestingEnvironment) {
          // Skip JWT validation in test environment
          console.log(`🧪 Test environment: skipping JWT validation for user ${user_id}`)
        } else {
          if (!supabaseUrl || !supabaseKeyForWrites) {
            return new Response(
              JSON.stringify({ error: 'Internal server error' }),
              { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
            )
          }
          const supabase = await getSupabaseClient({ overrideKey: supabaseKeyForWrites! })
          const { data: user, error: authError } = await supabase.auth.getUser(authToken)
          if (authError || !user?.user || user.user.id !== user_id) {
            return new Response(
              JSON.stringify({ error: 'Unauthorized' }),
              { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
            )
          }
        }
      }
    }

    // Check rate limit using new middleware (skip for system events)
    if (system_event !== 'momentum_change') {
      try {
        await enforceRateLimit(user_id)
      } catch (error) {
        if (error instanceof RateLimitError) {
          return new Response(
            JSON.stringify({
              error: error.message,
              retryAfter: error.retryAfter,
            }),
            {
              status: 429,
              headers: {
                ...corsHeaders,
                'Content-Type': 'application/json',
                'Retry-After': error.retryAfter?.toString() || '60',
              },
            },
          )
        }
        throw error // Re-throw if not a rate limit error
      }
    }

    // Log user message first (handle system events differently)
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

    // Fetch recent conversation history
    const conversationHistory = await getRecentMessages(user_id, 20, authToken || undefined)

    // Analyze user engagement patterns using real data
    const engagementEvents = await engagementDataService.getUserEngagementEvents(
      user_id,
      authToken || undefined,
    )
    const patternSummary = analyzeEngagement(engagementEvents)

    // Analyze sentiment of user message (skip for system events)
    let sentimentResult: SentimentResult | null = null
    if (system_event !== 'momentum_change') {
      sentimentResult = await analyzeSentiment(message)
      console.log(
        `Sentiment analyzed for user ${user_id}: ${sentimentResult.label} (${
          sentimentResult.score.toFixed(2)
        })`,
      )
    }

    // Determine time of day for strategy optimization
    const currentHour = new Date().getHours()
    let timeOfDay: 'morning' | 'afternoon' | 'evening' = 'afternoon'
    if (currentHour < 12) timeOfDay = 'morning'
    else if (currentHour >= 18) timeOfDay = 'evening'

    // Derive user engagement level from pattern summary
    const userEngagementLevel = patternSummary.engagementFrequency === 'high'
      ? 'high'
      : patternSummary.engagementFrequency === 'low'
      ? 'low'
      : 'medium'

    // Get optimized coaching strategy using effectiveness data
    let persona: string
    let adaptationReasons: string[] = []

    try {
      if (strategyOptimizer) {
        const strategy = await strategyOptimizer.optimizeStrategyForUser(user_id, {
          momentumState: momentum_state as 'Rising' | 'Steady' | 'NeedsCare',
          userEngagementLevel,
          timeOfDay,
          daysSinceLastInteraction: 0, // TODO: Calculate based on conversation history
        })

        persona = strategy.preferredPersona
        adaptationReasons = strategy.adaptationReasons

        console.log(`Strategy optimized for user ${user_id}: ${persona} persona selected`)
        console.log(`Adaptation reasons: ${adaptationReasons.join(', ')}`)
      } else {
        // Fallback when strategyOptimizer is not available (e.g., in tests)
        persona = derivePersona(patternSummary, momentum_state)
      }
    } catch (error) {
      console.error('Error optimizing strategy, falling back to default persona selection:', error)
      // Fallback to original persona derivation
      persona = derivePersona(patternSummary, momentum_state)
    }

    // Check cache first - include sentiment in cache key for better personalization
    const cacheKey = await generateCacheKey(user_id, message, persona, sentimentResult?.label)
    const cachedResponse = await getCachedResponse(cacheKey)

    let assistantMessage: string
    let cacheHit = false

    if (cachedResponse) {
      assistantMessage = cachedResponse
      cacheHit = true
    } else {
      // Build prompt (handle momentum change events with special context)
      let promptMessage = message
      if (system_event === 'momentum_change') {
        promptMessage =
          `I noticed your momentum has shifted from ${previous_state} to ${momentum_state}. Let me offer some personalized guidance to help you with this transition.`
      }

      const prompt = await buildPrompt(
        promptMessage,
        persona as CoachingPersona,
        patternSummary,
        momentum_state,
        conversationHistory,
        system_event === 'momentum_change'
          ? {
            isSystemEvent: true,
            previousState: previous_state,
            currentScore: current_score,
          }
          : undefined,
        sentimentResult,
      )

      // Call AI API
      assistantMessage = await callAIAPI(prompt)

      // Cache the response (shorter TTL for system events)
      const cacheTTL = system_event === 'momentum_change' ? 5 * 60 : 15 * 60 // 5 or 15 minutes
      await setCachedResponse(cacheKey, assistantMessage, cacheTTL)
    }

    // Log assistant response
    const conversationLogId = await logConversation(
      user_id,
      'assistant',
      assistantMessage,
      persona,
      authToken || undefined,
    )

    // Record effectiveness metrics for this interaction (skip for system events)
    if (system_event !== 'momentum_change' && conversationLogId && effectivenessTracker) {
      try {
        await effectivenessTracker.recordInteractionEffectiveness({
          userId: user_id,
          conversationLogId,
          personaUsed: persona as 'supportive' | 'challenging' | 'educational',
          interventionTrigger: system_event || 'user_message',
          momentumState: momentum_state as 'Rising' | 'Steady' | 'NeedsCare',
          responseTimeSeconds: Math.round((Date.now() - startTime) / 1000),
        })

        console.log(`Effectiveness metrics recorded for conversation ${conversationLogId}`)
      } catch (error) {
        console.error('Error recording effectiveness metrics:', error)
        // Don't fail the response if effectiveness tracking fails
      }
    }

    const responseTime = Date.now() - startTime

    const response: GenerateResponseResponse = {
      assistant_message: assistantMessage,
      persona,
      response_time_ms: responseTime,
      cache_hit: cacheHit,
    }

    return new Response(
      JSON.stringify(response),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'X-Cache-Status': cacheHit ? 'HIT' : 'MISS',
        },
      },
    )
  } catch (error) {
    console.error('Error in AI coaching handler:', error)
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    )
  }
}

/**
 * Call the AI API with the constructed prompt
 * TODO: Abstract this model selection logic into prompt-builder.ts for tiered pricing
 */
async function callAIAPI(prompt: AIMessage[]): Promise<string> {
  const apiUrl = aiModel.startsWith('gpt')
    ? 'https://api.openai.com/v1/chat/completions'
    : 'https://api.anthropic.com/v1/messages'

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  }

  let body: OpenAIRequestBody | AnthropicRequestBody

  if (aiModel.startsWith('gpt')) {
    // OpenAI format
    headers['Authorization'] = `Bearer ${aiApiKey}`
    body = {
      model: aiModel,
      messages: prompt,
      max_tokens: 200,
      temperature: 0.7,
    }
  } else {
    // Anthropic Claude format
    headers['x-api-key'] = aiApiKey
    headers['anthropic-version'] = '2023-06-01'

    body = {
      model: aiModel,
      max_tokens: 200,
      messages: prompt.filter((msg) => msg.role !== 'system'),
      system: prompt.find((msg) => msg.role === 'system')?.content || '',
    }
  }

  // Development-mode fallback: avoid external API calls when running locally
  const offlineFlag = Deno.env.get('OFFLINE_AI') === 'true'

  // Only bypass the real API if the developer explicitly sets OFFLINE_AI=true **or** no key is present
  if (offlineFlag || !aiApiKey) {
    console.log(
      '🧪 OFFLINE_AI mode – returning locally-generated response instead of calling external AI API',
    )
    const lastUserMsg = [...prompt].reverse().find((p) => p.role === 'user')?.content ||
      'your goals'
    return `I hear that ${lastUserMsg}. Let's take one small step today to build momentum! What is one action you can commit to right now?`
  }

  const response = await fetch(apiUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  })

  if (!response.ok) {
    console.error(`AI API error: ${response.status} ${response.statusText}`)
    // Return graceful fallback instead of throwing in non-prod envs
    if (response.status === 401 || response.status === 403) {
      return "I'm having trouble connecting to my knowledge base right now. Let's focus on one small, doable action: what is a tiny habit you can start today?"
    }
    throw new Error(`AI API error: ${response.status} ${response.statusText}`)
  }

  const data = await response.json()

  if (aiModel.startsWith('gpt')) {
    return data.choices[0]?.message?.content || 'I apologize, but I cannot respond right now.'
  } else {
    return data.content[0]?.text || 'I apologize, but I cannot respond right now.'
  }
}

// Export functions for testing
export {
  buildDailyContentPrompt,
  chooseTopicForDate,
  parseAIContentResponse,
} from './services/daily-content.service.ts'
