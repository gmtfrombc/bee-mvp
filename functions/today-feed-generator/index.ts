import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import {
    TodayFeedContent,
    HealthTopic,
    ContentGenerationRequest,
    VertexAIResponse,
    QualityValidationResult,
    TodayFeedApiResponse,
    ContentGenerationResult
} from './types.d.ts'

// Environment configuration
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const GCP_PROJECT_ID = Deno.env.get('GCP_PROJECT_ID')!
const VERTEX_AI_LOCATION = Deno.env.get('VERTEX_AI_LOCATION') || 'us-central1'
const GOOGLE_APPLICATION_CREDENTIALS = Deno.env.get('GOOGLE_APPLICATION_CREDENTIALS')!

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

// Vertex AI configuration
const VERTEX_AI_CONFIG = {
    model: 'text-bison@002',
    temperature: 0.7,
    max_output_tokens: 300,
    top_p: 0.8,
    top_k: 40,
}

/**
 * Main HTTP handler for the Today Feed Content Generation service
 */
async function handler(req: Request): Promise<Response> {
    const url = new URL(req.url)
    const path = url.pathname

    // CORS headers
    const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    }

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        return new Response(null, { headers: corsHeaders })
    }

    try {
        let response: Response

        switch (path) {
            case '/health':
                response = await handleHealthCheck()
                break
            case '/generate':
                response = await handleContentGeneration(req)
                break
            case '/current':
                response = await handleGetCurrentContent()
                break
            case '/validate':
                response = await handleContentValidation(req)
                break
            default:
                response = new Response(
                    JSON.stringify({ error: 'Not found' }),
                    { status: 404, headers: { 'Content-Type': 'application/json' } }
                )
        }

        // Add CORS headers to response
        Object.entries(corsHeaders).forEach(([key, value]) => {
            response.headers.set(key, value)
        })

        return response
    } catch (error) {
        console.error('Request handler error:', error)
        return new Response(
            JSON.stringify({
                success: false,
                error: 'Internal server error',
                details: error.message
            }),
            {
                status: 500,
                headers: {
                    'Content-Type': 'application/json',
                    ...corsHeaders
                }
            }
        )
    }
}

/**
 * Health check endpoint
 */
async function handleHealthCheck(): Promise<Response> {
    return new Response(
        JSON.stringify({
            status: 'healthy',
            service: 'today-feed-generator',
            timestamp: new Date().toISOString(),
            version: '1.0.0'
        }),
        {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
        }
    )
}

/**
 * Generate new content using Vertex AI
 */
