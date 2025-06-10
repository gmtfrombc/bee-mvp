export interface AIMessage {
  role: 'system' | 'user' | 'assistant'
  content: string
}

// Request/response DTOs used across controllers
export interface DailyContentRequest {
  content_date: string
  topic_category?: string
  force_regenerate?: boolean
}

export interface GeneratedContent {
  title: string
  summary: string
  topic_category: string
  confidence_score: number
  content_url?: string
  external_link?: string
}

export interface GenerateResponseRequest {
  user_id: string
  message: string
  momentum_state?: string
  system_event?: string
  previous_state?: string
  current_score?: number
}

export interface GenerateResponseResponse {
  assistant_message: string
  persona: string
  response_time_ms: number
  cache_hit: boolean
}
