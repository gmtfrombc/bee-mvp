import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
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
import { ContentSafetyValidator } from './safety/content-safety-validator.ts'
import { CrossPatientPatternsService } from './personalization/cross-patient-patterns.ts'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')
const aiApiKey = Deno.env.get('AI_API_KEY')!
const aiModel = Deno.env.get('AI_MODEL') || 'gpt-4o'
console.log(`🤖 AI model selected: ${aiModel}`)

// Initialize effectiveness tracking system (with null checks for tests and testing environment)
const isTestingEnvironment = Deno.env.get('DENO_TESTING') === 'true'
const effectivenessTracker = (supabaseUrl && supabaseKey && !isTestingEnvironment)
  ? new EffectivenessTracker(supabaseUrl, supabaseKey)
  : null
const strategyOptimizer = effectivenessTracker ? new StrategyOptimizer(effectivenessTracker) : null
const frequencyOptimizer = (supabaseUrl && supabaseKey && !isTestingEnvironment)
  ? new FrequencyOptimizer(supabaseUrl, supabaseKey)
  : null

// Initialize cross-patient patterns service for Epic 3.1 preparation
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const crossPatientService = (supabaseUrl && supabaseKey && serviceRoleKey && !isTestingEnvironment)
  ? new CrossPatientPatternsService(
    createClient(supabaseUrl, serviceRoleKey),
  )
  : null

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

/**
 * Generate daily health content using AI
 */
async function generateDailyHealthContent(
  contentDate: string,
  requestedTopic?: string,
): Promise<GeneratedContent | null> {
  try {
    // Define health topic categories and prompts
    const healthTopics = [
      'nutrition',
      'exercise',
      'sleep',
      'stress',
      'prevention',
      'lifestyle',
    ]

    // Choose topic (either requested or rotate through topics)
    const topicCategory = requestedTopic || chooseTopicForDate(contentDate, healthTopics)

    // Generate content prompt based on topic
    const prompt = buildDailyContentPrompt(topicCategory, contentDate)

    // Call AI API to generate content
    const aiResponse = await callAIAPI(prompt)

    if (!aiResponse) {
      throw new Error('No response from AI API')
    }

    // Parse AI response and extract structured content
    const parsedContent = parseAIContentResponse(aiResponse, topicCategory)

    if (!parsedContent) {
      throw new Error('Failed to parse AI response')
    }

    // Validate content safety
    const safetyResult = ContentSafetyValidator.validateContent(
      parsedContent.title,
      parsedContent.summary,
      topicCategory,
    )

    console.log(`🛡️ Safety validation for ${topicCategory} content:`, safetyResult)

    // If content is unsafe, use safe fallback
    if (!safetyResult.is_safe || safetyResult.requires_review) {
      console.log(
        `⚠️ Content flagged as unsafe, using safe fallback. Issues: ${
          safetyResult.flagged_issues.join(', ')
        }`,
      )
      const safeFallback = ContentSafetyValidator.generateSafeFallback(
        topicCategory,
      )

      return {
        title: safeFallback.title,
        summary: safeFallback.summary,
        topic_category: topicCategory,
        confidence_score: 0.7, // Lower confidence for fallback content
        content_url: undefined,
        external_link: undefined,
      }
    }

    return {
      ...parsedContent,
      confidence_score: Math.min(
        calculateContentConfidence(parsedContent, topicCategory),
        safetyResult.safety_score, // Cap confidence by safety score
      ),
    }
  } catch (error) {
    console.error('Error generating daily health content:', error)
    return null
  }
}

/**
 * Choose topic for a given date (deterministic rotation)
 */
function chooseTopicForDate(contentDate: string, topics: string[]): string {
  const date = new Date(contentDate)
  const dayOfYear = Math.floor(
    (date.getTime() - new Date(date.getFullYear(), 0, 0).getTime()) / (1000 * 60 * 60 * 24),
  )
  return topics[dayOfYear % topics.length]
}

/**
 * Build AI prompt for daily content generation
 */
