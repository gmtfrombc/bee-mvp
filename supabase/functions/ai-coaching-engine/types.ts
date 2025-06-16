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
  /** Optional rich JSON payload shown in Flutter app */
  full_content?: unknown
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

export interface WearableData {
  timestamp: number
  heart_rate: number
  resting_heart_rate?: number
  steps: number
  sleep_hours: number
  /** 0.0–1.0 where higher means more stress */
  stress_level?: number
}

export interface JITAITrigger {
  id: string
  type: 'encourage_activity' | 'relaxation_breath' | 'hydration_reminder' | 'sleep_hygiene'
  message: string
}