async function handleContentGeneration(req: Request): Promise<Response> {
    if (req.method !== 'POST') {
        return new Response(
            JSON.stringify({ error: 'Method not allowed' }),
            { status: 405, headers: { 'Content-Type': 'application/json' } }
        )
    }

    try {
        const body = await req.json()
        const { topic, date } = body as { topic?: HealthTopic, date?: string }

        // Use current date if not provided
        const contentDate = date || new Date().toISOString().split('T')[0]

        // Select topic if not provided
        const selectedTopic = topic || await selectDailyTopic(contentDate)

        console.log(`Generating content for topic: ${selectedTopic}, date: ${contentDate}`)

        // Generate content using Vertex AI
        const generationResult = await generateContentWithAI({
            topic: selectedTopic,
            date: contentDate,
            target_length: 200,
            tone: 'conversational'
        })

        if (!generationResult.success) {
            return new Response(
                JSON.stringify(generationResult),
                { status: 500, headers: { 'Content-Type': 'application/json' } }
            )
        }

        return new Response(
            JSON.stringify(generationResult),
            { status: 200, headers: { 'Content-Type': 'application/json' } }
        )
    } catch (error) {
        console.error('Content generation error:', error)
        return new Response(
            JSON.stringify({
                success: false,
                error: 'Failed to generate content',
                details: error.message
            }),
            { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
    }
}

/**
 * Get current day's content
 */
async function handleGetCurrentContent(): Promise<Response> {
    try {
        const today = new Date().toISOString().split('T')[0]

        const { data, error } = await supabase
            .from('daily_feed_content')
            .select('*')
            .eq('content_date', today)
            .single()

        if (error && error.code !== 'PGRST116') {
            throw error
        }

        const response: TodayFeedApiResponse = {
            success: true,
            data: data || undefined,
            cached_at: new Date().toISOString(),
            expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
        }

        return new Response(
            JSON.stringify(response),
            { status: 200, headers: { 'Content-Type': 'application/json' } }
        )
    } catch (error) {
        console.error('Get current content error:', error)
        return new Response(
            JSON.stringify({
                success: false,
                error: 'Failed to retrieve content',
                details: error.message
            }),
            { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
    }
}

/**
 * Validate content quality
 */
async function handleContentValidation(req: Request): Promise<Response> {
    if (req.method !== 'POST') {
        return new Response(
            JSON.stringify({ error: 'Method not allowed' }),
            { status: 405, headers: { 'Content-Type': 'application/json' } }
        )
    }

    try {
        const content = await req.json() as TodayFeedContent
        const validationResult = await validateContentQuality(content)

        return new Response(
            JSON.stringify(validationResult),
            { status: 200, headers: { 'Content-Type': 'application/json' } }
        )
    } catch (error) {
        console.error('Content validation error:', error)
        return new Response(
            JSON.stringify({
                success: false,
                error: 'Failed to validate content',
                details: error.message
            }),
            { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
    }
}

/**
 * Intelligent topic selection based on multiple factors
 */
async function selectDailyTopic(date: string): Promise<HealthTopic> {
    const topics: HealthTopic[] = ['nutrition', 'exercise', 'sleep', 'stress', 'prevention', 'lifestyle']

    try {
        // Get recent topic history to ensure diversity
        const recentTopics = await getRecentTopicHistory(date, 7) // Last 7 days

        // Get user engagement data for topic preferences
        const topicEngagement = await getTopicEngagementData(30) // Last 30 days

        // Calculate topic scores based on multiple factors
        const topicScores = await calculateTopicScores(topics, date, recentTopics, topicEngagement)

        // Select topic with highest score
        const selectedTopic = selectBestTopic(topicScores)

        console.log(`Selected topic: ${selectedTopic} for date ${date}`)
        console.log('Topic scores:', topicScores)

        return selectedTopic
    } catch (error) {
        console.error('Error in intelligent topic selection:', error)

        // Fallback to enhanced rotation (better than simple day rotation)
        return getFallbackTopic(date, topics)
    }
}

/**
 * Get recent topic history to ensure diversity
 */
async function getRecentTopicHistory(currentDate: string, days: number): Promise<HealthTopic[]> {
    try {
        const endDate = new Date(currentDate)
        const startDate = new Date(endDate)
        startDate.setDate(startDate.getDate() - days)

        const { data, error } = await supabase
            .from('daily_feed_content')
            .select('topic_category')
            .gte('content_date', startDate.toISOString().split('T')[0])
            .lt('content_date', currentDate)
            .order('content_date', { ascending: false })

        if (error) {
            console.warn('Could not fetch recent topics:', error)
            return []
        }

        return data?.map(row => row.topic_category as HealthTopic) || []
    } catch (error) {
        console.warn('Error fetching recent topics:', error)
        return []
    }
}

/**
 * Get user engagement data for topic preferences
 */
async function getTopicEngagementData(days: number): Promise<Record<HealthTopic, number>> {
    try {
        const cutoffDate = new Date()
        cutoffDate.setDate(cutoffDate.getDate() - days)

        const { data, error } = await supabase
            .from('user_content_interactions')
            .select(`
                daily_feed_content!inner(topic_category),
                interaction_type,
                session_duration
            `)
            .gte('interaction_timestamp', cutoffDate.toISOString())
            .in('interaction_type', ['view', 'click'])

        if (error) {
            console.warn('Could not fetch engagement data:', error)
            return {}
        }

        // Calculate engagement scores by topic
        const topicEngagement: Record<HealthTopic, number> = {
            nutrition: 0,
            exercise: 0,
            sleep: 0,
            stress: 0,
            prevention: 0,
            lifestyle: 0
        }

        data?.forEach(interaction => {
            const topic = interaction.daily_feed_content.topic_category as HealthTopic
            // Weight clicks higher than views, and consider session duration
            const score = interaction.interaction_type === 'click' ? 2 : 1
            const durationBonus = Math.min((interaction.session_duration || 0) / 60, 2) // Up to 2x bonus for reading time
            topicEngagement[topic] += score * (1 + durationBonus)
        })

        return topicEngagement
    } catch (error) {
        console.warn('Error fetching engagement data:', error)
        return {}
    }
}

/**
 * Calculate comprehensive topic scores based on multiple factors
 */
async function calculateTopicScores(
    topics: HealthTopic[],
    date: string,
    recentTopics: HealthTopic[],
    engagement: Record<HealthTopic, number>
): Promise<Record<HealthTopic, number>> {
    const scores: Record<HealthTopic, number> = {}
    const dateObj = new Date(date)
    const month = dateObj.getMonth() + 1 // 1-12
    const dayOfWeek = dateObj.getDay() // 0-6 (Sunday-Saturday)

    for (const topic of topics) {
        let score = 1.0 // Base score

        // 1. Diversity Factor: Penalize recently used topics
        const daysSinceLastUsed = getLastUsedDays(topic, recentTopics)
        if (daysSinceLastUsed === 0) {
            score *= 0.1 // Heavy penalty for yesterday's topic
        } else if (daysSinceLastUsed === 1) {
            score *= 0.3 // Moderate penalty for topic used 2 days ago
        } else if (daysSinceLastUsed <= 3) {
            score *= 0.7 // Light penalty for recently used topics
        } else {
            score *= 1.2 // Slight bonus for topics not used recently
        }

        // 2. User Engagement Factor: Boost topics users engage with more
        const engagementScore = engagement[topic] || 0
        const maxEngagement = Math.max(...Object.values(engagement), 1)
        const engagementMultiplier = 0.5 + (engagementScore / maxEngagement) * 1.5 // 0.5x to 2.0x
        score *= engagementMultiplier

        // 3. Seasonal Relevance Factor
        score *= getSeasonalRelevance(topic, month)

        // 4. Day of Week Factor
        score *= getDayOfWeekRelevance(topic, dayOfWeek)

        // 5. Randomization Factor: Add some controlled randomness (±20%)
        const randomFactor = 0.8 + Math.random() * 0.4
        score *= randomFactor

        scores[topic] = score
    }

    return scores
}

/**
 * Get days since topic was last used
 */
function getLastUsedDays(topic: HealthTopic, recentTopics: HealthTopic[]): number {
    const index = recentTopics.indexOf(topic)
    return index === -1 ? 30 : index // Return high number if not found recently
}

/**
 * Get seasonal relevance multiplier for topics
 */
function getSeasonalRelevance(topic: HealthTopic, month: number): number {
    // Seasonal adjustments based on typical health patterns
    const seasonalWeights: Record<HealthTopic, Record<string, number>> = {
        exercise: {
            'winter': 1.3, // New Year fitness resolutions (Jan-Feb)
            'spring': 1.2, // Spring activity increase (Mar-May)
            'summer': 0.9, // People more active naturally (Jun-Aug)
            'fall': 1.1    // Back to routine (Sep-Dec)
        },
        nutrition: {
            'winter': 1.1, // Holiday eating awareness
            'spring': 1.3, // Spring detox/fresh starts
            'summer': 1.2, // Fresh produce season
            'fall': 1.0    // Baseline
        },
        sleep: {
            'winter': 1.2, // Longer nights, sleep hygiene focus
            'spring': 1.0, // Baseline
            'summer': 0.9, // Longer days affect sleep
            'fall': 1.1    // Back to routine
        },
        stress: {
            'winter': 1.3, // Holiday stress, seasonal depression
            'spring': 1.0, // Baseline
            'summer': 0.8, // Generally lower stress
            'fall': 1.2    // Back to school/work stress
        },
        prevention: {
            'winter': 1.2, // Flu season awareness
            'spring': 1.1, // Health checkup reminders
            'summer': 0.9, // Less health focus
            'fall': 1.3    // Annual checkups, flu shots
        },
        lifestyle: {
            'winter': 1.0, // Baseline
            'spring': 1.2, // Spring cleaning, new habits
            'summer': 1.1, // Outdoor activities
            'fall': 1.1    // Routine establishment
        }
    }

    let season: string
    if (month >= 12 || month <= 2) season = 'winter'
    else if (month >= 3 && month <= 5) season = 'spring'
    else if (month >= 6 && month <= 8) season = 'summer'
    else season = 'fall'

    return seasonalWeights[topic][season] || 1.0
}

/**
 * Get day of week relevance multiplier
 */
function getDayOfWeekRelevance(topic: HealthTopic, dayOfWeek: number): number {
    // Day of week patterns (0=Sunday, 6=Saturday)
    const dayWeights: Record<HealthTopic, number[]> = {
        exercise: [1.2, 1.3, 1.1, 1.1, 1.1, 0.8, 0.9], // Higher on Mon/Tue (workout motivation)
        nutrition: [1.3, 1.2, 1.0, 1.0, 0.9, 0.8, 1.1], // Higher on Sun/Mon (meal prep)
        sleep: [1.1, 0.9, 1.0, 1.0, 1.0, 1.2, 1.3], // Higher on weekends (sleep recovery)
        stress: [1.2, 1.3, 1.1, 1.1, 1.2, 0.8, 0.9], // Higher on Mon/Tue/Fri (work stress)
        prevention: [1.0, 1.1, 1.0, 1.0, 1.0, 1.0, 1.0], // Consistent throughout week
        lifestyle: [1.2, 1.0, 1.0, 1.0, 1.0, 1.1, 1.3] // Higher on weekends (habit focus)
    }

    return dayWeights[topic][dayOfWeek] || 1.0
}

/**
 * Select the best topic based on calculated scores
 */
function selectBestTopic(scores: Record<HealthTopic, number>): HealthTopic {
    let bestTopic: HealthTopic = 'nutrition'
    let bestScore = 0

    for (const [topic, score] of Object.entries(scores)) {
        if (score > bestScore) {
            bestScore = score
            bestTopic = topic as HealthTopic
        }
    }

    return bestTopic
}

/**
 * Fallback topic selection with enhanced rotation
 */
function getFallbackTopic(date: string, topics: HealthTopic[]): HealthTopic {
    const dateObj = new Date(date)
    const dayOfYear = Math.floor((dateObj.getTime() - new Date(dateObj.getFullYear(), 0, 0).getTime()) / (1000 * 60 * 60 * 24))

    // Enhanced rotation: Use a pattern that avoids simple sequential order
    const rotationPattern = [0, 3, 1, 4, 2, 5] // nutrition, stress, exercise, prevention, sleep, lifestyle
    const patternIndex = dayOfYear % rotationPattern.length
    const topicIndex = rotationPattern[patternIndex]

    return topics[topicIndex]
}

/**
 * Generate content using Vertex AI
 */
async function generateContentWithAI(request: ContentGenerationRequest): Promise<ContentGenerationResult> {
    try {
        console.log('Generating AI content for:', request)

        // Get Google Cloud access token
        const accessToken = await getGoogleCloudAccessToken()

        // Generate content using Vertex AI
        const aiContent = await callVertexAI(request, accessToken)

        if (!aiContent) {
            // Fallback to mock content if AI generation fails
            console.warn('Vertex AI generation failed, falling back to mock content')
            const mockContent = await generateMockContent(request)
            const validationResult = await validateContentQuality(mockContent)

            if (!validationResult.is_valid) {
                return {
                    success: false,
                    error: 'Generated content failed quality validation',
                    validation_result: validationResult
                }
            }

            // Store content in database
            const { data, error } = await supabase
                .from('daily_feed_content')
                .upsert([mockContent])
                .select()
                .single()

            if (error) {
                throw error
            }

            return {
                success: true,
                content: data,
                validation_result: validationResult
            }
        }

        // Create TodayFeedContent from AI response
        const content: TodayFeedContent = {
            content_date: request.date,
            title: aiContent.title,
            summary: aiContent.summary,
            topic_category: request.topic,
            ai_confidence_score: aiContent.confidence_score,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        }

        const validationResult = await validateContentQuality(content)

        if (!validationResult.is_valid) {
            return {
                success: false,
                error: 'Generated content failed quality validation',
                validation_result: validationResult
            }
        }

        // Store content in database
        const { data, error } = await supabase
            .from('daily_feed_content')
            .upsert([content])
            .select()
            .single()

        if (error) {
            throw error
        }

        return {
            success: true,
            content: data,
            validation_result: validationResult
        }
    } catch (error) {
        console.error('AI content generation error:', error)
        return {
            success: false,
            error: error.message
        }
    }
}

/**
 * Get Google Cloud access token for service account authentication
 */
async function getGoogleCloudAccessToken(): Promise<string> {
    try {
        // Read service account credentials from environment
        if (!GOOGLE_APPLICATION_CREDENTIALS) {
            throw new Error('GOOGLE_APPLICATION_CREDENTIALS environment variable not set')
        }

        const credentials = JSON.parse(GOOGLE_APPLICATION_CREDENTIALS)

        // Create JWT for Google Cloud authentication
        const jwt = await createJWTForGoogleCloud(credentials)

        // Exchange JWT for access token
        const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
                grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                assertion: jwt,
            }),
        })

        if (!tokenResponse.ok) {
            throw new Error(`Failed to get access token: ${tokenResponse.status}`)
        }

        const tokenData = await tokenResponse.json()
        return tokenData.access_token
    } catch (error) {
        console.error('Error getting Google Cloud access token:', error)
        throw error
    }
}

/**
 * Create JWT for Google Cloud service account authentication
 */
async function createJWTForGoogleCloud(credentials: any): Promise<string> {
    const header = {
        alg: 'RS256',
        typ: 'JWT',
        kid: credentials.private_key_id,
    }

    const now = Math.floor(Date.now() / 1000)
    const payload = {
        iss: credentials.client_email,
        scope: 'https://www.googleapis.com/auth/cloud-platform',
        aud: 'https://oauth2.googleapis.com/token',
        exp: now + 3600, // 1 hour
        iat: now,
    }

    // Clean and prepare the private key
    const privateKeyPem = credentials.private_key.replace(/\\n/g, '\n')

    // Extract the base64 content from the PEM format
    const privateKeyB64 = privateKeyPem
        .replace(/-----BEGIN PRIVATE KEY-----/, '')
        .replace(/-----END PRIVATE KEY-----/, '')
        .replace(/\s/g, '')

    // Convert base64 to ArrayBuffer
    const privateKeyBytes = Uint8Array.from(atob(privateKeyB64), c => c.charCodeAt(0))

    // Import the private key
    const privateKey = await crypto.subtle.importKey(
        'pkcs8',
        privateKeyBytes.buffer,
        {
            name: 'RSASSA-PKCS1-v1_5',
            hash: 'SHA-256',
        },
        false,
        ['sign']
    )

    // Create the JWT
    const headerBase64 = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
    const payloadBase64 = btoa(JSON.stringify(payload)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
    const signatureInput = `${headerBase64}.${payloadBase64}`

    const signature = await crypto.subtle.sign(
        'RSASSA-PKCS1-v1_5',
        privateKey,
        new TextEncoder().encode(signatureInput)
    )

    const signatureBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
        .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

    return `${signatureInput}.${signatureBase64}`
}

/**
 * Call Vertex AI to generate content
 */
async function callVertexAI(request: ContentGenerationRequest, accessToken: string): Promise<VertexAIResponse | null> {
    try {
        const prompt = createPromptForTopic(request)

        const url = `https://${VERTEX_AI_LOCATION}-aiplatform.googleapis.com/v1/projects/${GCP_PROJECT_ID}/locations/${VERTEX_AI_LOCATION}/publishers/google/models/${VERTEX_AI_CONFIG.model}:predict`

        const requestBody = {
            instances: [
                {
                    prompt: prompt
                }
            ],
            parameters: {
                temperature: VERTEX_AI_CONFIG.temperature,
                maxOutputTokens: VERTEX_AI_CONFIG.max_output_tokens,
                topP: VERTEX_AI_CONFIG.top_p,
                topK: VERTEX_AI_CONFIG.top_k,
            }
        }

        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody),
        })

        if (!response.ok) {
            console.error(`Vertex AI API error: ${response.status} ${response.statusText}`)
            const errorText = await response.text()
            console.error('Error details:', errorText)
            return null
        }

        const data = await response.json()

        if (!data.predictions || data.predictions.length === 0) {
            console.error('No predictions returned from Vertex AI')
            return null
        }

        const prediction = data.predictions[0]
        const content = prediction.content || prediction.text || ''

        if (!content) {
            console.error('No content in Vertex AI prediction')
            return null
        }

        // Parse the AI response to extract title and summary
        const parsedContent = parseAIResponse(content)

        if (!parsedContent) {
            console.error('Failed to parse AI response')
            return null
        }

        return {
            title: parsedContent.title,
            summary: parsedContent.summary,
            confidence_score: prediction.confidence || 0.85, // Default confidence if not provided
            external_references: parsedContent.external_references
        }
    } catch (error) {
        console.error('Error calling Vertex AI:', error)
        return null
    }
}