function buildDailyContentPrompt(topicCategory: string, contentDate: string): AIMessage[] {
  const date = new Date(contentDate)
  const dayName = date.toLocaleDateString('en-US', { weekday: 'long' })
  const monthName = date.toLocaleDateString('en-US', { month: 'long' })

  const systemPrompt =
    `You are a health and wellness content writer creating daily tips for a mobile health app. 

IMPORTANT SAFETY GUIDELINES:
- Never provide medical advice or diagnose conditions
- Always recommend consulting healthcare professionals for medical concerns
- Focus on general wellness and lifestyle tips
- Avoid claims about curing or treating diseases
- Use evidence-based information when possible

Your task is to create engaging, actionable health content for the topic: ${topicCategory}

Today is ${dayName}, ${monthName} ${date.getDate()}.

Please respond with a JSON object in this exact format:
{
  "title": "Engaging headline (max 60 characters)",
  "summary": "Brief, actionable summary (max 200 characters)",
  "key_points": ["Point 1", "Point 2", "Point 3"]
}

The content should be:
- Practical and actionable
- Appropriate for general audiences
- Evidence-based but accessible
- Motivational and positive
- Safe and not prescriptive`

  const userPrompt =
    `Generate daily health content for ${topicCategory} that users can apply today. Make it relevant for a ${dayName} and include specific, actionable advice.`

  return [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: userPrompt },
  ]
}

/**
 * Parse AI response and extract structured content
 */
function parseAIContentResponse(
  aiResponse: string,
  topicCategory: string,
): Omit<GeneratedContent, 'confidence_score'> | null {
  try {
    // Try to extract JSON from the response
    let jsonMatch = aiResponse.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      // If no JSON found, try to parse the entire response
      jsonMatch = [aiResponse]
    }

    const parsed = JSON.parse(jsonMatch[0])

    // Validate required fields
    if (!parsed.title || !parsed.summary) {
      throw new Error('Missing required fields in AI response')
    }

    // Ensure title and summary are within limits
    const title = parsed.title.substring(0, 60)
    const summary = parsed.summary.substring(0, 200)

    return {
      title,
      summary,
      topic_category: topicCategory,
      content_url: undefined,
      external_link: undefined,
    }
  } catch (error) {
    console.error('Error parsing AI content response:', error)

    // Fallback: create content from raw AI response
    const lines = aiResponse.split('\n').filter((line) => line.trim())
    const title = lines[0]?.substring(0, 60) || `Daily ${topicCategory} Tip`
    const summary = lines.slice(1, 3).join(' ').substring(0, 200) ||
      'Focus on improving your health today.'

    return {
      title,
      summary,
      topic_category: topicCategory,
      content_url: undefined,
      external_link: undefined,
    }
  }
}

/**
 * Calculate confidence score for generated content
 */
function calculateContentConfidence(
  content: Omit<GeneratedContent, 'confidence_score'>,
  topicCategory: string,
): number {
  let confidence = 0.7 // Base confidence

  // Check title quality
  if (content.title.length >= 20 && content.title.length <= 60) {
    confidence += 0.1
  }

  // Check summary quality
  if (content.summary.length >= 50 && content.summary.length <= 200) {
    confidence += 0.1
  }

  // Check for topic relevance (simple keyword check)
  const topicKeywords: Record<string, string[]> = {
    'nutrition': ['food', 'eat', 'diet', 'nutrition', 'meal', 'vitamin', 'nutrient'],
    'exercise': ['exercise', 'workout', 'fitness', 'movement', 'activity', 'strength', 'cardio'],
    'sleep': ['sleep', 'rest', 'bedtime', 'morning', 'dream', 'tired', 'energy'],
    'stress': ['stress', 'anxiety', 'calm', 'relax', 'mindful', 'peace', 'tension'],
    'prevention': ['prevent', 'avoid', 'protect', 'health', 'immune', 'wellness', 'safety'],
    'lifestyle': ['lifestyle', 'habit', 'routine', 'balance', 'wellness', 'daily', 'healthy'],
  }

  const keywords = topicKeywords[topicCategory] || []
  const text = `${content.title} ${content.summary}`.toLowerCase()
  const keywordMatches = keywords.filter((keyword: string) => text.includes(keyword)).length

  if (keywordMatches >= 2) {
    confidence += 0.1
  }

  return Math.min(confidence, 1.0)
}

/**
 * Main HTTP handler for the AI coaching engine
 */
