// Type definitions for Real-time Momentum Sync Edge Function
// Epic: 1.1 · Momentum Meter
// Task: T1.1.2.7 · Implement real-time triggers for momentum updates

declare global {
    namespace Deno {
        interface Env {
            SUPABASE_URL: string
            SUPABASE_SERVICE_ROLE_KEY: string
            SUPABASE_ANON_KEY: string
        }
    }
}

// WebSocket message types
export interface WebSocketMessage {
    type: string
    [key: string]: any
}

export interface PingMessage extends WebSocketMessage {
    type: 'ping'
}

export interface PongMessage extends WebSocketMessage {
    type: 'pong'
    timestamp: string
}

export interface MomentumUpdateRequest extends WebSocketMessage {
    type: 'request_momentum_update'
}

export interface NotificationReadMessage extends WebSocketMessage {
    type: 'mark_notification_read'
    notification_id: string
}

export interface CacheInvalidationAck extends WebSocketMessage {
    type: 'cache_invalidation_ack'
    cache_key: string
}

// Real-time event types
export interface RealtimeEvent {
    event_type: string
    user_id: string
    payload: Record<string, any>
    timestamp: string
}

export interface MomentumScoreEvent extends RealtimeEvent {
    event_type: 'momentum_score_created' | 'momentum_score_updated'
    payload: {
        score_date: string
        momentum_state: 'Rising' | 'Steady' | 'NeedsCare'
        final_score: number
        previous_state?: string
        state_changed?: boolean
    }
}

export interface InterventionEvent extends RealtimeEvent {
    event_type: 'intervention_created' | 'intervention_updated'
    payload: {
        intervention_id: string
        intervention_type: string
        status: string
        scheduled_date?: string
        trigger_reason: string
        previous_status?: string
        status_changed?: boolean
    }
}

export interface NotificationEvent extends RealtimeEvent {
    event_type: 'push_notification'
    payload: {
        notification_id: string
        notification_type: string
        title: string
        message: string
        action_type: string
        action_data: Record<string, any>
        status: string
    }
}

// Client connection types
export interface ClientConnection {
    socket: WebSocket
    user_id: string
    client_id: string
    platform: 'ios' | 'android' | 'web'
    connected_at: Date
    last_ping?: Date
}

export interface SubscriptionChannels {
    momentum_updates: string
    interventions: string
    notifications: string
    cache_invalidation: string
}

// API response types
export interface MomentumSyncResponse {
    success: boolean
    data?: any
    error?: string
    timestamp: string
}

export interface MomentumState {
    user_id: string
    has_data: boolean
    score_date?: string
    momentum_state?: 'Rising' | 'Steady' | 'NeedsCare'
    final_score?: number
    events_count?: number
    breakdown?: Record<string, any>
    last_updated?: string
    message?: string
    timestamp: string
}

export interface InterventionData {
    user_id: string
    interventions: Array<{
        id: string
        intervention_type: string
        status: string
        scheduled_date?: string
        trigger_reason: string
        created_at: string
    }>
    timestamp: string
}

export interface NotificationData {
    id: string
    user_id: string
    notification_type: string
    title: string
    message: string
    action_type: string
    action_data: Record<string, any>
    status: string
    created_at: string
    sent_at?: string
    delivered_at?: string
    opened_at?: string
}

// Cache invalidation types
export interface CacheInvalidationEvent {
    cache_key: string
    user_id: string
    timestamp: string
}

// Performance monitoring types
export interface RealtimeMetrics {
    event_type: string
    channel_name: string
    user_id?: string
    payload_size?: number
    processing_time_ms?: number
    success: boolean
    error_message?: string
    timestamp: string
}

// Health check response
export interface HealthCheckResponse {
    status: 'healthy' | 'degraded' | 'unhealthy'
    connected_clients: number
    active_subscriptions: number
    timestamp: string
    uptime?: number
    memory_usage?: number
}

export { } 