/**
 * Create prompt for specific health topic
 */
function createPromptForTopic(request: ContentGenerationRequest): string {
    const topicPrompts = {
        nutrition: `Generate an engaging daily health insight about nutrition for a wellness app user.
        
Topic: Nutrition and healthy eating
Target audience: Adults interested in preventive health
Tone: Conversational, encouraging, science-based
Requirements:
- Include one actionable tip
- Reference credible research when relevant  
- Avoid medical advice or diagnoses
- Make it curiosity-driving and engaging
- Title must be under 60 characters
- Summary must be exactly 2 sentences under 200 characters

Format your response as:
Title: [Engaging headline under 60 characters]
Summary: [Exactly 2 sentences under 200 characters with actionable tip]`,

        exercise: `Generate an engaging daily health insight about exercise and physical activity for a wellness app user.
        
Topic: Exercise, movement, and physical activity
Target audience: Adults interested in preventive health
Tone: Conversational, encouraging, science-based
Requirements:
- Include one actionable tip
- Reference credible research when relevant  
- Avoid medical advice or diagnoses
- Make it curiosity-driving and engaging
- Title must be under 60 characters
- Summary must be exactly 2 sentences under 200 characters

Format your response as:
Title: [Engaging headline under 60 characters]
Summary: [Exactly 2 sentences under 200 characters with actionable tip]`,

        sleep: `Generate an engaging daily health insight about sleep and rest for a wellness app user.
        
Topic: Sleep, rest, and recovery
Target audience: Adults interested in preventive health
Tone: Conversational, encouraging, science-based
Requirements:
- Include one actionable tip
- Reference credible research when relevant  
- Avoid medical advice or diagnoses
- Make it curiosity-driving and engaging
- Title must be under 60 characters
- Summary must be exactly 2 sentences under 200 characters

Format your response as:
Title: [Engaging headline under 60 characters]
Summary: [Exactly 2 sentences under 200 characters with actionable tip]`,

        stress: `Generate an engaging daily health insight about stress management and mental health for a wellness app user.
        
Topic: Stress management, mindfulness, and mental wellness
Target audience: Adults interested in preventive health
Tone: Conversational, encouraging, science-based
Requirements:
- Include one actionable tip
- Reference credible research when relevant  
- Avoid medical advice or diagnoses
- Make it curiosity-driving and engaging
- Title must be under 60 characters
- Summary must be exactly 2 sentences under 200 characters

Format your response as:
Title: [Engaging headline under 60 characters]
Summary: [Exactly 2 sentences under 200 characters with actionable tip]`,

        prevention: `Generate an engaging daily health insight about preventive care and health screenings for a wellness app user.
        
Topic: Preventive healthcare and early detection
Target audience: Adults interested in preventive health
Tone: Conversational, encouraging, science-based
Requirements:
- Include one actionable tip
- Reference credible research when relevant  
- Avoid medical advice or diagnoses
- Make it curiosity-driving and engaging
- Title must be under 60 characters
- Summary must be exactly 2 sentences under 200 characters

Format your response as:
Title: [Engaging headline under 60 characters]
Summary: [Exactly 2 sentences under 200 characters with actionable tip]`,

        lifestyle: `Generate an engaging daily health insight about healthy lifestyle habits for a wellness app user.
        
Topic: Lifestyle habits, behavior change, and wellness
Target audience: Adults interested in preventive health
Tone: Conversational, encouraging, science-based
Requirements:
- Include one actionable tip
- Reference credible research when relevant  
- Avoid medical advice or diagnoses
- Make it curiosity-driving and engaging
- Title must be under 60 characters
- Summary must be exactly 2 sentences under 200 characters

Format your response as:
Title: [Engaging headline under 60 characters]
Summary: [Exactly 2 sentences under 200 characters with actionable tip]`
    }

    return topicPrompts[request.topic] || topicPrompts.lifestyle
}