export default async function handler(req: Request): Promise<Response> {
  // Enable CORS
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  }

  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', {
      status: 405,
      headers: corsHeaders,
    })
  }

  // Parse URL to determine endpoint
  const url = new URL(req.url)
  const pathname = url.pathname

  // Route to daily content generation endpoint
  if (pathname.endsWith('/generate-daily-content')) {
    return await handleGenerateDailyContent(req, corsHeaders)
  }

  // Route to frequency optimization endpoint
  if (pathname.endsWith('/optimize-frequency')) {
    return await handleFrequencyOptimization(req, corsHeaders)
  }

  // Route to cross-patient pattern aggregation endpoint (Epic 3.1 preparation)
  if (pathname.endsWith('/aggregate-patterns')) {
    return await handlePatternAggregation(req, corsHeaders)
  }

  // Default to conversation handling
  return await handleConversation(req, corsHeaders)
}

/**
 * Handle daily content generation requests
 */
async function handleGenerateDailyContent(
  req: Request,
  corsHeaders: Record<string, string>,
): Promise<Response> {
  const startTime = Date.now()

  try {
    // Parse request - simpler structure for daily content generation
    const body = await req.json()
    const { content_date, topic_category, force_regenerate = false } = body

    if (!content_date) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: content_date' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Validate service role authentication for system operations
    const authToken = req.headers.get('Authorization')?.replace('Bearer ', '')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (authToken !== serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized: Service role key required for content generation' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Initialize Supabase client with service role (skip in test environment)
    if (isTestingEnvironment) {
      throw new Error('Daily content generation not supported in test environment')
    }
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error('Missing Supabase configuration')
    }
    const supabase = createClient(supabaseUrl, serviceRoleKey)

    // Check if content already exists for this date (unless force regenerate)
    if (!force_regenerate) {
      const { data: existingContent } = await supabase
        .from('daily_feed_content')
        .select('*')
        .eq('content_date', content_date)
        .single()

      if (existingContent) {
        return new Response(
          JSON.stringify({
            success: true,
            message: 'Content already exists for this date',
            content: existingContent,
            generated: false,
            response_time_ms: Date.now() - startTime,
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    }

    // Generate new content using AI
    const generatedContent = await generateDailyHealthContent(content_date, topic_category)

    if (!generatedContent) {
      throw new Error('Failed to generate content')
    }

    // Store content in database
    const { data: savedContent, error: saveError } = await supabase
      .from('daily_feed_content')
      .upsert({
        content_date,
        title: generatedContent.title,
        summary: generatedContent.summary,
        topic_category: generatedContent.topic_category,
        ai_confidence_score: generatedContent.confidence_score,
        content_url: generatedContent.content_url,
        external_link: generatedContent.external_link,
      }, {
        onConflict: 'content_date',
      })
      .select()
      .single()

    if (saveError) {
      throw new Error(`Failed to save content: ${saveError.message}`)
    }

    console.log(`✅ Daily content generated and saved for ${content_date}`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Daily content generated successfully',
        content: savedContent,
        generated: true,
        response_time_ms: Date.now() - startTime,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    console.error('Error generating daily content:', error)
    return new Response(
      JSON.stringify({
        error: 'Failed to generate daily content',
        message: error instanceof Error ? error.message : 'Unknown error',
        response_time_ms: Date.now() - startTime,
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
}

/**
 * Handle frequency optimization requests
 */
async function handleFrequencyOptimization(
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
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

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
async function handlePatternAggregation(
  req: Request,
  corsHeaders: Record<string, string>,
): Promise<Response> {
  const startTime = Date.now()

  try {
    // Parse request
    const body = await req.json()
    const { week_start, force_regenerate = false, operation = 'weekly_aggregation' } = body

    // Validate service role authentication for system operations
    const authToken = req.headers.get('Authorization')?.replace('Bearer ', '')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

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
async function handleConversation(
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
          if (!supabaseUrl || !supabaseKey) {
            return new Response(
              JSON.stringify({ error: 'Internal server error' }),
              { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
            )
          }
          const supabase = createClient(supabaseUrl, supabaseKey)
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
  generateDailyHealthContent,
  parseAIContentResponse,
}
