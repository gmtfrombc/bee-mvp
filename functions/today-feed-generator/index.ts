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

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

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

    // Simple rotation for now - can be enhanced with more sophisticated logic
    const dayOfYear = Math.floor((new Date(date).getTime() - new Date(date.substring(0, 4)).getTime()) / (1000 * 60 * 60 * 24))
    const topicIndex = dayOfYear % topics.length

    return topics[topicIndex]
}

/**
 * Generate content using Vertex AI
 */
async function generateContentWithAI(request: ContentGenerationRequest): Promise<ContentGenerationResult> {
    try {
        // For now, we'll create a mock implementation since setting up Vertex AI requires more infrastructure
        // This will be replaced with actual Vertex AI integration in the next tasks
        console.log('Generating AI content for:', request)

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
    } catch (error) {
        console.error('AI content generation error:', error)
        return {
            success: false,
            error: error.message
        }
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