/**
 * Parse AI response to extract title and summary
 */
function parseAIResponse(content: string): { title: string; summary: string; external_references?: string[] } | null {
    try {
        // Look for structured format in the response
        const titleMatch = content.match(/Title:\s*(.*?)(?:\n|$)/i)
        const summaryMatch = content.match(/Summary:\s*(.*?)(?:\n|$)/is)

        if (titleMatch && summaryMatch) {
            return {
                title: titleMatch[1].trim(),
                summary: summaryMatch[1].trim().replace(/\n/g, ' ')
            }
        }

        // Fallback: try to extract from unstructured content
        const lines = content.split('\n').filter(line => line.trim().length > 0)

        if (lines.length >= 2) {
            return {
                title: lines[0].trim(),
                summary: lines.slice(1).join(' ').trim()
            }
        }

        return null
    } catch (error) {
        console.error('Error parsing AI response:', error)
        return null
    }
}

/**
 * Mock content generation (to be replaced with Vertex AI)
 */
async function generateMockContent(request: ContentGenerationRequest): Promise<TodayFeedContent> {
    const topicContent = {
        nutrition: {
            title: "The Hidden Power of Colorful Eating",
            summary: "Different colored fruits and vegetables contain unique antioxidants that protect different parts of your body. Aim for a rainbow of colors on your plate each day for optimal health benefits."
        },
        exercise: {
            title: "The 2-Minute Activity Break Miracle",
            summary: "Just 2 minutes of movement every hour can counteract the negative effects of prolonged sitting. Even simple stretches or walking in place counts toward better health."
        },
        sleep: {
            title: "The 90-Minute Sleep Cycle Secret",
            summary: "Your brain naturally cycles through sleep stages every 90 minutes. Timing your wake-up to align with these cycles can help you feel more refreshed and energized."
        },
        stress: {
            title: "Why Deep Breathing Actually Works",
            summary: "Deep breathing activates your parasympathetic nervous system, which literally tells your body to calm down. Just 4-7-8 breathing can reduce stress hormones within minutes."
        },
        prevention: {
            title: "The Simple Screening That Saves Lives",
            summary: "Regular blood pressure checks can detect hypertension before symptoms appear. This silent condition affects 1 in 3 adults but is easily managed when caught early."
        },
        lifestyle: {
            title: "The 21-Day Habit Formation Myth",
            summary: "Research shows it actually takes an average of 66 days to form a new habit. Understanding this timeline helps set realistic expectations for lasting change."
        }
    }

    const content = topicContent[request.topic]

    return {
        content_date: request.date,
        title: content.title,
        summary: content.summary,
        topic_category: request.topic,
        ai_confidence_score: 0.85, // Mock confidence score
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
    }
}

