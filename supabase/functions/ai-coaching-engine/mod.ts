import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { analyzeEngagement } from './personalization/pattern-analysis.ts'
import { derivePersona } from './personalization/coaching-personas.ts'
import { buildPrompt } from './prompt-builder.ts'
import { logConversation, getRecentMessages } from './response-logger.ts'
import { getCachedResponse, setCachedResponse, generateCacheKey } from './middleware/cache.ts'
import { enforceRateLimit, RateLimitError } from './middleware/rate-limit.ts'
import { detectRedFlags } from './middleware/safety/red-flag-detector.ts'
import { analyzeSentiment, type SentimentResult } from './sentiment/sentiment-analyzer.ts'
import { engagementDataService } from './services/engagement-data.ts'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!
const aiApiKey = Deno.env.get('AI_API_KEY')!
const aiModel = Deno.env.get('AI_MODEL') || 'claude-3-haiku-20240307'

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
            headers: corsHeaders
        })
    }

    const startTime = Date.now()

    try {
        // Parse request
        const body: GenerateResponseRequest = await req.json()
        const { user_id, message, momentum_state = 'Steady', system_event, previous_state, current_score } = body

        if (!user_id || !message) {
            return new Response(
                JSON.stringify({ error: 'Missing required fields: user_id, message' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
                    message: 'Message contains content that requires special handling'
                }),
                {
                    status: 403,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                }
            )
        }

        // Extract auth token
        const authToken = req.headers.get('Authorization')?.replace('Bearer ', '')
        if (!authToken) {
            return new Response(
                JSON.stringify({ error: 'Missing authorization token' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Check if this is a system event with service role key
        const isSystemEvent = req.headers.get('X-System-Event') === 'true'
        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

        if (isSystemEvent && authToken === serviceRoleKey) {
            // Allow system events with service role key
            console.log(`System event authenticated for user: ${user_id}`)
        } else {
            // Validate JWT for regular user requests
            const supabase = createClient(supabaseUrl, supabaseKey)
            const { data: user, error: authError } = await supabase.auth.getUser(authToken)
            if (authError || !user?.user || user.user.id !== user_id) {
                return new Response(
                    JSON.stringify({ error: 'Unauthorized' }),
                    { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
                )
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
                            retryAfter: error.retryAfter
                        }),
                        {
                            status: 429,
                            headers: {
                                ...corsHeaders,
                                'Content-Type': 'application/json',
                                'Retry-After': error.retryAfter?.toString() || '60'
                            }
                        }
                    )
                }
                throw error // Re-throw if not a rate limit error
            }
        }



        // Log user message first (handle system events differently)
        if (system_event === 'momentum_change') {
            await logConversation(user_id, 'system', `Momentum changed from ${previous_state} to ${momentum_state}`, undefined, authToken)
        } else {
            await logConversation(user_id, 'user', message, undefined, authToken)
        }

        // Fetch recent conversation history
        const conversationHistory = await getRecentMessages(user_id, 20, authToken)

        // Analyze user engagement patterns using real data
        const engagementEvents = await engagementDataService.getUserEngagementEvents(user_id, authToken)
        const patternSummary = analyzeEngagement(engagementEvents)

        // Analyze sentiment of user message (skip for system events)
        let sentimentResult: SentimentResult | null = null
        if (system_event !== 'momentum_change') {
            sentimentResult = await analyzeSentiment(message)
            console.log(`Sentiment analyzed for user ${user_id}: ${sentimentResult.label} (${sentimentResult.score.toFixed(2)})`)
        }

        // Derive coaching persona
        const persona = derivePersona(patternSummary, momentum_state)

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
                promptMessage = `I noticed your momentum has shifted from ${previous_state} to ${momentum_state}. Let me offer some personalized guidance to help you with this transition.`
            }

            const prompt = await buildPrompt(
                promptMessage,
                persona,
                patternSummary,
                momentum_state,
                conversationHistory,
                system_event === 'momentum_change' ? {
                    isSystemEvent: true,
                    previousState: previous_state,
                    currentScore: current_score
                } : undefined,
                sentimentResult
            )

            // Call AI API
            assistantMessage = await callAIAPI(prompt)

            // Cache the response (shorter TTL for system events)
            const cacheTTL = system_event === 'momentum_change' ? 5 * 60 : 15 * 60 // 5 or 15 minutes
            await setCachedResponse(cacheKey, assistantMessage, cacheTTL)
        }

        // Log assistant response
        await logConversation(user_id, 'assistant', assistantMessage, persona, authToken)

        const responseTime = Date.now() - startTime

        const response: GenerateResponseResponse = {
            assistant_message: assistantMessage,
            persona,
            response_time_ms: responseTime,
            cache_hit: cacheHit
        }

        return new Response(
            JSON.stringify(response),
            {
                status: 200,
                headers: {
                    ...corsHeaders,
                    'Content-Type': 'application/json',
                    'X-Cache-Status': cacheHit ? 'HIT' : 'MISS'
                }
            }
        )

    } catch (error) {
        console.error('Error in AI coaching handler:', error)
        return new Response(
            JSON.stringify({
                error: 'Internal server error',
                message: error instanceof Error ? error.message : 'Unknown error'
            }),
            {
                status: 500,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            }
        )
    }
}



/**
 * Call the AI API with the constructed prompt
 * TODO: Abstract this model selection logic into prompt-builder.ts for tiered pricing
 */
async function callAIAPI(prompt: any[]): Promise<string> {
    const apiUrl = aiModel.startsWith('gpt')
        ? 'https://api.openai.com/v1/chat/completions'
        : 'https://api.anthropic.com/v1/messages'

    const headers: Record<string, string> = {
        'Content-Type': 'application/json',
    }

    let body: any

    if (aiModel.startsWith('gpt')) {
        // OpenAI format
        headers['Authorization'] = `Bearer ${aiApiKey}`
        body = {
            model: aiModel,
            messages: prompt,
            max_tokens: 200,
            temperature: 0.7
        }
    } else {
        // Anthropic Claude format
        headers['x-api-key'] = aiApiKey
        headers['anthropic-version'] = '2023-06-01'

        body = {
            model: aiModel,
            max_tokens: 200,
            messages: prompt.filter(msg => msg.role !== 'system'),
            system: prompt.find(msg => msg.role === 'system')?.content || ''
        }
    }

    const response = await fetch(apiUrl, {
        method: 'POST',
        headers,
        body: JSON.stringify(body)
    })

    if (!response.ok) {
        throw new Error(`AI API error: ${response.status} ${response.statusText}`)
    }

    const data = await response.json()

    if (aiModel.startsWith('gpt')) {
        return data.choices[0]?.message?.content || 'I apologize, but I cannot respond right now.'
    } else {
        return data.content[0]?.text || 'I apologize, but I cannot respond right now.'
    }
} 