// Today Feed Content Types
export interface TodayFeedContent {
    id?: number
    content_date: string // ISO date string (YYYY-MM-DD)
    title: string // max 60 characters
    summary: string // max 200 characters
    content_url?: string
    external_link?: string
    topic_category: HealthTopic
    ai_confidence_score: number // 0.0 to 1.0
    created_at?: string
    updated_at?: string
}

export type HealthTopic =
    | 'nutrition'
    | 'exercise'
    | 'sleep'
    | 'stress'
    | 'prevention'
    | 'lifestyle'

// Vertex AI Integration Types
export interface ContentGenerationRequest {
    topic: HealthTopic
    date: string
    target_length: number
    tone: 'conversational' | 'educational' | 'motivational'
}

export interface VertexAIResponse {
    title: string
    summary: string
    confidence_score: number
    external_references?: string[]
}

// Content Quality Validation
export interface QualityValidationResult {
    is_valid: boolean
    confidence_score: number
    safety_score: number
    readability_score: number
    engagement_score: number
    issues: string[]
}

// API Response Types
export interface TodayFeedApiResponse {
    success: boolean
    data?: TodayFeedContent
    error?: string
    cached_at?: string
    expires_at?: string
}

export interface ContentGenerationResult {
    success: boolean
    content?: TodayFeedContent
    validation_result?: QualityValidationResult
    error?: string
} 