/**
 * Content quality validation
 */
async function validateContentQuality(content: TodayFeedContent): Promise<QualityValidationResult> {
    const issues: string[] = []

    // Title length validation
    if (content.title.length > 60) {
        issues.push('Title exceeds 60 character limit')
    }

    // Summary length validation
    if (content.summary.length > 200) {
        issues.push('Summary exceeds 200 character limit')
    }

    // Basic content safety checks
    const prohibitedTerms = ['diagnose', 'prescription', 'cure', 'treatment']
    const contentText = (content.title + ' ' + content.summary).toLowerCase()

    prohibitedTerms.forEach(term => {
        if (contentText.includes(term)) {
            issues.push(`Contains prohibited medical term: ${term}`)
        }
    })

    // Calculate scores (simplified for mock implementation)
    const confidence_score = content.ai_confidence_score || 0.8
    const safety_score = issues.length === 0 ? 0.95 : 0.5
    const readability_score = 0.85 // Mock readability score
    const engagement_score = 0.8 // Mock engagement score

    return {
        is_valid: issues.length === 0 && confidence_score >= 0.7,
        confidence_score,
        safety_score,
        readability_score,
        engagement_score,
        issues
    }
}

// Start the server
console.log('Starting Today Feed Content Generation service...')
serve(handler, { port: 8080 }) 